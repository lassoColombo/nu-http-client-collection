# Auto-generated client for LINE Messaging API v0.0.1
# Source: https://raw.githubusercontent.com/line/line-openapi/main/messaging-api.yml
# Auth: --token flag or $env.LINE_MESSAGING_API_TOKEN

const BASE_URL = "https://api.line.me"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LINE_MESSAGING_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.line.me" "https://api-data.line.me"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def visibility-completer [] { ["PUBLIC" "UNLISTED"] }
def timezone-completer [] { ["AMERICA_ANCHORAGE" "AMERICA_CARACAS" "AMERICA_CHICAGO" "AMERICA_LOS_ANGELES" "AMERICA_NEW_YORK" "AMERICA_PHOENIX" "AMERICA_SANTIAGO" "AMERICA_SAO_PAULO" "AMERICA_ST_JOHNS" "ASIA_ALMATY" "ASIA_BANGKOK" "ASIA_COLOMBO" "ASIA_KABUL" "ASIA_KATHMANDU" "ASIA_RANGOON" "ASIA_TAIPEI" "ASIA_TASHKENT" "ASIA_TBILISI" "ASIA_TEHRAN" "ASIA_TOKYO" "ASIA_VLADIVOSTOK" "ATLANTIC_CAPE_VERDE" "AUSTRALIA_DARWIN" "AUSTRALIA_SYDNEY" "ETC_GMT_MINUS_11" "ETC_GMT_MINUS_12" "ETC_GMT_MINUS_2" "ETC_GMT_PLUS_12" "EUROPE_ISTANBUL" "EUROPE_LONDON" "EUROPE_MOSCOW" "EUROPE_PARIS" "PACIFIC_HONOLULU" "PACIFIC_TONGATAPU"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bot-channel-webhook-endpoint get" } } | get name | first)
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

# Get webhook endpoint information
#
# GET /v2/bot/channel/webhook/endpoint
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-webhook-endpoint-information
# operationId: getWebhookEndpoint
export def "bot-channel-webhook-endpoint get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<endpoint: string, active: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/channel/webhook/endpoint")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set webhook endpoint URL
#
# PUT /v2/bot/channel/webhook/endpoint
# Docs: https://developers.line.biz/en/reference/messaging-api/#set-webhook-endpoint-url
# operationId: setWebhookEndpoint
export def "bot-channel-webhook-endpoint setWebhookEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  endpoint: string # A valid webhook URL. (format: uri)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/channel/webhook/endpoint")
  let body = {endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test webhook endpoint
#
# POST /v2/bot/channel/webhook/test
# Docs: https://developers.line.biz/en/reference/messaging-api/#test-webhook-endpoint
# operationId: testWebhookEndpoint
export def "bot-channel-webhook-test testWebhookEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --endpoint: string # A webhook URL to be validated. (format: uri)
]: any -> record<success: bool, timestamp: string, statusCode: int, reason: string, detail: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/channel/webhook/test")
  let body = {endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download image, video, and audio data sent from users.
#
# GET /v2/bot/message/{messageId}/content
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-content
# operationId: getMessageContent
export def "bot-message-content get" [
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api-data.line.me")
  let full_url = (build-url $base $"/v2/bot/message/($messageId)/content")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a preview image of the image or video
#
# GET /v2/bot/message/{messageId}/content/preview
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-image-or-video-preview
# operationId: getMessageContentPreview
export def "bot-message-content-preview get" [
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api-data.line.me")
  let full_url = (build-url $base $"/v2/bot/message/($messageId)/content/preview")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify the preparation status of a video or audio for getting
#
# GET /v2/bot/message/{messageId}/content/transcoding
# Docs: https://developers.line.biz/en/reference/messaging-api/#verify-video-or-audio-preparation-status
# operationId: getMessageContentTranscodingByMessageId
export def "bot-message-content-transcoding get" [
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api-data.line.me")
  let full_url = (build-url $base $"/v2/bot/message/($messageId)/content/transcoding")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send reply message
#
# POST /v2/bot/message/reply
# Docs: https://developers.line.biz/en/reference/messaging-api/#send-reply-message
# operationId: replyMessage
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-reply replyMessage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  replyToken: string # replyToken received via webhook.
  messages: list # List of messages. — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
  --notificationDisabled: oneof<nothing, bool> # `true`: The user doesn’t receive a push notification when a message is sent. `false`: The user receives a push notification when the message is sent (unless they have disabled push notifications in LINE and/or their device). The default value is false.  (default: false)
]: any -> record<sentMessages: table<id: string, quoteToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/reply")
  let body = {replyToken: $replyToken, messages: $messages, notificationDisabled: $notificationDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sends a message to a user, group chat, or multi-person chat at any time.
#
# POST /v2/bot/message/push
# Docs: https://developers.line.biz/en/reference/messaging-api/#send-push-message
# operationId: pushMessage
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-push pushMessage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Line-Retry-Key: string # Retry key. Specifies the UUID in hexadecimal format (e.g., `123e4567-e89b-12d3-a456-426614174000`) generated by any method. The retry key isn't generated by LINE. Each developer must generate their own retry key.
  --body-to: string # ID of the receiver.
  messages: list # List of Message objects. — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
  --notificationDisabled: oneof<nothing, bool> # `true`: The user doesn’t receive a push notification when a message is sent. `false`: The user receives a push notification when the message is sent (unless they have disabled push notifications in LINE and/or their device). The default value is false.  (default: false)
  --customAggregationUnits: list # List of aggregation unit name. Case-sensitive. This functions can only be used by corporate users who have submitted the required applications.
]: any -> record<sentMessages: table<id: string, quoteToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/push")
  let body = {to: $body_to, messages: $messages, notificationDisabled: $notificationDisabled, customAggregationUnits: $customAggregationUnits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Line-Retry-Key": $X_Line_Retry_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# An API that efficiently sends the same message to multiple user IDs. You can't send messages to group chats or multi-person chats.
#
# POST /v2/bot/message/multicast
# Docs: https://developers.line.biz/en/reference/messaging-api/#send-multicast-message
# operationId: multicast
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-multicast multicast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Line-Retry-Key: string # Retry key. Specifies the UUID in hexadecimal format (e.g., `123e4567-e89b-12d3-a456-426614174000`) generated by any method. The retry key isn't generated by LINE. Each developer must generate their own retry key.
  messages: list # Messages to send — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
  --body-to: list # Array of user IDs. Use userId values which are returned in webhook event objects. Do not use LINE IDs found on LINE.
  --notificationDisabled: oneof<nothing, bool> # `true`: The user doesn’t receive a push notification when a message is sent. `false`: The user receives a push notification when the message is sent (unless they have disabled push notifications in LINE and/or their device). The default value is false.  (default: false)
  --customAggregationUnits: list # Name of aggregation unit. Case-sensitive.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/multicast")
  let body = {messages: $messages, to: $body_to, notificationDisabled: $notificationDisabled, customAggregationUnits: $customAggregationUnits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Line-Retry-Key": $X_Line_Retry_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send narrowcast message
#
# POST /v2/bot/message/narrowcast
# Docs: https://developers.line.biz/en/reference/messaging-api/#send-narrowcast-message
# operationId: narrowcast
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
# --recipient shape: {type: "operator"|"audience"|"redelivery"}
# --filter shape: {demographic?: record}
# --limit shape: {max?: int, upToRemainingQuota?: bool, forbidPartialDelivery?: bool}
export def "bot-message-narrowcast narrowcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Line-Retry-Key: string # Retry key. Specifies the UUID in hexadecimal format (e.g., `123e4567-e89b-12d3-a456-426614174000`) generated by any method. The retry key isn't generated by LINE. Each developer must generate their own retry key.
  messages: list # List of Message objects. — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
  --recipient: record # Recipient — shape: {type: "operator"|"audience"|"redelivery"}
  --filter: record # Filter for narrowcast — shape: {demographic?: record}
  --limit: record # Limit of the Narrowcast — shape: {max?: int, upToRemainingQuota?: bool, forbidPartialDelivery?: bool}
  --notificationDisabled: oneof<nothing, bool> # `true`: The user doesn’t receive a push notification when a message is sent. `false`: The user receives a push notification when the message is sent (unless they have disabled push notifications in LINE and/or their device). The default value is false.  (default: false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/narrowcast")
  let body = {messages: $messages, recipient: $recipient, filter: $filter, limit: $limit, notificationDisabled: $notificationDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Line-Retry-Key": $X_Line_Retry_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the status of a narrowcast message.
#
# GET /v2/bot/message/progress/narrowcast
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-narrowcast-progress-status
# operationId: getNarrowcastProgress
export def "bot-message-progress-narrowcast get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requestId: string # The narrowcast message's request ID. Each Messaging API request has a request ID.
]: nothing -> record<phase: string, successCount: int, failureCount: int, targetCount: int, failedDescription: string, errorCode: int, acceptedTime: string, completedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestId" $requestId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/message/progress/narrowcast" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends a message to multiple users at any time.
#
# POST /v2/bot/message/broadcast
# Docs: https://developers.line.biz/en/reference/messaging-api/#send-broadcast-message
# operationId: broadcast
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-broadcast broadcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Line-Retry-Key: string # Retry key. Specifies the UUID in hexadecimal format (e.g., `123e4567-e89b-12d3-a456-426614174000`) generated by any method. The retry key isn't generated by LINE. Each developer must generate their own retry key.
  messages: list # List of Message objects. — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
  --notificationDisabled: oneof<nothing, bool> # `true`: The user doesn’t receive a push notification when a message is sent. `false`: The user receives a push notification when the message is sent (unless they have disabled push notifications in LINE and/or their device). The default value is false.  (default: false)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/broadcast")
  let body = {messages: $messages, notificationDisabled: $notificationDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Line-Retry-Key": $X_Line_Retry_Key} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets the target limit for sending messages in the current month. The total number of the free messages and the additional messages is returned.
#
# GET /v2/bot/message/quota
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-quota
# operationId: getMessageQuota
export def "bot-message-quota get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: string, value: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/quota")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the number of messages sent in the current month.
#
# GET /v2/bot/message/quota/consumption
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-consumption
# operationId: getMessageQuotaConsumption
export def "bot-message-quota-consumption get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<totalUsage: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/quota/consumption")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get number of sent reply messages
#
# GET /v2/bot/message/delivery/reply
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-number-of-reply-messages
# operationId: getNumberOfSentReplyMessages
export def "bot-message-delivery-reply get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date the messages were sent  Format: `yyyyMMdd` (e.g. `20191231`) Timezone: UTC+9
]: nothing -> record<status: string, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/message/delivery/reply" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get number of sent push messages
#
# GET /v2/bot/message/delivery/push
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-number-of-push-messages
# operationId: getNumberOfSentPushMessages
export def "bot-message-delivery-push get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date the messages were sent  Format: `yyyyMMdd` (e.g. `20191231`) Timezone: UTC+9
]: nothing -> record<status: string, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/message/delivery/push" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get number of sent multicast messages
#
# GET /v2/bot/message/delivery/multicast
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-number-of-multicast-messages
# operationId: getNumberOfSentMulticastMessages
export def "bot-message-delivery-multicast get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date the messages were sent  Format: `yyyyMMdd` (e.g. `20191231`) Timezone: UTC+9
]: nothing -> record<status: string, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/message/delivery/multicast" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get number of sent broadcast messages
#
# GET /v2/bot/message/delivery/broadcast
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-number-of-broadcast-messages
# operationId: getNumberOfSentBroadcastMessages
export def "bot-message-delivery-broadcast get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date the messages were sent  Format: yyyyMMdd (e.g. 20191231) Timezone: UTC+9  (format: ^[0-9]{8}$)
]: nothing -> record<status: string, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/message/delivery/broadcast" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validate message objects of a reply message
#
# POST /v2/bot/message/validate/reply
# Docs: https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-reply-message
# operationId: validateReply
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-validate-reply validateReply" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list # Array of message objects to validate — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/validate/reply")
  let body = {messages: $messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate message objects of a push message
#
# POST /v2/bot/message/validate/push
# Docs: https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-push-message
# operationId: validatePush
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-validate-push validatePush" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list # Array of message objects to validate — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/validate/push")
  let body = {messages: $messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate message objects of a multicast message
#
# POST /v2/bot/message/validate/multicast
# Docs: https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-multicast-message
# operationId: validateMulticast
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-validate-multicast validateMulticast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list # Array of message objects to validate — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/validate/multicast")
  let body = {messages: $messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate message objects of a narrowcast message
#
# POST /v2/bot/message/validate/narrowcast
# Docs: https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-narrowcast-message
# operationId: validateNarrowcast
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-validate-narrowcast validateNarrowcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list # Array of message objects to validate — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/validate/narrowcast")
  let body = {messages: $messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate message objects of a broadcast message
#
# POST /v2/bot/message/validate/broadcast
# Docs: https://developers.line.biz/en/reference/messaging-api/#validate-message-objects-of-broadcast-message
# operationId: validateBroadcast
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-message-validate-broadcast validateBroadcast" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list # Array of message objects to validate — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/validate/broadcast")
  let body = {messages: $messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get number of units used this month
#
# GET /v2/bot/message/aggregation/info
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-number-of-units-used-this-month
# operationId: getAggregationUnitUsage
export def "bot-message-aggregation-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<numOfCustomAggregationUnits: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/aggregation/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get name list of units used this month
#
# GET /v2/bot/message/aggregation/list
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-name-list-of-units-used-this-month
# operationId: getAggregationUnitNameList
export def "bot-message-aggregation-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: string # The maximum number of aggregation units you can get per request.
  --start: string # Value of the continuation token found in the next property of the JSON object returned in the response. If you can't get all the aggregation units in one request, include this parameter to get the remaining array.
]: nothing -> record<customAggregationUnits: list<string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/message/aggregation/list" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get profile
#
# GET /v2/bot/profile/{userId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-profile
# operationId: getProfile
export def "bot-profile get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<displayName: string, userId: string, pictureUrl: string, statusMessage: string, language: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/profile/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of users who added your LINE Official Account as a friend
#
# GET /v2/bot/followers/ids
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-follower-ids
# operationId: getFollowers
export def "bot-followers-ids get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Value of the continuation token found in the next property of the JSON object returned in the response. Include this parameter to get the next array of user IDs.
  --limit: int # The maximum number of user IDs to retrieve in a single request. (format: int32, default: 300)
]: nothing -> record<userIds: list<string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/followers/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get bot info
#
# GET /v2/bot/info
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-bot-info
# operationId: getBotInfo
export def "bot-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userId: string, basicId: string, premiumId: string, displayName: string, pictureUrl: string, chatMode: string, markAsReadMode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group chat member profile
#
# GET /v2/bot/group/{groupId}/member/{userId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-group-member-profile
# operationId: getGroupMemberProfile
export def "bot-group-member get" [
  groupId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<displayName: string, userId: string, pictureUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/group/($groupId)/member/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get multi-person chat member profile
#
# GET /v2/bot/room/{roomId}/member/{userId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-room-member-profile
# operationId: getRoomMemberProfile
export def "bot-room-member get" [
  roomId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<displayName: string, userId: string, pictureUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/room/($roomId)/member/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group chat member user IDs
#
# GET /v2/bot/group/{groupId}/members/ids
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-group-member-user-ids
# operationId: getGroupMembersIds
export def "bot-group-members-ids get" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Value of the continuation token found in the `next` property of the JSON object returned in the response. Include this parameter to get the next array of user IDs for the members of the group.
]: nothing -> record<memberIds: list<string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/bot/group/($groupId)/members/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get multi-person chat member user IDs
#
# GET /v2/bot/room/{roomId}/members/ids
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-room-member-user-ids
# operationId: getRoomMembersIds
export def "bot-room-members-ids get" [
  roomId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Value of the continuation token found in the `next` property of the JSON object returned in the response. Include this parameter to get the next array of user IDs for the members of the group.
]: nothing -> record<memberIds: list<string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/bot/room/($roomId)/members/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Leave group chat
#
# POST /v2/bot/group/{groupId}/leave
# Docs: https://developers.line.biz/en/reference/messaging-api/#leave-group
# operationId: leaveGroup
export def "bot-group-leave leaveGroup" [
  groupId: string
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
  let full_url = (build-url $base $"/v2/bot/group/($groupId)/leave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Leave multi-person chat
#
# POST /v2/bot/room/{roomId}/leave
# Docs: https://developers.line.biz/en/reference/messaging-api/#leave-room
# operationId: leaveRoom
export def "bot-room-leave leaveRoom" [
  roomId: string
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
  let full_url = (build-url $base $"/v2/bot/room/($roomId)/leave")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group chat summary
#
# GET /v2/bot/group/{groupId}/summary
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-group-summary
# operationId: getGroupSummary
export def "bot-group-summary get" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<groupId: string, groupName: string, pictureUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/group/($groupId)/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get number of users in a group chat
#
# GET /v2/bot/group/{groupId}/members/count
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-members-group-count
# operationId: getGroupMemberCount
export def "bot-group-members-count get" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/group/($groupId)/members/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get number of users in a multi-person chat
#
# GET /v2/bot/room/{roomId}/members/count
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-members-room-count
# operationId: getRoomMemberCount
export def "bot-room-members-count get" [
  roomId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/room/($roomId)/members/count")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create rich menu
#
# POST /v2/bot/richmenu
# Docs: https://developers.line.biz/en/reference/messaging-api/#create-rich-menu
# operationId: createRichMenu
# --size shape: {width?: int, height?: int}
# --areas item shape: {bounds?: record, action?: record}
export def "bot-richmenu createRichMenu" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: record # Rich menu size — shape: {width?: int, height?: int}
  --selected: oneof<nothing, bool> # `true` to display the rich menu by default. Otherwise, `false`.
  --name: string # Name of the rich menu. This value can be used to help manage your rich menus and is not displayed to users.
  --chatBarText: string # Text displayed in the chat bar
  --areas: list # Array of area objects which define the coordinates and size of tappable areas — item shape: {bounds?: record, action?: record}
]: any -> record<richMenuId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu")
  let body = {size: $size, selected: $selected, name: $name, chatBarText: $chatBarText, areas: $areas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate rich menu object
#
# POST /v2/bot/richmenu/validate
# Docs: https://developers.line.biz/en/reference/messaging-api/#validate-rich-menu-object
# operationId: validateRichMenuObject
# --size shape: {width?: int, height?: int}
# --areas item shape: {bounds?: record, action?: record}
export def "bot-richmenu-validate validateRichMenuObject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: record # Rich menu size — shape: {width?: int, height?: int}
  --selected: oneof<nothing, bool> # `true` to display the rich menu by default. Otherwise, `false`.
  --name: string # Name of the rich menu. This value can be used to help manage your rich menus and is not displayed to users.
  --chatBarText: string # Text displayed in the chat bar
  --areas: list # Array of area objects which define the coordinates and size of tappable areas — item shape: {bounds?: record, action?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu/validate")
  let body = {size: $size, selected: $selected, name: $name, chatBarText: $chatBarText, areas: $areas} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Download rich menu image.
#
# GET /v2/bot/richmenu/{richMenuId}/content
# Docs: https://developers.line.biz/en/reference/messaging-api/#download-rich-menu-image
# operationId: getRichMenuImage
export def "bot-richmenu-content get" [
  richMenuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://api-data.line.me")
  let full_url = (build-url $base $"/v2/bot/richmenu/($richMenuId)/content")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload rich menu image
#
# POST /v2/bot/richmenu/{richMenuId}/content
# Docs: https://developers.line.biz/en/reference/messaging-api/#upload-rich-menu-image
# operationId: setRichMenuImage
export def "bot-richmenu-content setRichMenuImage" [
  richMenuId: string
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
  let base = ($base_url | default "https://api-data.line.me")
  let full_url = (build-url $base $"/v2/bot/richmenu/($richMenuId)/content")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "*/*" $body
}

# Gets a rich menu via a rich menu ID.
#
# GET /v2/bot/richmenu/{richMenuId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-rich-menu
# operationId: getRichMenu
export def "bot-richmenu get" [
  richMenuId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<richMenuId: string, size: record<width: int, height: int>, selected: bool, name: string, chatBarText: string, areas: table<bounds: record, action: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/richmenu/($richMenuId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes a rich menu.
#
# DELETE /v2/bot/richmenu/{richMenuId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#delete-rich-menu
# operationId: deleteRichMenu
export def "bot-richmenu delete" [
  richMenuId: string
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
  let full_url = (build-url $base $"/v2/bot/richmenu/($richMenuId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rich menu list
#
# GET /v2/bot/richmenu/list
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-rich-menu-list
# operationId: getRichMenuList
export def "bot-richmenu-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<richmenus: table<richMenuId: string, size: record, selected: bool, name: string, chatBarText: string, areas: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set default rich menu
#
# POST /v2/bot/user/all/richmenu/{richMenuId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#set-default-rich-menu
# operationId: setDefaultRichMenu
export def "bot-user-all-richmenu setDefaultRichMenu" [
  richMenuId: string
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
  let full_url = (build-url $base $"/v2/bot/user/all/richmenu/($richMenuId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the ID of the default rich menu set with the Messaging API.
#
# GET /v2/bot/user/all/richmenu
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-default-rich-menu-id
# operationId: getDefaultRichMenuId
export def "bot-user-all-richmenu get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<richMenuId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/user/all/richmenu")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel default rich menu
#
# DELETE /v2/bot/user/all/richmenu
# Docs: https://developers.line.biz/en/reference/messaging-api/#cancel-default-rich-menu
# operationId: cancelDefaultRichMenu
export def "bot-user-all-richmenu cancelDefaultRichMenu" [
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
  let full_url = (build-url $base "/v2/bot/user/all/richmenu")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create rich menu alias
#
# POST /v2/bot/richmenu/alias
# Docs: https://developers.line.biz/en/reference/messaging-api/#create-rich-menu-alias
# operationId: createRichMenuAlias
export def "bot-richmenu-alias createRichMenuAlias" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  richMenuAliasId: string # Rich menu alias ID, which can be any ID, unique for each channel.
  richMenuId: string # The rich menu ID to be associated with the rich menu alias.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu/alias")
  let body = {richMenuAliasId: $richMenuAliasId, richMenuId: $richMenuId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get rich menu alias information
#
# GET /v2/bot/richmenu/alias/{richMenuAliasId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-rich-menu-alias-by-id
# operationId: getRichMenuAlias
export def "bot-richmenu-alias get" [
  richMenuAliasId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<richMenuAliasId: string, richMenuId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/richmenu/alias/($richMenuAliasId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update rich menu alias
#
# POST /v2/bot/richmenu/alias/{richMenuAliasId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#update-rich-menu-alias
# operationId: updateRichMenuAlias
export def "bot-richmenu-alias updateRichMenuAlias" [
  richMenuAliasId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  richMenuId: string # The rich menu ID to be associated with the rich menu alias.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/richmenu/alias/($richMenuAliasId)")
  let body = {richMenuId: $richMenuId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete rich menu alias
#
# DELETE /v2/bot/richmenu/alias/{richMenuAliasId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#delete-rich-menu-alias
# operationId: deleteRichMenuAlias
export def "bot-richmenu-alias delete" [
  richMenuAliasId: string
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
  let full_url = (build-url $base $"/v2/bot/richmenu/alias/($richMenuAliasId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get list of rich menu alias
#
# GET /v2/bot/richmenu/alias/list
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-rich-menu-alias-list
# operationId: getRichMenuAliasList
export def "bot-richmenu-alias-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<aliases: table<richMenuAliasId: string, richMenuId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu/alias/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rich menu ID of user
#
# GET /v2/bot/user/{userId}/richmenu
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-rich-menu-id-of-user
# operationId: getRichMenuIdOfUser
export def "bot-user-richmenu get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<richMenuId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/user/($userId)/richmenu")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlink rich menu from user
#
# DELETE /v2/bot/user/{userId}/richmenu
# Docs: https://developers.line.biz/en/reference/messaging-api/#unlink-rich-menu-from-user
# operationId: unlinkRichMenuIdFromUser
export def "bot-user-richmenu unlinkRichMenuIdFromUser" [
  userId: string
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
  let full_url = (build-url $base $"/v2/bot/user/($userId)/richmenu")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link rich menu to user.
#
# POST /v2/bot/user/{userId}/richmenu/{richMenuId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#link-rich-menu-to-user
# operationId: linkRichMenuIdToUser
export def "bot-user-richmenu linkRichMenuIdToUser" [
  userId: string
  richMenuId: string
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
  let full_url = (build-url $base $"/v2/bot/user/($userId)/richmenu/($richMenuId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link rich menu to multiple users
#
# POST /v2/bot/richmenu/bulk/link
# Docs: https://developers.line.biz/en/reference/messaging-api/#link-rich-menu-to-users
# operationId: linkRichMenuIdToUsers
export def "bot-richmenu-bulk-link linkRichMenuIdToUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  richMenuId: string # ID of a rich menu
  userIds: list # Array of user IDs. Found in the `source` object of webhook event objects. Do not use the LINE ID used in LINE.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu/bulk/link")
  let body = {richMenuId: $richMenuId, userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlink rich menus from multiple users
#
# POST /v2/bot/richmenu/bulk/unlink
# Docs: https://developers.line.biz/en/reference/messaging-api/#unlink-rich-menu-from-users
# operationId: unlinkRichMenuIdFromUsers
export def "bot-richmenu-bulk-unlink unlinkRichMenuIdFromUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userIds: list # Array of user IDs. Found in the `source` object of webhook event objects. Do not use the LINE ID used in LINE.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu/bulk/unlink")
  let body = {userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# You can use this endpoint to batch control the rich menu linked to the users using the endpoint such as Link rich menu to user. The following operations are available:  1. Replace a rich menu with another rich menu for all users linked to a specific rich menu 2. Unlink a rich menu for all users linked to a specific rich menu 3. Unlink a rich menu for all users linked the rich menu
#
# POST /v2/bot/richmenu/batch
# Docs: https://developers.line.biz/en/reference/messaging-api/#batch-control-rich-menus-of-users
# operationId: richMenuBatch
# --operations item shape: {type: "link"|"unlink"|"unlinkAll"}
export def "bot-richmenu-batch richMenuBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  operations: list # Array of Rich menu operation object... — item shape: {type: "link"|"unlink"|"unlinkAll"}
  --resumeRequestKey: string # Key for retry. Key value is a string matching the regular expression pattern
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu/batch")
  let body = {operations: $operations, resumeRequestKey: $resumeRequestKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Validate a request body of the Replace or unlink the linked rich menus in batches endpoint.
#
# POST /v2/bot/richmenu/validate/batch
# Docs: https://developers.line.biz/en/reference/messaging-api/#validate-batch-control-rich-menus-request
# operationId: validateRichMenuBatchRequest
# --operations item shape: {type: "link"|"unlink"|"unlinkAll"}
export def "bot-richmenu-validate-batch validateRichMenuBatchRequest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  operations: list # Array of Rich menu operation object... — item shape: {type: "link"|"unlink"|"unlinkAll"}
  --resumeRequestKey: string # Key for retry. Key value is a string matching the regular expression pattern
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/richmenu/validate/batch")
  let body = {operations: $operations, resumeRequestKey: $resumeRequestKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get the status of Replace or unlink a linked rich menus in batches.
#
# GET /v2/bot/richmenu/progress/batch
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-batch-control-rich-menus-progress-status
# operationId: getRichMenuBatchProgress
export def "bot-richmenu-progress-batch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --requestId: string # A request ID used to batch control the rich menu linked to the user. Each Messaging API request has a request ID.
]: nothing -> record<phase: string, acceptedTime: string, completedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "requestId" $requestId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/richmenu/progress/batch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issue link token
#
# POST /v2/bot/user/{userId}/linkToken
# Docs: https://developers.line.biz/en/reference/messaging-api/#issue-link-token
# operationId: issueLinkToken
export def "bot-user-link-token issueLinkToken" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<linkToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/user/($userId)/linkToken")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark messages from users as read
#
# POST /v2/bot/message/markAsRead
# Docs: https://developers.line.biz/en/reference/partner-docs/#mark-messages-from-users-as-read
# operationId: markMessagesAsRead
# --chat shape: {userId: string}
export def "bot-message-mark-as-read markMessagesAsRead" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  chat: record # Chat reference — shape: {userId: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/message/markAsRead")
  let body = {chat: $chat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send LINE notification message
#
# POST /bot/pnp/push
# Docs: https://developers.line.biz/en/reference/partner-docs/#send-line-notification-message
# operationId: pushMessagesByPhone
# --messages item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
export def "bot-pnp-push pushMessagesByPhone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Line-Delivery-Tag: string # String returned in the delivery.data property of the delivery completion event via Webhook.
  messages: list # Message to be sent. — item shape: {type: "text"|"textV2"|"sticker"|"image"|"video"|"audio"|"location"|"imagemap"|"template"|"flex"|"coupon", quickReply?: record, sender?: record}
  --body-to: string # Message destination. Specify a phone number that has been normalized to E.164 format and hashed with SHA256.
  --notificationDisabled: oneof<nothing, bool> # `true`: The user doesn’t receive a push notification when a message is sent. `false`: The user receives a push notification when the message is sent (unless they have disabled push notifications in LINE and/or their device). The default value is false.  (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/bot/pnp/push")
  let body = {messages: $messages, to: $body_to, notificationDisabled: $notificationDisabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Line-Delivery-Tag": $X_Line_Delivery_Tag} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get number of sent LINE notification messages
#
# GET /v2/bot/message/delivery/pnp
# Docs: https://developers.line.biz/en/reference/partner-docs/#get-number-of-sent-line-notification-messages
# operationId: getPNPMessageStatistics
export def "bot-message-delivery-pnp get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --date: string # Date the message was sent  Format: `yyyyMMdd` (Example:`20211231`) Time zone: UTC+9
]: nothing -> record<status: string, success: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "date" $date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/message/delivery/pnp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a user's membership subscription.
#
# GET /v2/bot/membership/subscription/{userId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-a-users-membership-subscription-status
# operationId: getMembershipSubscription
export def "bot-membership-subscription get" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<subscriptions: table<membership: record, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/membership/subscription/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of memberships.
#
# GET /v2/bot/membership/list
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-membership-plans
# operationId: getMembershipList
export def "bot-membership-list get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<memberships: table<membershipId: int, title: string, description: string, benefits: list, price: float, currency: string, memberCount: int, memberLimit: int, isInAppPurchase: bool, isPublished: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/membership/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of user IDs who joined the membership.
#
# GET /v2/bot/membership/{membershipId}/users/ids
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-membership-user-ids
# operationId: getJoinedMembershipUsers
export def "bot-membership-users-ids get" [
  membershipId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # A continuation token to get next remaining membership user IDs. Returned only when there are remaining user IDs that weren't returned in the userIds property in the previous request. The continuation token expires in 24 hours (86,400 seconds).
  --limit: int # The max number of items to return for this API call. The value is set to 300 by default, but the max acceptable value is 1000.  (format: int32, default: 300)
]: nothing -> record<userIds: list<string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/bot/membership/($membershipId)/users/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a paginated list of coupons.
#
# GET /v2/bot/coupon
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-coupons-list
# operationId: listCoupon
export def "bot-coupon listCoupon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: list # Filter coupons by their status.
  --start: string # Pagination token to retrieve the next page of results.
  --limit: int # Maximum number of coupons to return per request. (format: int32, default: 20)
]: nothing -> record<items: table<couponId: string, title: string>, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "multi") (serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bot/coupon" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new coupon. Define coupon details such as type, title, and validity period.
#
# POST /v2/bot/coupon
# Docs: https://developers.line.biz/en/reference/messaging-api/#create-coupon
# operationId: createCoupon
# --acquisitionCondition shape: {type: "normal"|"lottery"}
# --reward shape: {type: "cashBack"|"discount"|"free"|"gift"|"others"}
export def "bot-coupon createCoupon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  acquisitionCondition: record # shape: {type: "normal"|"lottery"}
  --barcodeImageUrl: string # URL of the barcode image associated with the coupon. Used for in-store redemption.
  --couponCode: string # Unique code to be presented by the user to redeem the coupon. Optional.
  --description: string # Detailed description of the coupon. Displayed to users.
  endTimestamp: int # Coupon expiration time (epoch seconds). Coupon cannot be used after this time. (format: int64)
  --imageUrl: string # URL of the main image representing the coupon. Displayed in the coupon list.
  maxUseCountPerTicket: int # Maximum number of times a single coupon ticket can be used. Use -1 to indicate no limit. (format: int32)
  startTimestamp: int # Coupon start time (epoch seconds). Coupon can be used from this time. (format: int64)
  title: string # Title of the coupon. Displayed in the coupon list.
  --usageCondition: string # Conditions for using the coupon. Shown to users.
  --reward: record # shape: {type: "cashBack"|"discount"|"free"|"gift"|"others"}
  visibility: string@visibility-completer # Visibility of the coupon. Determines who can see or acquire the coupon.
  timezone: string@timezone-completer # Timezone for interpreting start and end timestamps.
]: any -> record<couponId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/coupon")
  let body = {acquisitionCondition: $acquisitionCondition, barcodeImageUrl: $barcodeImageUrl, couponCode: $couponCode, description: $description, endTimestamp: $endTimestamp, imageUrl: $imageUrl, maxUseCountPerTicket: $maxUseCountPerTicket, startTimestamp: $startTimestamp, title: $title, usageCondition: $usageCondition, reward: $reward, visibility: $visibility, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get coupon detail
#
# GET /v2/bot/coupon/{couponId}
# Docs: https://developers.line.biz/en/reference/messaging-api/#get-coupon
# operationId: getCouponDetail
export def "bot-coupon get" [
  couponId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<acquisitionCondition: record<type: string>, barcodeImageUrl: string, couponCode: string, description: string, endTimestamp: int, imageUrl: string, maxAcquireCount: int, maxUseCountPerTicket: int, maxTicketPerUser: int, startTimestamp: int, title: string, usageCondition: string, reward: record<type: string>, visibility: string, timezone: string, couponId: string, createdTimestamp: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/bot/coupon/($couponId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Close coupon
#
# PUT /v2/bot/coupon/{couponId}/close
# Docs: https://developers.line.biz/en/reference/messaging-api/#discontinue-coupon
# operationId: closeCoupon
export def "bot-coupon-close closeCoupon" [
  couponId: string
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
  let full_url = (build-url $base $"/v2/bot/coupon/($couponId)/close")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Display a loading animation in one-on-one chats between users and LINE Official Accounts.
#
# POST /v2/bot/chat/loading/start
# Docs: https://developers.line.biz/en/reference/messaging-api/#display-a-loading-indicator
# operationId: showLoadingAnimation
export def "bot-chat-loading-start showLoadingAnimation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  chatId: string # User ID of the target user for whom the loading animation is to be displayed.
  --loadingSeconds: int # The number of seconds to display the loading indicator. It must be a multiple of 5. The maximum value is 60 seconds.  (format: int32)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/chat/loading/start")
  let body = {chatId: $chatId, loadingSeconds: $loadingSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark messages from users as read by token
#
# POST /v2/bot/chat/markAsRead
# Docs: https://developers.line.biz/en/reference/messaging-api/#mark-as-read
# operationId: markMessagesAsReadByToken
export def "bot-chat-mark-as-read markMessagesAsReadByToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  markAsReadToken: string # Token used to mark messages as read.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/bot/chat/markAsRead")
  let body = {markAsReadToken: $markAsReadToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
