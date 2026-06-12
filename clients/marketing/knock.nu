# Auto-generated client for Knock API v1.0
# Source: https://api.knock.app/v1/openapi
# Auth: --token flag or $env.KNOCK_API_TOKEN

const BASE_URL = "https://api.knock.app"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KNOCK_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.knock.app"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["all" "read" "seen" "unread" "unseen"] }
def archived-completer [] { ["exclude" "include" "only"] }
def mode-completer [] { ["compact" "rich"] }
def mode-completer-1 [] { ["object" "recipient"] }
def persistence-strategy-completer [] { ["merge" "replace"] }
def delivery-status-completer [] { ["bounced" "delivered" "delivery_attempted" "not_sent" "queued" "sent" "undelivered"] }
def engagement-status-completer [] { ["archived" "interacted" "link_clicked" "read" "seen" "unarchived" "unread" "unseen"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "objects delete" } } | get name | first)
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

# Delete an object
#
# DELETE /v1/objects/{collection}/{id}
# operationId: deleteObject
export def "objects delete" [
  collection: string
  id: string
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
  let full_url = (build-url $base $"/v1/objects/($collection)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an object
#
# GET /v1/objects/{collection}/{id}
# operationId: getObject
export def "objects get" [
  collection: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, collection: string, created_at: string, id: string, properties: record, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set an object
#
# PUT /v1/objects/{collection}/{id}
# operationId: setObject
export def "objects setObject" [
  collection: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel-data: record # A request to set channel data for a type of channel inline. (e.g. {97c5837d-c65c-4d54-aa39-080eeb81c69d: {tokens: [push_token_xxx]}})
  --locale: string # The locale of the object. Used for [message localization](/concepts/translations). (nullable)
  --name: string # An optional name for the object. (nullable)
  --preferences: record # Inline set preferences for a recipient, where the key is the preference set id. Preferences that are set inline will be merged into any existing preferences rather than replacing them. (e.g. {default: {categories: {transactional: {channel_types: {email: false}}}, channel_types: {email: true}}})
  --timezone: string # The timezone of the object. Must be a valid [tz database time zone string](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Used for [recurring schedules](/concepts/schedules#scheduling-workflows-with-recurring-schedules-for-recipients). (nullable)
]: any -> record<__typename: string, collection: string, created_at: string, id: string, properties: record, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($id)")
  let body = {channel_data: $channel_data, locale: $locale, name: $name, preferences: $preferences, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark guide as interacted
#
# PUT /v1/users/{user_id}/guides/messages/interacted
# operationId: markUserGuideAsInteracted (2)
export def "users-guides-messages-interacted markUserGuideAsInteracted-2" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: string # The unique identifier for the channel. (format: uuid)
  --content: record # The content of the guide.
  --data: record # The data of the guide.
  guide_id: string # The unique identifier for the guide. (format: uuid)
  guide_key: string # The key of the guide.
  guide_step_ref: string # The step reference of the guide.
  --is-final: oneof<nothing, bool> # Whether the guide is final.
  --metadata: record # The metadata of the guide.
  --tenant: string # The tenant ID of the guide. (nullable)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/messages/interacted")
  let body = {channel_id: $channel_id, content: $content, data: $data, guide_id: $guide_id, guide_key: $guide_key, guide_step_ref: $guide_step_ref, is_final: $is_final, metadata: $metadata, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Process a Census RPC request
#
# POST /v1/integrations/census/custom-destination
# operationId: processCensusRpcRequest
export def "integrations-census-custom-destination processCensusRpcRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # The unique identifier for the RPC request.
  jsonrpc: string # The JSON-RPC version.
  method: string # The method name to execute.
  --params: record # The parameters for the method.
]: any -> record<id: string, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/census/custom-destination")
  let body = {id: $id, jsonrpc: $jsonrpc, method: $method, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List user subscriptions
#
# GET /v1/users/{user_id}/subscriptions
# operationId: listSubscriptionsForUser
export def "users-subscriptions listSubscriptionsForUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Associated resources to include in the response.
  --objects: list # Only returns subscriptions for the specified object references.
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<entries: table<__typename: string, inserted_at: string, object: record, properties: record, recipient: record, updated_at: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "multi") (serialize-qp "objects[]" $objects "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($user_id)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel workflow
#
# POST /v1/workflows/{key}/cancel
# operationId: cancelWorkflow (2)
export def "workflows-cancel cancelWorkflow-2" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cancellation_key: string # A key that is used to reference a specific workflow trigger request when issuing a [workflow cancellation](/send-notifications/canceling-workflows) request. Must be provided while triggering a workflow in order to enable subsequent cancellation. Should be unique across trigger requests to avoid unintentional cancellations.
  --recipients: list # A list of recipients to cancel the notification for. If omitted, cancels for all recipients associated with the cancellation key. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/($key)/cancel")
  let body = {cancellation_key: $cancellation_key, recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark guide as unarchived
#
# DELETE /v1/users/{user_id}/guides/messages/archived
# operationId: markUserGuideAsUnarchived
export def "users-guides-messages-archived markUserGuideAsUnarchived" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: string # The unique identifier for the channel. (format: uuid)
  --content: record # The content of the guide.
  --data: record # The data of the guide.
  guide_id: string # The unique identifier for the guide. (format: uuid)
  guide_key: string # The key of the guide.
  guide_step_ref: string # The step reference of the guide.
  --is-final: oneof<nothing, bool> # Whether the guide is final.
  --metadata: record # The metadata of the guide.
  --tenant: string # The tenant ID of the guide. (nullable)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/messages/archived")
  let body = {channel_id: $channel_id, content: $content, data: $data, guide_id: $guide_id, guide_key: $guide_key, guide_step_ref: $guide_step_ref, is_final: $is_final, metadata: $metadata, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark guide as archived
#
# PUT /v1/users/{user_id}/guides/messages/archived
# operationId: markUserGuideAsArchived (2)
export def "users-guides-messages-archived markUserGuideAsArchived-2" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: string # The unique identifier for the channel. (format: uuid)
  --content: record # The content of the guide.
  --data: record # The data of the guide.
  guide_id: string # The unique identifier for the guide. (format: uuid)
  guide_key: string # The key of the guide.
  guide_step_ref: string # The step reference of the guide.
  --is-final: oneof<nothing, bool> # Whether the guide is final.
  --metadata: record # The metadata of the guide.
  --tenant: string # The tenant ID of the guide. (nullable)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/messages/archived")
  let body = {channel_id: $channel_id, content: $content, data: $data, guide_id: $guide_id, guide_key: $guide_key, guide_step_ref: $guide_step_ref, is_final: $is_final, metadata: $metadata, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update channel types in preference set
#
# PUT /v1/users/{user_id}/preferences/{id}/channel_types
# DEPRECATED
# operationId: updateUserPreferenceChannelTypes
@deprecated
export def "users-preferences-channel-types updateUserPreferenceChannelTypes" [
  user_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)/channel_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update categories in preference set
#
# PUT /v1/objects/{collection}/{object_id}/preferences/{id}/categories
# DEPRECATED
# operationId: updateObjectPreferenceCategories
@deprecated
export def "objects-preferences-categories updateObjectPreferenceCategories" [
  collection: any
  object_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List messages
#
# GET /v1/messages
# operationId: listMessages
export def "messages listMessages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
  --tenant: string # Limits the results to items with the corresponding tenant. (e.g. tenant_123)
  --channel-id: string # Limits the results to items with the corresponding channel ID. (e.g. 123e4567-e89b-12d3-a456-426614174000)
  --status: list # Limits the results to messages with the given delivery status. (e.g. [delivered])
  --engagement-status: list # Limits the results to messages with the given engagement status. (e.g. [unread])
  --message-ids: list # Limits the results to only the message IDs given (max 50). Note: when using this option, the results will be subject to any other filters applied to the query. (e.g. [1jNaXzB2RZX3LY8wVQnfCKyPnv7])
  --workflow-categories: list # Limits the results to messages related to any of the provided categories. (e.g. [workflow_123])
  --qp-source: string # Limits the results to messages triggered by the given workflow key. (e.g. comment-created)
  --workflow-run-id: string # Limits the results to messages associated with the top-level workflow run ID returned by the workflow trigger request. (format: uuid, e.g. 123e4567-e89b-12d3-a456-426614174000)
  --workflow-recipient-run-id: string # Limits the results to messages for a specific recipient's workflow run. (format: uuid, e.g. 123e4567-e89b-12d3-a456-426614174000)
  --trigger-data: string # Limits the results to only messages that were generated with the given data. See [trigger data filtering](/api-reference/overview/trigger-data-filtering) for more information. (e.g. {"comment_id": "123"})
  --inserted-atgt: string # Limits the results to items inserted after the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atgte: string # Limits the results to items inserted after or on the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atlt: string # Limits the results to items inserted before the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atlte: string # Limits the results to items inserted before or on the given date. (e.g. 2025-01-01T00:00:00Z)
]: nothing -> record<items: table<__typename: string, actors: list, archived_at: string, channel: record, channel_id: string, clicked_at: string, data: record, engagement_statuses: list, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record, scheduled_at: string, seen_at: string, source: record, status: string, tenant: string, updated_at: string, workflow: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "status[]" $status "multi") (serialize-qp "engagement_status[]" $engagement_status "multi") (serialize-qp "message_ids[]" $message_ids "multi") (serialize-qp "workflow_categories[]" $workflow_categories "multi") (serialize-qp "source" $qp_source "scalar") (serialize-qp "workflow_run_id" $workflow_run_id "scalar") (serialize-qp "workflow_recipient_run_id" $workflow_recipient_run_id "scalar") (serialize-qp "trigger_data" $trigger_data "scalar") (serialize-qp "inserted_at.gt" $inserted_atgt "scalar") (serialize-qp "inserted_at.gte" $inserted_atgte "scalar") (serialize-qp "inserted_at.lt" $inserted_atlt "scalar") (serialize-qp "inserted_at.lte" $inserted_atlte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update channel type in preference set
#
# PUT /v1/users/{user_id}/preferences/{id}/channel_types/{type}
# DEPRECATED
# operationId: updateUserPreferenceChannelType
@deprecated
export def "users-preferences-channel-types updateUserPreferenceChannelType" [
  user_id: any
  id: any
  type: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)/channel_types/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List channels
#
# GET /v1/providers/ms-teams/{channel_id}/channels
# operationId: listChannelsForMsTeamsProvider
export def "providers-ms-teams-channels listChannelsForMsTeamsProvider" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ms-teams-tenant-object: string # A JSON encoded string containing the Microsoft Teams tenant object reference. (e.g. {"collection":"projects","object_id":"project_123"})
  --team-id: string # Microsoft Teams team ID.
  --query-optionsfilter: string # [OData param](https://learn.microsoft.com/en-us/graph/query-parameters) passed to the Microsoft Graph API to filter channels. (e.g. displayName eq 'General')
  --query-optionsselect: string # [OData param](https://learn.microsoft.com/en-us/graph/query-parameters) passed to the Microsoft Graph API to select specific properties. (e.g. id,displayName,description)
]: nothing -> record<ms_teams_channels: table<createdDateTime: string, description: string, displayName: string, id: string, isArchived: bool, membershipType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ms_teams_tenant_object" $ms_teams_tenant_object "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "query_options.$filter" $query_optionsfilter "scalar") (serialize-qp "query_options.$select" $query_optionsselect "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/providers/ms-teams/($channel_id)/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark message as interacted
#
# PUT /v1/messages/{message_id}/interacted
# operationId: markMessageInteracted
export def "messages-interacted markMessageInteracted" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # Metadata about the interaction. (e.g. {key: value})
]: any -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/interacted")
  let body = {metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List events
#
# GET /v1/messages/{message_id}/events
# operationId: listMessageEvents
export def "messages-events listMessageEvents" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<items: table<__typename: string, data: record, id: string, inserted_at: string, recipient: any, type: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/messages/($message_id)/events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user messages
#
# GET /v1/users/{user_id}/messages
# operationId: listMessagesForUser
export def "users-messages listMessagesForUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
  --tenant: string # Limits the results to items with the corresponding tenant. (e.g. tenant_123)
  --channel-id: string # Limits the results to items with the corresponding channel ID. (e.g. 123e4567-e89b-12d3-a456-426614174000)
  --status: list # Limits the results to messages with the given delivery status. (e.g. [delivered])
  --engagement-status: list # Limits the results to messages with the given engagement status. (e.g. [unread])
  --message-ids: list # Limits the results to only the message IDs given (max 50). Note: when using this option, the results will be subject to any other filters applied to the query. (e.g. [1jNaXzB2RZX3LY8wVQnfCKyPnv7])
  --workflow-categories: list # Limits the results to messages related to any of the provided categories. (e.g. [workflow_123])
  --qp-source: string # Limits the results to messages triggered by the given workflow key. (e.g. comment-created)
  --workflow-run-id: string # Limits the results to messages associated with the top-level workflow run ID returned by the workflow trigger request. (format: uuid, e.g. 123e4567-e89b-12d3-a456-426614174000)
  --workflow-recipient-run-id: string # Limits the results to messages for a specific recipient's workflow run. (format: uuid, e.g. 123e4567-e89b-12d3-a456-426614174000)
  --trigger-data: string # Limits the results to only messages that were generated with the given data. See [trigger data filtering](/api-reference/overview/trigger-data-filtering) for more information. (e.g. {"comment_id": "123"})
  --inserted-atgt: string # Limits the results to items inserted after the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atgte: string # Limits the results to items inserted after or on the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atlt: string # Limits the results to items inserted before the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atlte: string # Limits the results to items inserted before or on the given date. (e.g. 2025-01-01T00:00:00Z)
]: nothing -> record<items: table<__typename: string, actors: list, archived_at: string, channel: record, channel_id: string, clicked_at: string, data: record, engagement_statuses: list, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record, scheduled_at: string, seen_at: string, source: record, status: string, tenant: string, updated_at: string, workflow: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "status[]" $status "multi") (serialize-qp "engagement_status[]" $engagement_status "multi") (serialize-qp "message_ids[]" $message_ids "multi") (serialize-qp "workflow_categories[]" $workflow_categories "multi") (serialize-qp "source" $qp_source "scalar") (serialize-qp "workflow_run_id" $workflow_run_id "scalar") (serialize-qp "workflow_recipient_run_id" $workflow_recipient_run_id "scalar") (serialize-qp "trigger_data" $trigger_data "scalar") (serialize-qp "inserted_at.gt" $inserted_atgt "scalar") (serialize-qp "inserted_at.gte" $inserted_atgte "scalar") (serialize-qp "inserted_at.lt" $inserted_atlt "scalar") (serialize-qp "inserted_at.lte" $inserted_atlte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($user_id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke access
#
# PUT /v1/providers/slack/{channel_id}/revoke_access
# operationId: slackProviderRevokeAccess
export def "providers-slack-revoke-access slackProviderRevokeAccess" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token-object: string # A JSON encoded string containing the access token object reference. (e.g. {"collection":"projects","object_id":"project_123"})
]: nothing -> record<ok: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access_token_object" $access_token_object "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/providers/slack/($channel_id)/revoke_access" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk delete objects
#
# POST /v1/objects/{collection}/bulk/delete
# operationId: bulkDeleteObjects
export def "objects-bulk-delete bulkDeleteObjects" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  object_ids: list # List of object IDs to delete.
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/bulk/delete")
  let body = {object_ids: $object_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workflows in preference set
#
# PUT /v1/users/{user_id}/preferences/{id}/workflows
# DEPRECATED
# operationId: updateUserPreferenceWorkflows
@deprecated
export def "users-preferences-workflows updateUserPreferenceWorkflows" [
  user_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)/workflows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List guides
#
# GET /v1/users/{user_id}/guides/{channel_id}
# operationId: listUserGuides
export def "users-guides listUserGuides" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant: string # The tenant ID to use for targeting and rendering guides.
  --data: string # The data (JSON encoded object) to use for targeting and rendering guides.
  --type: string # The type of guides to filter by.
]: nothing -> record<entries: table<__typename: string, activation_url_patterns: list, activation_url_rules: list, active: bool, bypass_global_group_limit: bool, channel_id: string, dashboard_url: string, id: string, inserted_at: string, key: string, semver: string, steps: list, type: string, updated_at: string>, guide_group_display_logs: record, guide_groups: table<__typename: string, display_interval: int, display_sequence: list, inserted_at: string, key: string, updated_at: string>, ineligible_guides: table<key: string, message: string, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant" $tenant "scalar") (serialize-qp "data" $data "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/($channel_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user schedules
#
# GET /v1/users/{user_id}/schedules
# operationId: listUserSchedules
export def "users-schedules listUserSchedules" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workflow: string # The workflow key to filter schedules for.
  --tenant: string # The tenant ID to filter schedules for.
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<entries: table<__typename: string, actor: any, data: record, id: string, inserted_at: string, last_occurrence_at: string, next_occurrence_at: string, recipient: record, repeats: list, tenant: string, updated_at: string, workflow: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow" $workflow "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($user_id)/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a category preference
#
# PUT /v1/objects/{collection}/{object_id}/preferences/{id}/categories/{key}
# DEPRECATED
# operationId: updateObjectPreferenceCategory
@deprecated
export def "objects-preferences-categories updateObjectPreferenceCategory" [
  collection: any
  object_id: any
  id: any
  key: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)/categories/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update category in user preference set
#
# PUT /v1/users/{user_id}/preferences/{id}/categories/{key}
# DEPRECATED
# operationId: updateUserPreferenceCategory
@deprecated
export def "users-preferences-categories updateUserPreferenceCategory" [
  user_id: any
  id: any
  key: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)/categories/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get message content
#
# GET /v1/messages/{message_id}/content
# operationId: getMessageContents
export def "messages-content get" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, data: record, inserted_at: string, message_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/content")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check auth
#
# GET /v1/providers/ms-teams/{channel_id}/auth_check
# operationId: msTeamsProviderAuthCheck
export def "providers-ms-teams-auth-check msTeamsProviderAuthCheck" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ms-teams-tenant-object: string # A JSON encoded string containing the Microsoft Teams tenant object reference. (e.g. {"collection":"projects","object_id":"project_123"})
]: nothing -> record<connection: record<ms_teams_tenant_id: string, ok: bool, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ms_teams_tenant_object" $ms_teams_tenant_object "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/providers/ms-teams/($channel_id)/auth_check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke access
#
# PUT /v1/providers/ms-teams/{channel_id}/revoke_access
# operationId: msTeamsProviderRevokeAccess
export def "providers-ms-teams-revoke-access msTeamsProviderRevokeAccess" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ms-teams-tenant-object: string # A JSON encoded string containing the Microsoft Teams tenant object reference. (e.g. {"collection":"projects","object_id":"project_123"})
]: nothing -> record<ok: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ms_teams_tenant_object" $ms_teams_tenant_object "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/providers/ms-teams/($channel_id)/revoke_access" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get feed settings
#
# GET /v1/users/{user_id}/feeds/{id}/settings
# operationId: getUserInAppFeedSettings
export def "users-feeds-settings get" [
  user_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<features: record<branding_required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/feeds/($id)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset guide engagement
#
# PUT /v1/users/{user_id}/guides/engagements/reset
# operationId: resetUserGuideEngagement
export def "users-guides-engagements-reset resetUserGuideEngagement" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: string # The unique identifier for the channel. (format: uuid)
  --content: record # The content of the guide.
  --data: record # The data of the guide.
  guide_id: string # The unique identifier for the guide. (format: uuid)
  guide_key: string # The key of the guide.
  guide_step_ref: string # The step reference of the guide.
  --is-final: oneof<nothing, bool> # Whether the guide is final.
  --metadata: record # The metadata of the guide.
  --tenant: string # The tenant ID of the guide. (nullable)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/engagements/reset")
  let body = {channel_id: $channel_id, content: $content, data: $data, guide_id: $guide_id, guide_key: $guide_key, guide_step_ref: $guide_step_ref, is_final: $is_final, metadata: $metadata, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List preference sets
#
# GET /v1/objects/{collection}/{object_id}/preferences
# operationId: listObjectPreferenceSets
export def "objects-preferences listObjectPreferenceSets" [
  object_id: string
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List activities
#
# GET /v1/messages/{message_id}/activities
# operationId: listMessageActivities
export def "messages-activities listMessageActivities" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --trigger-data: string # The trigger data to filter activities by.
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<items: table<__typename: string, actor: record, data: record, id: string, inserted_at: string, recipient: record, updated_at: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "trigger_data" $trigger_data "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/messages/($message_id)/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List tenants
#
# GET /v1/tenants
# operationId: listTenants
export def "tenants listTenants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant-id: string # Filter tenants by ID.
  --name: string # Filter tenants by name.
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<entries: table<__typename: string, id: string, name: string, settings: record>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant_id" $tenant_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tenants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update workflows in preference set
#
# PUT /v1/objects/{collection}/{object_id}/preferences/{id}/workflows
# DEPRECATED
# operationId: updateObjectPreferenceWorkflows
@deprecated
export def "objects-preferences-workflows updateObjectPreferenceWorkflows" [
  collection: any
  object_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)/workflows")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List messages
#
# GET /v1/objects/{collection}/{id}/messages
# operationId: listMessagesForObject
export def "objects-messages listMessagesForObject" [
  collection: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
  --tenant: string # Limits the results to items with the corresponding tenant. (e.g. tenant_123)
  --channel-id: string # Limits the results to items with the corresponding channel ID. (e.g. 123e4567-e89b-12d3-a456-426614174000)
  --status: list # Limits the results to messages with the given delivery status. (e.g. [delivered])
  --engagement-status: list # Limits the results to messages with the given engagement status. (e.g. [unread])
  --message-ids: list # Limits the results to only the message IDs given (max 50). Note: when using this option, the results will be subject to any other filters applied to the query. (e.g. [1jNaXzB2RZX3LY8wVQnfCKyPnv7])
  --workflow-categories: list # Limits the results to messages related to any of the provided categories. (e.g. [workflow_123])
  --qp-source: string # Limits the results to messages triggered by the given workflow key. (e.g. comment-created)
  --workflow-run-id: string # Limits the results to messages associated with the top-level workflow run ID returned by the workflow trigger request. (format: uuid, e.g. 123e4567-e89b-12d3-a456-426614174000)
  --workflow-recipient-run-id: string # Limits the results to messages for a specific recipient's workflow run. (format: uuid, e.g. 123e4567-e89b-12d3-a456-426614174000)
  --trigger-data: string # Limits the results to only messages that were generated with the given data. See [trigger data filtering](/api-reference/overview/trigger-data-filtering) for more information. (e.g. {"comment_id": "123"})
  --inserted-atgt: string # Limits the results to items inserted after the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atgte: string # Limits the results to items inserted after or on the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atlt: string # Limits the results to items inserted before the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atlte: string # Limits the results to items inserted before or on the given date. (e.g. 2025-01-01T00:00:00Z)
]: nothing -> record<items: table<__typename: string, actors: list, archived_at: string, channel: record, channel_id: string, clicked_at: string, data: record, engagement_statuses: list, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record, scheduled_at: string, seen_at: string, source: record, status: string, tenant: string, updated_at: string, workflow: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "channel_id" $channel_id "scalar") (serialize-qp "status[]" $status "multi") (serialize-qp "engagement_status[]" $engagement_status "multi") (serialize-qp "message_ids[]" $message_ids "multi") (serialize-qp "workflow_categories[]" $workflow_categories "multi") (serialize-qp "source" $qp_source "scalar") (serialize-qp "workflow_run_id" $workflow_run_id "scalar") (serialize-qp "workflow_recipient_run_id" $workflow_recipient_run_id "scalar") (serialize-qp "trigger_data" $trigger_data "scalar") (serialize-qp "inserted_at.gt" $inserted_atgt "scalar") (serialize-qp "inserted_at.gte" $inserted_atgte "scalar") (serialize-qp "inserted_at.lt" $inserted_atlt "scalar") (serialize-qp "inserted_at.lte" $inserted_atlte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/objects/($collection)/($id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger workflow
#
# POST /v1/notify
# operationId: triggerWorkflow (2)
export def "notify triggerWorkflow-2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  actor: any # A reference to a recipient, either a user identifier (string) or an object reference (ID, collection). (e.g. user_123)
  --cancellation-key: string # A key that is used to reference a specific workflow trigger request when issuing a [workflow cancellation](/send-notifications/canceling-workflows) request. Must be provided while triggering a workflow in order to enable subsequent cancellation. Should be unique across trigger requests to avoid unintentional cancellations. (nullable)
  --data: record # An optional map of data to pass into the workflow execution. There is a 10MB limit on the size of the full `data` payload. Any individual string value greater than 1024 bytes in length will be [truncated](/developer-tools/api-logs#log-truncation) in your logs. (nullable)
  name: string # The key of the workflow to trigger.
  recipients: list # A list of recipients.
]: any -> record<result_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/notify")
  let body = {actor: $actor, cancellation_key: $cancellation_key, data: $data, name: $name, recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark messages as archived
#
# POST /v1/messages/batch/archived
# operationId: batchMarkMessagesAsArchived
export def "messages-batch-archived batchMarkMessagesAsArchived" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message_ids: list # The message IDs to update the status of.
]: any -> table<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batch/archived")
  let body = {message_ids: $message_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List feed items
#
# GET /v1/users/{user_id}/feeds/{id}
# operationId: listUserInAppFeedItems
export def "users-feeds listUserInAppFeedItems" [
  user_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # The status of the feed items. (e.g. unread)
  --qp-source: string # The workflow key associated with the message in the feed. (e.g. my_source)
  --tenant: string # The tenant associated with the feed items. (e.g. my_tenant)
  --has-tenant: oneof<nothing, bool> # Whether the feed items have a tenant. (e.g. true)
  --workflow-categories: list # The workflow categories of the feed items. (e.g. [my_workflow_category])
  --archived: string@archived-completer # The archived status of the feed items. (e.g. exclude)
  --trigger-data: string # The trigger data of the feed items (as a JSON string). (e.g. { "key": "value" })
  --locale: string # The locale to render the feed items in. Must be in the IETF 5646 format (e.g. `en-US`). When not provided, will default to the locale that the feed items were rendered in. Only available for enterprise plan customers using custom translations. (e.g. en-US)
  --exclude: string # Comma-separated list of field paths to exclude from the response. Use dot notation for nested fields (e.g., `entries.archived_at`). Limited to 3 levels deep. (e.g. entries.archived_at,entries.clicked_at)
  --mode: string@mode-completer # The mode to render the feed items in. Can be `compact` or `rich`. Defaults to `rich`. When `mode` is `compact`, feed items will not have `activities` and `total_activities` fields; the `data` field will not include nested arrays and objects; and the `actors` field will only have up to one actor. (default: rich, e.g. compact)
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
  --inserted-atgt: string # Limits the results to items inserted after the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atgte: string # Limits the results to items inserted after or on the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atlt: string # Limits the results to items inserted before the given date. (e.g. 2025-01-01T00:00:00Z)
  --inserted-atlte: string # Limits the results to items inserted before or on the given date. (e.g. 2025-01-01T00:00:00Z)
]: nothing -> record<entries: table<__typename: string, activities: list, actors: list, archived_at: string, blocks: list, clicked_at: string, data: record, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, read_at: string, seen_at: string, source: record, tenant: string, total_activities: int, total_actors: int, updated_at: string>, meta: record<__typename: string, total_count: int, unread_count: int, unseen_count: int>, page_info: record<__typename: string, after: string, before: string, page_size: int>, vars: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "has_tenant" $has_tenant "scalar") (serialize-qp "workflow_categories[]" $workflow_categories "multi") (serialize-qp "archived" $archived "scalar") (serialize-qp "trigger_data" $trigger_data "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "exclude" $exclude "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "inserted_at.gt" $inserted_atgt "scalar") (serialize-qp "inserted_at.gte" $inserted_atgte "scalar") (serialize-qp "inserted_at.lt" $inserted_atlt "scalar") (serialize-qp "inserted_at.lte" $inserted_atlte "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($user_id)/feeds/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark messages as unarchived
#
# POST /v1/messages/batch/unarchived
# operationId: batchMarkMessagesAsUnarchived
export def "messages-batch-unarchived batchMarkMessagesAsUnarchived" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message_ids: list # The message IDs to update the status of.
]: any -> table<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batch/unarchived")
  let body = {message_ids: $message_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List teams
#
# GET /v1/providers/ms-teams/{channel_id}/teams
# operationId: listTeamsForMsTeamsProvider
export def "providers-ms-teams-teams listTeamsForMsTeamsProvider" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ms-teams-tenant-object: string # A JSON encoded string containing the Microsoft Teams tenant object reference. (e.g. {"collection":"projects","object_id":"project_123"})
  --query-optionsfilter: string # [OData param](https://learn.microsoft.com/en-us/graph/query-parameters) passed to the Microsoft Graph API to filter teams. (e.g. displayName eq 'My Team')
  --query-optionsselect: string # [OData param](https://learn.microsoft.com/en-us/graph/query-parameters) passed to the Microsoft Graph API to select fields on a team. (e.g. id,displayName,description)
  --query-optionstop: int # [OData param](https://learn.microsoft.com/en-us/graph/query-parameters) passed to the Microsoft Graph API to limit the number of teams returned. (e.g. 10)
  --query-optionsskiptoken: string # [OData param](https://learn.microsoft.com/en-us/graph/query-parameters) passed to the Microsoft Graph API to retrieve the next page of results.
]: nothing -> record<ms_teams_teams: table<description: string, displayName: string, id: string>, skip_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ms_teams_tenant_object" $ms_teams_tenant_object "scalar") (serialize-qp "query_options.$filter" $query_optionsfilter "scalar") (serialize-qp "query_options.$select" $query_optionsselect "scalar") (serialize-qp "query_options.$top" $query_optionstop "scalar") (serialize-qp "query_options.$skiptoken" $query_optionsskiptoken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/providers/ms-teams/($channel_id)/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge users
#
# POST /v1/users/{user_id}/merge
# operationId: mergeUser
export def "users-merge mergeUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  from_user_id: string # The user ID to merge from.
]: any -> record<__typename: string, avatar: string, created_at: string, email: string, id: string, name: string, phone_number: string, timezone: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/merge")
  let body = {from_user_id: $from_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete subscriptions
#
# POST /v1/objects/{collection}/bulk/subscriptions/delete
# operationId: bulkDeleteSubscriptions
# --subscriptions item shape: {id: string, recipients: list}
export def "objects-bulk-subscriptions-delete bulkDeleteSubscriptions" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscriptions: list # A nested list of subscriptions. — item shape: {id: string, recipients: list}
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/bulk/subscriptions/delete")
  let body = {subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update categories in user preference set
#
# PUT /v1/users/{user_id}/preferences/{id}/categories
# DEPRECATED
# operationId: updateUserPreferenceCategories
@deprecated
export def "users-preferences-categories updateUserPreferenceCategories" [
  user_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List objects in a collection
#
# GET /v1/objects/{collection}
# operationId: listObjects
export def "objects listObjects" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
  --include: list # Includes preferences of the objects in the response.
]: nothing -> record<entries: table<__typename: string, collection: string, created_at: string, id: string, properties: record, updated_at: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "include[]" $include "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/objects/($collection)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List users
#
# GET /v1/users
# operationId: listUsers
export def "users listUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include: list # Associated resources to include in the response.
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<entries: table<__typename: string, avatar: string, created_at: string, email: string, id: string, name: string, phone_number: string, timezone: string, updated_at: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include[]" $include "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a workflow recipient run
#
# GET /v1/workflow_recipient_runs/{id}
# operationId: getWorkflowRecipientRun
export def "workflow-recipient-runs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actor: any, error_count: int, id: string, inserted_at: string, recipient: any, status: string, tenant: string, trigger_source: record<audience_key: string, cancellation_key: string, schedule_id: string, type: string>, updated_at: string, workflow: string, workflow_run_id: string, events: table<__typename: string, attempt: int, data: record, event: string, id: string, inserted_at: string, status: string, step_ref: string, step_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflow_recipient_runs/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark message as unseen
#
# DELETE /v1/messages/{message_id}/seen
# operationId: markMessageUnseen (2)
export def "messages-seen markMessageUnseen-2" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/seen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark message as seen
#
# PUT /v1/messages/{message_id}/seen
# operationId: markMessageSeen
export def "messages-seen markMessageSeen" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/seen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check auth
#
# GET /v1/providers/slack/{channel_id}/auth_check
# operationId: slackProviderAuthCheck
export def "providers-slack-auth-check slackProviderAuthCheck" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token-object: string # A JSON encoded string containing the access token object reference. (e.g. {"collection":"projects","object_id":"project_123"})
]: nothing -> record<connection: record<ok: bool, reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access_token_object" $access_token_object "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/providers/slack/($channel_id)/auth_check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk delete users
#
# POST /v1/users/bulk/delete
# operationId: bulkDeleteUsers
export def "users-bulk-delete bulkDeleteUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_ids: list # A list of user IDs.
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/bulk/delete")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel workflow
#
# POST /v1/notify/cancel
# operationId: cancelWorkflow
export def "notify-cancel cancelWorkflow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  cancellation_key: string # A key that is used to reference a specific workflow trigger request when issuing a [workflow cancellation](/send-notifications/canceling-workflows) request. Must be provided while triggering a workflow in order to enable subsequent cancellation. Should be unique across trigger requests to avoid unintentional cancellations.
  name: string # The key of the workflow to cancel.
  --recipients: list # A list of recipients to cancel the notification for. If omitted, cancels for all recipients associated with the cancellation key.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/notify/cancel")
  let body = {cancellation_key: $cancellation_key, name: $name, recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a channel type preference
#
# PUT /v1/objects/{collection}/{object_id}/preferences/{id}/channel_types/{type}
# DEPRECATED
# operationId: updateObjectPreferenceChannelType
@deprecated
export def "objects-preferences-channel-types updateObjectPreferenceChannelType" [
  collection: any
  object_id: any
  id: any
  type: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)/channel_types/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update channel types in preference set
#
# PUT /v1/objects/{collection}/{object_id}/preferences/{id}/channel_types
# DEPRECATED
# operationId: updateObjectPreferenceChannelTypes
@deprecated
export def "objects-preferences-channel-types updateObjectPreferenceChannelTypes" [
  collection: any
  object_id: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)/channel_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk identify users
#
# POST /v1/users/bulk/identify
# operationId: bulkIdentifyUsers
# --users item shape: {avatar?: string, channel_data?: any, created_at?: string, email?: string, id: string, locale?: string, name?: string, phone_number?: string, preferences?: any, timezone?: string}
export def "users-bulk-identify bulkIdentifyUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  users: list # A list of users. — item shape: {avatar?: string, channel_data?: any, created_at?: string, email?: string, id: string, locale?: string, name?: string, phone_number?: string, preferences?: any, timezone?: string}
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/bulk/identify")
  let body = {users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk set tenants
#
# POST /v1/tenants/bulk/set
# operationId: bulkSetTenants
export def "tenants-bulk-set bulkSetTenants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tenants: list # The tenants to be upserted.
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/tenants/bulk/set")
  let body = {tenants: $tenants} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove members
#
# DELETE /v1/audiences/{key}/members
# operationId: removeAudienceMembers
# --members item shape: {tenant?: string, user: any}
export def "audiences-members removeAudienceMembers" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  members: list # A list of audience members to remove. You can remove up to 1,000 members per request. — item shape: {tenant?: string, user: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audiences/($key)/members")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List members
#
# GET /v1/audiences/{key}/members
# operationId: listAudienceMembers
export def "audiences-members listAudienceMembers" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entries: table<__typename: string, added_at: string, tenant: string, user: record, user_id: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/audiences/($key)/members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add members
#
# POST /v1/audiences/{key}/members
# operationId: addAudienceMembers
# --members item shape: {tenant?: string, user: any}
export def "audiences-members addAudienceMembers" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --create-audience: oneof<nothing, bool> # Create the audience if it does not exist.
  members: list # A list of audience members to add. You can add up to 1,000 members per request. — item shape: {tenant?: string, user: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "create_audience" $create_audience "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/audiences/($key)/members" $qp)
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unarchive message
#
# DELETE /v1/messages/{message_id}/archived
# operationId: unarchiveMessage (2)
export def "messages-archived unarchiveMessage-2" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/archived")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive message
#
# PUT /v1/messages/{message_id}/archived
# operationId: archiveMessage
export def "messages-archived archiveMessage" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/archived")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger workflow
#
# POST /v1/workflows/{key}/trigger
# operationId: triggerWorkflow
# --settings shape: {sandbox_mode?: bool}
export def "workflows-trigger triggerWorkflow" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actor: any # A map of properties describing a user or an object to identify in Knock and mark as who or what performed the action.
  --cancellation-key: string # A key that is used to reference a specific workflow trigger request when issuing a [workflow cancellation](/send-notifications/canceling-workflows) request. Must be provided while triggering a workflow in order to enable subsequent cancellation. Should be unique across trigger requests to avoid unintentional cancellations. (nullable)
  --data: record # An optional map of data to pass into the workflow execution. There is a 10MB limit on the size of the full `data` payload. Any individual string value greater than 1024 bytes in length will be [truncated](/developer-tools/api-logs#log-truncation) in your logs. (nullable)
  recipients: list # The recipients to trigger the workflow for. Can inline identify users, objects, or use a list of user IDs. Limited to 1,000 recipients.
  --settings: record # Optional settings that control how this workflow trigger is executed. (nullable) — shape: {sandbox_mode?: bool}
  --tenant: any # The tenant to trigger the workflow for. Triggering with a tenant will use any tenant-level overrides associated with the tenant object, and all messages produced from workflow runs will be tagged with the tenant.
]: any -> record<workflow_run_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/workflows/($key)/trigger")
  let body = {actor: $actor, cancellation_key: $cancellation_key, data: $data, recipients: $recipients, settings: $settings, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark guide as archived
#
# PUT /v1/users/{user_id}/guides/messages/{message_id}/archived
# operationId: markUserGuideAsArchived
export def "users-guides-messages-archived markUserGuideAsArchived" [
  user_id: string
  message_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: string # The unique identifier for the channel. (format: uuid)
  --content: record # The content of the guide.
  --data: record # The data of the guide.
  guide_id: string # The unique identifier for the guide. (format: uuid)
  guide_key: string # The key of the guide.
  guide_step_ref: string # The step reference of the guide.
  --is-final: oneof<nothing, bool> # Whether the guide is final.
  --metadata: record # The metadata of the guide.
  --tenant: string # The tenant ID of the guide. (nullable)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/messages/($message_id)/archived")
  let body = {channel_id: $channel_id, content: $content, data: $data, guide_id: $guide_id, guide_key: $guide_key, guide_step_ref: $guide_step_ref, is_final: $is_final, metadata: $metadata, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk delete tenants
#
# POST /v1/tenants/bulk/delete
# operationId: bulkDeleteTenants
export def "tenants-bulk-delete bulkDeleteTenants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant-ids: list # The IDs of the tenants to delete.
]: nothing -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant_ids[]" $tenant_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/tenants/bulk/delete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark message as unread
#
# DELETE /v1/messages/{message_id}/unread
# operationId: markMessageUnread (2)
export def "messages-unread markMessageUnread-2" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/unread")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user
#
# DELETE /v1/users/{user_id}
# operationId: deleteUser
export def "users delete" [
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
  let full_url = (build-url $base $"/v1/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user
#
# GET /v1/users/{user_id}
# operationId: getUser
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, avatar: string, created_at: string, email: string, id: string, name: string, phone_number: string, timezone: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Identify user
#
# PUT /v1/users/{user_id}
# operationId: identifyUser
export def "users identifyUser" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --avatar: string # A URL for the avatar of the user. (nullable)
  --channel-data: any # Channel-specific information that's needed to deliver a notification to an end provider. (nullable)
  --created-at: string # The creation date of the user from your system. (nullable, format: date-time)
  --email: string # The primary email address for the user. (nullable)
  --locale: string # The locale of the user. Used for [message localization](/concepts/translations). (nullable)
  --name: string # Display name of the user. (nullable)
  --phone-number: string # The [E.164](https://www.twilio.com/docs/glossary/what-e164) phone number of the user (required for SMS channels). (nullable)
  --preferences: any # A set of preferences for the user. (nullable)
  --timezone: string # The timezone of the user. Must be a valid [tz database time zone string](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones). Used for [recurring schedules](/concepts/schedules#scheduling-workflows-with-recurring-schedules-for-recipients). (nullable)
]: any -> record<__typename: string, avatar: string, created_at: string, email: string, id: string, name: string, phone_number: string, timezone: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)")
  let body = {avatar: $avatar, channel_data: $channel_data, created_at: $created_at, email: $email, locale: $locale, name: $name, phone_number: $phone_number, preferences: $preferences, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark messages as interacted
#
# POST /v1/messages/batch/interacted
# operationId: batchMarkMessagesAsInteracted
export def "messages-batch-interacted batchMarkMessagesAsInteracted" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message_ids: list # The message IDs to batch mark as interacted with.
  --metadata: record # Metadata about the interaction. (nullable, e.g. {key: value})
]: any -> table<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batch/interacted")
  let body = {message_ids: $message_ids, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a tenant
#
# DELETE /v1/tenants/{id}
# operationId: deleteTenant
export def "tenants delete" [
  id: string
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
  let full_url = (build-url $base $"/v1/tenants/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a tenant
#
# GET /v1/tenants/{id}
# operationId: getTenant
export def "tenants get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resolve-full-preference-settings: oneof<nothing, bool> # When true, merges environment-level default preferences into the tenant's `settings.preference_set` field before returning the response. Defaults to false.
]: nothing -> record<__typename: string, id: string, name: string, settings: record<branding: record<icon_url: string, logo_url: string, primary_color: string, primary_color_contrast: string>, preference_set: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolve_full_preference_settings" $resolve_full_preference_settings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tenants/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set a tenant
#
# PUT /v1/tenants/{id}
# operationId: setTenant
# --settings shape: {branding?: record, preference_set?: any}
export def "tenants setTenant" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resolve-full-preference-settings: oneof<nothing, bool> # When true, merges environment-level default preferences into the tenant's `settings.preference_set` field before returning the response. Defaults to false.
  --channel-data: any # The channel data for the tenant.
  --name: string # An optional name for the tenant. (nullable)
  --settings: record # The settings for the tenant. Includes branding and preference set. — shape: {branding?: record, preference_set?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resolve_full_preference_settings" $resolve_full_preference_settings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/tenants/($id)" $qp)
  let body = {channel_data: $channel_data, name: $name, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark guide as seen
#
# PUT /v1/users/{user_id}/guides/messages/seen
# operationId: markUserGuideAsSeen (2)
export def "users-guides-messages-seen markUserGuideAsSeen-2" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: string # The unique identifier for the channel. (format: uuid)
  --content: record # The content of the guide.
  --data: record # The data of the guide.
  guide_id: string # The unique identifier for the guide. (format: uuid)
  guide_key: string # The key of the guide.
  guide_step_ref: string # The step reference of the guide.
  --is-final: oneof<nothing, bool> # Whether the guide is final.
  --metadata: record # The metadata of the guide.
  --tenant: string # The tenant ID of the guide. (nullable)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/messages/seen")
  let body = {channel_id: $channel_id, content: $content, data: $data, guide_id: $guide_id, guide_key: $guide_key, guide_step_ref: $guide_step_ref, is_final: $is_final, metadata: $metadata, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark message as unseen
#
# DELETE /v1/messages/{message_id}/unseen
# operationId: markMessageUnseen
export def "messages-unseen markMessageUnseen" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/unseen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete subscriptions
#
# DELETE /v1/objects/{collection}/{object_id}/subscriptions
# operationId: deleteSubscriptionsForObject
export def "objects-subscriptions delete" [
  object_id: string
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  recipients: list # The recipients of the subscription. You can subscribe up to 100 recipients to an object at a time.
]: any -> table<__typename: string, inserted_at: string, object: record<__typename: string, collection: string, created_at: string, id: string, properties: record, updated_at: string>, properties: record, recipient: record, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/subscriptions")
  let body = {recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List subscriptions
#
# GET /v1/objects/{collection}/{object_id}/subscriptions
# operationId: listSubscriptionsForObject
export def "objects-subscriptions listSubscriptionsForObject" [
  object_id: string
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mode: string@mode-completer-1 # Mode of the request. `recipient` to list the objects that the provided object is subscribed to, `object` to list the recipients that subscribe to the provided object. (default: object)
  --include: list # Additional fields to include in the response.
  --recipients: list # Recipients to filter by (only used if mode is `object`).
  --objects: list # Objects to filter by (only used if mode is `recipient`).
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<entries: table<__typename: string, inserted_at: string, object: record, properties: record, recipient: record, updated_at: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mode" $mode "scalar") (serialize-qp "include[]" $include "multi") (serialize-qp "recipients[]" $recipients "multi") (serialize-qp "objects[]" $objects "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add subscriptions
#
# POST /v1/objects/{collection}/{object_id}/subscriptions
# operationId: addSubscriptionsForObject
export def "objects-subscriptions addSubscriptionsForObject" [
  object_id: string
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --properties: record # The custom properties associated with the subscription relationship. (nullable)
  recipients: list # The recipients of the subscription. You can subscribe up to 100 recipients to an object at a time.
]: any -> table<__typename: string, inserted_at: string, object: record<__typename: string, collection: string, created_at: string, id: string, properties: record, updated_at: string>, properties: record, recipient: record, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/subscriptions")
  let body = {properties: $properties, recipients: $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a workflow preference
#
# PUT /v1/objects/{collection}/{object_id}/preferences/{id}/workflows/{key}
# DEPRECATED
# operationId: updateObjectPreferenceWorkflow
@deprecated
export def "objects-preferences-workflows updateObjectPreferenceWorkflow" [
  collection: any
  object_id: any
  id: any
  key: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)/workflows/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark message as unread
#
# DELETE /v1/messages/{message_id}/read
# operationId: markMessageUnread
export def "messages-read markMessageUnread" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/read")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark message as read
#
# PUT /v1/messages/{message_id}/read
# operationId: markMessageRead
export def "messages-read markMessageRead" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/read")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unset channel data
#
# DELETE /v1/users/{user_id}/channel_data/{channel_id}
# operationId: unsetUserChannelData
export def "users-channel-data unsetUserChannelData" [
  user_id: string
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
  let full_url = (build-url $base $"/v1/users/($user_id)/channel_data/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get channel data
#
# GET /v1/users/{user_id}/channel_data/{channel_id}
# operationId: getUserChannelData
export def "users-channel-data get" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, channel_id: string, data: record, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/channel_data/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set channel data
#
# PUT /v1/users/{user_id}/channel_data/{channel_id}
# operationId: setUserChannelData
# --data shape: {tokens?: list, devices?: list, target_arns?: list, player_ids?: list, connections?: list, token?: record, ms_teams_tenant_id?: string}
export def "users-channel-data setUserChannelData" [
  user_id: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Channel data for a given channel type. — shape: {tokens?: list, devices?: list, target_arns?: list, player_ids?: list, connections?: list, token?: record, ms_teams_tenant_id?: string}
]: any -> record<__typename: string, channel_id: string, data: record, provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/channel_data/($channel_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update workflow in user preference set
#
# PUT /v1/users/{user_id}/preferences/{id}/workflows/{key}
# DEPRECATED
# operationId: updateUserPreferenceWorkflow
@deprecated
export def "users-preferences-workflows updateUserPreferenceWorkflow" [
  user_id: any
  id: any
  key: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)/workflows/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete schedules
#
# DELETE /v1/schedules
# operationId: deleteSchedules
export def "schedules delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schedule_ids: list # A list of schedule IDs.
]: any -> table<__typename: string, actor: any, data: record, id: string, inserted_at: string, last_occurrence_at: string, next_occurrence_at: string, recipient: record, repeats: list<record>, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/schedules")
  let body = {schedule_ids: $schedule_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List schedules
#
# GET /v1/schedules
# operationId: listSchedules
export def "schedules listSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --workflow: string # Filter by workflow key.
  --recipients: list # Filter by recipient references.
  --tenant: string # Filter by tenant ID.
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<entries: table<__typename: string, actor: any, data: record, id: string, inserted_at: string, last_occurrence_at: string, next_occurrence_at: string, recipient: record, repeats: list, tenant: string, updated_at: string, workflow: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "workflow" $workflow "scalar") (serialize-qp "recipients[]" $recipients "multi") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create schedules
#
# POST /v1/schedules
# operationId: createSchedules
# --repeats item shape: {__typename?: string, day_of_month?: int, days?: list, frequency: "daily"|"weekly"|"monthly"|"hourly", hours?: int, interval?: int, minutes?: int}
export def "schedules createSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actor: record # A map of properties describing a user or an object to identify in Knock and mark as who or what performed the action.
  --data: record # An optional map of data to pass into the workflow execution. There is a 10MB limit on the size of the full `data` payload. Any individual string value greater than 1024 bytes in length will be [truncated](/developer-tools/api-logs#log-truncation) in your logs. (nullable)
  --ending-at: string # The ending date and time for the schedule. (nullable, format: date-time)
  recipients: list # The recipients to set the schedule for. Limited to 100 recipients per request.
  --repeats: list # The repeat rule for the schedule. — item shape: {__typename?: string, day_of_month?: int, days?: list, frequency: "daily"|"weekly"|"monthly"|"hourly", hours?: int, interval?: int, minutes?: int}
  --scheduled-at: string # The starting date and time for the schedule. (nullable, format: date-time)
  --tenant: any # The tenant to trigger the workflow for. Triggering with a tenant will use any tenant-level overrides associated with the tenant object, and all messages produced from workflow runs will be tagged with the tenant.
  workflow: string # The key of the workflow.
]: any -> table<__typename: string, actor: any, data: record, id: string, inserted_at: string, last_occurrence_at: string, next_occurrence_at: string, recipient: record, repeats: list<record>, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/schedules")
  let body = {actor: $actor, data: $data, ending_at: $ending_at, recipients: $recipients, repeats: $repeats, scheduled_at: $scheduled_at, tenant: $tenant, workflow: $workflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update schedules
#
# PUT /v1/schedules
# operationId: updateSchedules
# --repeats item shape: {__typename?: string, day_of_month?: int, days?: list, frequency: "daily"|"weekly"|"monthly"|"hourly", hours?: int, interval?: int, minutes?: int}
export def "schedules updateSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actor: any # A map of properties describing a user or an object to identify in Knock and mark as who or what performed the action.
  --data: record # An optional map of data to pass into the workflow execution. There is a 10MB limit on the size of the full `data` payload. Any individual string value greater than 1024 bytes in length will be [truncated](/developer-tools/api-logs#log-truncation) in your logs. (nullable)
  --ending-at: string # The ending date and time for the schedule. (nullable, format: date-time)
  --repeats: list # The repeat rule for the schedule. — item shape: {__typename?: string, day_of_month?: int, days?: list, frequency: "daily"|"weekly"|"monthly"|"hourly", hours?: int, interval?: int, minutes?: int}
  schedule_ids: list # A list of schedule IDs.
  --scheduled-at: string # The starting date and time for the schedule. (nullable, format: date-time)
  --tenant: any # The tenant to trigger the workflow for. Triggering with a tenant will use any tenant-level overrides associated with the tenant object, and all messages produced from workflow runs will be tagged with the tenant.
]: any -> table<__typename: string, actor: any, data: record, id: string, inserted_at: string, last_occurrence_at: string, next_occurrence_at: string, recipient: record, repeats: list<record>, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/schedules")
  let body = {actor: $actor, data: $data, ending_at: $ending_at, repeats: $repeats, schedule_ids: $schedule_ids, scheduled_at: $scheduled_at, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete object preference set
#
# DELETE /v1/objects/{collection}/{object_id}/preferences/{id}
# operationId: deleteObjectPreferenceSet
export def "objects-preferences delete" [
  object_id: string
  collection: string
  id: string
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
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get object preference set
#
# GET /v1/objects/{collection}/{object_id}/preferences/{id}
# operationId: getObjectPreferenceSet
export def "objects-preferences get" [
  object_id: string
  collection: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a preference set
#
# PUT /v1/objects/{collection}/{object_id}/preferences/{id}
# operationId: updateObjectPreferenceSet
export def "objects-preferences updateObjectPreferenceSet" [
  object_id: string
  collection: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --persistence-strategy: string@persistence-strategy-completer # Controls how the preference set is persisted. 'replace' will completely replace the preference set, 'merge' will merge with existing preferences.
  --categories: any # An object where the key is the category and the values are the preference settings for that category.
  --channel-types: any # An object where the key is the channel type and the values are the preference settings for that channel type.
  --channels: any # An object where the key is the channel ID and the values are the preference settings for that channel ID.
  --commercial-subscribed: oneof<nothing, bool> # Whether the recipient is subscribed to commercial communications. When false, the recipient will not receive commercial workflow notifications. (nullable)
  --workflows: any # An object where the key is the workflow key and the values are the preference settings for that workflow.
]: any -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/preferences/($id)")
  let body = {__persistence_strategy__: $persistence_strategy, categories: $categories, channel_types: $channel_types, channels: $channels, commercial_subscribed: $commercial_subscribed, workflows: $workflows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark guide as seen
#
# PUT /v1/users/{user_id}/guides/messages/{message_id}/seen
# operationId: markUserGuideAsSeen
export def "users-guides-messages-seen markUserGuideAsSeen" [
  user_id: string
  message_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: string # The unique identifier for the channel. (format: uuid)
  --content: record # The content of the guide.
  --data: record # The data of the guide.
  guide_id: string # The unique identifier for the guide. (format: uuid)
  guide_key: string # The key of the guide.
  guide_step_ref: string # The step reference of the guide.
  --is-final: oneof<nothing, bool> # Whether the guide is final.
  --metadata: record # The metadata of the guide.
  --tenant: string # The tenant ID of the guide. (nullable)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/messages/($message_id)/seen")
  let body = {channel_id: $channel_id, content: $content, data: $data, guide_id: $guide_id, guide_key: $guide_key, guide_step_ref: $guide_step_ref, is_final: $is_final, metadata: $metadata, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk set objects
#
# POST /v1/objects/{collection}/bulk/set
# operationId: bulkSetObjects
# --objects item shape: {channel_data?: any, created_at?: string, id: string, name?: string, preferences?: any}
export def "objects-bulk-set bulkSetObjects" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  objects: list # A list of objects. — item shape: {channel_data?: any, created_at?: string, id: string, name?: string, preferences?: any}
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/bulk/set")
  let body = {objects: $objects} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Process a Hightouch RPC request
#
# POST /v1/integrations/hightouch/embedded-destination
# operationId: processHightouchRpcRequest
export def "integrations-hightouch-embedded-destination processHightouchRpcRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: string # The unique identifier for the RPC request.
  jsonrpc: string # The JSON-RPC version.
  method: string # The method name to execute.
  --params: record # The parameters for the method.
]: any -> record<id: string, result: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/hightouch/embedded-destination")
  let body = {id: $id, jsonrpc: $jsonrpc, method: $method, params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark messages as unseen
#
# POST /v1/messages/batch/unseen
# operationId: batchMarkMessagesAsUnseen
export def "messages-batch-unseen batchMarkMessagesAsUnseen" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message_ids: list # The message IDs to update the status of.
]: any -> table<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batch/unseen")
  let body = {message_ids: $message_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List object schedules
#
# GET /v1/objects/{collection}/{id}/schedules
# operationId: listObjectSchedules
export def "objects-schedules listObjectSchedules" [
  id: string
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant: string # Filter schedules by tenant id.
  --workflow: string # Filter schedules by workflow id.
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<entries: table<__typename: string, actor: any, data: record, id: string, inserted_at: string, last_occurrence_at: string, next_occurrence_at: string, recipient: record, repeats: list, tenant: string, updated_at: string, workflow: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant" $tenant "scalar") (serialize-qp "workflow" $workflow "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/objects/($collection)/($id)/schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create schedules in bulk
#
# POST /v1/schedules/bulk/create
# operationId: bulkCreateSchedules
# --schedules item shape: {actor?: record, data?: record, ending_at?: string, recipient?: any, repeats?: list, scheduled_at?: string, tenant?: any, workflow: string}
export def "schedules-bulk-create bulkCreateSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  schedules: list # A list of schedules. — item shape: {actor?: record, data?: record, ending_at?: string, recipient?: any, repeats?: list, scheduled_at?: string, tenant?: any, workflow: string}
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/schedules/bulk/create")
  let body = {schedules: $schedules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unset channel data
#
# DELETE /v1/objects/{collection}/{object_id}/channel_data/{channel_id}
# operationId: unsetObjectChannelData
export def "objects-channel-data unsetObjectChannelData" [
  object_id: string
  collection: string
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
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/channel_data/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get channel data
#
# GET /v1/objects/{collection}/{object_id}/channel_data/{channel_id}
# operationId: getObjectChannelData
export def "objects-channel-data get" [
  object_id: string
  collection: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, channel_id: string, data: record, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/channel_data/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set channel data
#
# PUT /v1/objects/{collection}/{object_id}/channel_data/{channel_id}
# operationId: setObjectChannelData
# --data shape: {tokens?: list, devices?: list, target_arns?: list, player_ids?: list, connections?: list, token?: record, ms_teams_tenant_id?: string}
export def "objects-channel-data setObjectChannelData" [
  object_id: string
  collection: string
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Channel data for a given channel type. — shape: {tokens?: list, devices?: list, target_arns?: list, player_ids?: list, connections?: list, token?: record, ms_teams_tenant_id?: string}
]: any -> record<__typename: string, channel_id: string, data: record, provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/($object_id)/channel_data/($channel_id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark messages as unread
#
# POST /v1/messages/batch/unread
# operationId: batchMarkMessagesAsUnread
export def "messages-batch-unread batchMarkMessagesAsUnread" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message_ids: list # The message IDs to update the status of.
]: any -> table<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batch/unread")
  let body = {message_ids: $message_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List channels
#
# GET /v1/providers/slack/{channel_id}/channels
# operationId: listChannelsForSlackProvider
export def "providers-slack-channels listChannelsForSlackProvider" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token-object: string # A JSON encoded string containing the access token object reference. (e.g. {"collection":"projects","object_id":"project_123"})
  --query-optionscursor: string # Paginate through collections of data by setting the cursor parameter to a next_cursor attribute returned by a previous request's response_metadata. Default value fetches the first "page" of the collection.
  --query-optionslimit: int # The maximum number of channels to return. Defaults to 200.
  --query-optionsexclude-archived: oneof<nothing, bool> # Set to true to exclude archived channels from the list. Defaults to `true` when not explicitly provided.
  --query-optionstypes: string # Mix and match channel types by providing a comma-separated list of any combination of public_channel, private_channel, mpim, im. Defaults to `"public_channel,private_channel"`. If the user's Slack ID is unavailable, this option is ignored and only public channels are returned.
  --query-optionsteam-id: string # Encoded team ID (T1234) to list channels in, required if org token is used.
]: nothing -> record<next_cursor: string, slack_channels: table<context_team_id: string, id: string, is_im: bool, is_private: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "access_token_object" $access_token_object "scalar") (serialize-qp "query_options.cursor" $query_optionscursor "scalar") (serialize-qp "query_options.limit" $query_optionslimit "scalar") (serialize-qp "query_options.exclude_archived" $query_optionsexclude_archived "scalar") (serialize-qp "query_options.types" $query_optionstypes "scalar") (serialize-qp "query_options.team_id" $query_optionsteam_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/providers/slack/($channel_id)/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List workflow recipient runs
#
# GET /v1/workflow_recipient_runs
# operationId: listWorkflowRecipientRuns
export def "workflow-recipient-runs listWorkflowRecipientRuns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
  --workflow: string # Limits the results to workflow recipient runs for the given workflow key.
  --status: list # Limits the results to workflow recipient runs with the given status.
  --tenant: string # Limits the results to workflow recipient runs for the given tenant.
  --has-errors: oneof<nothing, bool> # Limits the results to workflow recipient runs that have errors.
  --recipient: string # Limits the results to workflow recipient runs for the given recipient. Accepts a user ID string or an object reference with `id` and `collection`. (e.g. user_123)
  --starting-at: string # Limits the results to workflow recipient runs started after the given date. (format: date-time, e.g. 2025-01-01T00:00:00Z)
  --ending-at: string # Limits the results to workflow recipient runs started before the given date. (format: date-time, e.g. 2025-01-01T00:00:00Z)
]: nothing -> record<items: table<__typename: string, actor: any, error_count: int, id: string, inserted_at: string, recipient: any, status: string, tenant: string, trigger_source: record, updated_at: string, workflow: string, workflow_run_id: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "workflow" $workflow "scalar") (serialize-qp "status[]" $status "multi") (serialize-qp "tenant" $tenant "scalar") (serialize-qp "has_errors" $has_errors "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "starting_at" $starting_at "scalar") (serialize-qp "ending_at" $ending_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/workflow_recipient_runs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark messages as seen
#
# POST /v1/messages/batch/seen
# operationId: batchMarkMessagesAsSeen
export def "messages-batch-seen batchMarkMessagesAsSeen" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message_ids: list # The message IDs to update the status of.
]: any -> table<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batch/seen")
  let body = {message_ids: $message_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk set preferences
#
# POST /v1/users/bulk/preferences
# operationId: bulkSetUserPreferences
# --preferences shape: {__persistence_strategy__?: "merge"|"replace", categories?: any, channel_types?: any, channels?: any, commercial_subscribed?: bool, workflows?: any}
export def "users-bulk-preferences bulkSetUserPreferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  preferences: record # A request to set a preference set for a recipient. (e.g. {__persistence_strategy__: merge, categories: {marketing: false, transactional: {channel_types: {email: false}}}, channel_types: {email: true}, channels: {2f641633-95d3-4555-9222-9f1eb7888a80: {conditions: [{argument: US, operator: equal_to, variable: recipient.country_code}]}, aef6e715-df82-4ab6-b61e-b743e249f7b6: true}, commercial_subscribed: true, workflows: {dinosaurs-loose: {channel_types: {email: false}}}}) — shape: {__persistence_strategy__?: "merge"|"replace", categories?: any, channel_types?: any, channels?: any, commercial_subscribed?: bool, workflows?: any}
  user_ids: list # A list of user IDs.
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/bulk/preferences")
  let body = {preferences: $preferences, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark messages as read
#
# POST /v1/messages/batch/read
# operationId: batchMarkMessagesAsRead
export def "messages-batch-read batchMarkMessagesAsRead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  message_ids: list # The message IDs to update the status of.
]: any -> table<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/messages/batch/read")
  let body = {message_ids: $message_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Batch get message contents
#
# GET /v1/messages/batch/content
# operationId: batchGetMessageContents
export def "messages-batch-content batchGetMessageContents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --message-ids: list # The IDs of the messages to fetch contents of.
]: nothing -> table<__typename: string, data: record, inserted_at: string, message_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "message_ids[]" $message_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/messages/batch/content" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List delivery logs
#
# GET /v1/messages/{message_id}/delivery_logs
# operationId: listMessageDeliveryLogs
export def "messages-delivery-logs listMessageDeliveryLogs" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # The cursor to fetch entries after.
  --before: string # The cursor to fetch entries before.
  --page-size: int # The number of items per page (defaults to 50).
]: nothing -> record<items: table<__typename: string, environment_id: string, id: string, inserted_at: string, request: record, response: record, service_name: string>, page_info: record<__typename: string, after: string, before: string, page_size: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/messages/($message_id)/delivery_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark guide as interacted
#
# PUT /v1/users/{user_id}/guides/messages/{message_id}/interacted
# operationId: markUserGuideAsInteracted
export def "users-guides-messages-interacted markUserGuideAsInteracted" [
  user_id: string
  message_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  channel_id: string # The unique identifier for the channel. (format: uuid)
  --content: record # The content of the guide.
  --data: record # The data of the guide.
  guide_id: string # The unique identifier for the guide. (format: uuid)
  guide_key: string # The key of the guide.
  guide_step_ref: string # The step reference of the guide.
  --is-final: oneof<nothing, bool> # Whether the guide is final.
  --metadata: record # The metadata of the guide.
  --tenant: string # The tenant ID of the guide. (nullable)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/guides/messages/($message_id)/interacted")
  let body = {channel_id: $channel_id, content: $content, data: $data, guide_id: $guide_id, guide_key: $guide_key, guide_step_ref: $guide_step_ref, is_final: $is_final, metadata: $metadata, tenant: $tenant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get message
#
# GET /v1/messages/{message_id}
# operationId: getMessage
export def "messages get" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk update message statuses for channel
#
# POST /v1/channels/{channel_id}/messages/bulk/{action}
# operationId: bulkUpdateMessagesForChannel
export def "channels-messages-bulk bulkUpdateMessagesForChannel" [
  channel_id: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --archived: string@archived-completer # Limits the results to messages with the given archived status.
  --delivery-status: string@delivery-status-completer # Limits the results to messages with the given delivery status.
  --engagement-status: string@engagement-status-completer # Limits the results to messages with the given engagement status.
  --has-tenant: oneof<nothing, bool> # Limits the results to messages that have a tenant or not.
  --newer-than: string # Limits the results to messages inserted after the given date. (format: date-time)
  --older-than: string # Limits the results to messages inserted before the given date. (format: date-time)
  --recipient-ids: list # Limits the results to messages with the given recipient IDs.
  --tenants: list # Limits the results to messages with the given tenant IDs.
  --trigger-data: string # Limits the results to only messages that were generated with the given data. See [trigger data filtering](/api-reference/overview/trigger-data-filtering) for more information.
  --workflows: list # Limits the results to messages with the given workflow keys.
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/channels/($channel_id)/messages/bulk/($action)")
  let body = {archived: $archived, delivery_status: $delivery_status, engagement_status: $engagement_status, has_tenant: $has_tenant, newer_than: $newer_than, older_than: $older_than, recipient_ids: $recipient_ids, tenants: $tenants, trigger_data: $trigger_data, workflows: $workflows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unarchive message
#
# DELETE /v1/messages/{message_id}/unarchived
# operationId: unarchiveMessage
export def "messages-unarchived unarchiveMessage" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, actors: list<any>, archived_at: string, channel: record<created_at: string, id: string, key: string, name: string, provider: string, type: string, updated_at: string>, channel_id: string, clicked_at: string, data: record, engagement_statuses: list<string>, id: string, inserted_at: string, interacted_at: string, link_clicked_at: string, metadata: record, read_at: string, recipient: any, recipient_snapshot: record<email: string, name: string>, scheduled_at: string, seen_at: string, source: record<__typename: string, categories: list<string>, key: string, step_ref: string, type: string, version_id: string, workflow_recipient_run_id: string, workflow_run_id: string>, status: string, tenant: string, updated_at: string, workflow: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($message_id)/unarchived")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get bulk operation
#
# GET /v1/bulk_operations/{id}
# operationId: getBulkOperation
export def "bulk-operations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/bulk_operations/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user preference sets
#
# GET /v1/users/{user_id}/preferences
# operationId: listUserPreferenceSets
export def "users-preferences listUserPreferenceSets" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user preference set
#
# DELETE /v1/users/{user_id}/preferences/{id}
# operationId: deleteUserPreferenceSet
export def "users-preferences delete" [
  user_id: string
  id: string
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
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user preference set
#
# GET /v1/users/{user_id}/preferences/{id}
# operationId: getUserPreferenceSet
export def "users-preferences get" [
  user_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenant: string # The unique identifier for the tenant.
]: nothing -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tenant" $tenant "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user preference set
#
# PUT /v1/users/{user_id}/preferences/{id}
# operationId: updateUserPreferenceSet
export def "users-preferences updateUserPreferenceSet" [
  user_id: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --persistence-strategy: string@persistence-strategy-completer # Controls how the preference set is persisted. 'replace' will completely replace the preference set, 'merge' will merge with existing preferences.
  --categories: any # An object where the key is the category and the values are the preference settings for that category.
  --channel-types: any # An object where the key is the channel type and the values are the preference settings for that channel type.
  --channels: any # An object where the key is the channel ID and the values are the preference settings for that channel ID.
  --commercial-subscribed: oneof<nothing, bool> # Whether the recipient is subscribed to commercial communications. When false, the recipient will not receive commercial workflow notifications. (nullable)
  --workflows: any # An object where the key is the workflow key and the values are the preference settings for that workflow.
]: any -> record<categories: any, channel_types: any, channels: any, commercial_subscribed: bool, id: string, workflows: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/preferences/($id)")
  let body = {__persistence_strategy__: $persistence_strategy, categories: $categories, channel_types: $channel_types, channels: $channels, commercial_subscribed: $commercial_subscribed, workflows: $workflows} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk add subscriptions
#
# POST /v1/objects/{collection}/bulk/subscriptions/add
# operationId: bulkAddSubscriptions
# --subscriptions item shape: {id: string, properties?: record, recipients: list}
export def "objects-bulk-subscriptions-add bulkAddSubscriptions" [
  collection: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscriptions: list # A nested list of subscriptions. — item shape: {id: string, properties?: record, recipients: list}
]: any -> record<__typename: string, completed_at: string, error_count: int, error_items: table<collection: string, id: string>, estimated_total_rows: int, failed_at: string, id: string, inserted_at: string, name: string, processed_rows: int, progress_path: string, started_at: string, status: string, success_count: int, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/objects/($collection)/bulk/subscriptions/add")
  let body = {subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
