# Auto-generated client for Platform API v1.1.0
# Source: https://api.apis.guru/v2/specs/ably.io/platform/1.1.0/openapi.json
# Auth: --token flag or $env.PLATFORM_API_TOKEN

const BASE_URL = "https://rest.ably.io"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PLATFORM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://rest.ably.io"] }
def auth-scheme-completer [] { ["basic" "bearer"] }

# Completers for enum parameters
def format-completer [] { ["html" "json" "jsonp" "msgpack"] }
def by-completer [] { ["id" "value"] }
def accept-completer [] { ["application/json" "application/x-msgpack" "text/html"] }
def direction-completer [] { ["backwards" "forwards"] }
def accept-completer-1 [] { ["application/json" "application/x-msgpack"] }
def form-factor-completer [] { ["car" "desktop" "embedded" "phone" "tablet" "tv" "watch"] }
def platform-completer [] { ["android" "ios"] }
def unit-completer [] { ["day" "hour" "minute" "month"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "channels get-metadata-of-all" } } | get name | first)
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

# Enumerate all active channels of the application
#
# GET /channels
# operationId: getMetadataOfAllChannels
export def "channels get-metadata-of-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # The response format you would like
  --limit: int # default: 100
  --prefix: string # Optionally limits the query to only those channels whose name starts with the given prefix
  --by: string@by-completer # optionally specifies whether to return just channel names (by=id) or ChannelDetails (by=value)
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "prefix" $prefix "scalar") (serialize-qp "by" $by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get metadata of a channel
#
# GET /channels/{channel_id}
# operationId: getMetadataOfChannel
export def "channels get-metadata-of" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<channelId: string, isGlobalMaster: bool, region: string, status: record<isActive: bool, occupancy: record<presenceConnections: int, presenceMembers: int, presenceSubscribers: int, publishers: int, subscribers: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_id: $channel_id} | format pattern "/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get message history for a channel
#
# GET /channels/{channel_id}/messages
# operationId: getMessagesByChannel
export def "channels-messages get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: string
  --limit: int # default: 100
  --end: string # default: now
  --direction: string@direction-completer # default: backwards
]: nothing -> table<clientId: string, connectionId: string, data: string, encoding: string, extras: record<push: record>, id: string, name: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: $channel_id} | format pattern "/channels/{channel_id}/messages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publish a message to a channel
#
# POST /channels/{channel_id}/messages
# operationId: publishMessagesToChannel
# --extras shape: {push?: record}
export def "channels-messages publish-messages-to" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string # The [client ID](https://www.ably.io/documentation/core-features/authentication#identified-clients) of the publisher of this message.
  --connection-id: string # The connection ID of the publisher of this message.
  --data: string # The string encoded payload, with the encoding specified below.
  --encoding: string # This will typically be empty as all messages received from Ably are automatically decoded client-side using this value. However, if the message encoding cannot be processed, this attribute will contain the remaining transformations not applied to the data payload.
  --extras: record # Extras object. Currently only allows for [push](https://www.ably.io/documentation/general/push/publish#channel-broadcast-example) extra. — shape: {push?: record}
  --name: string # The event name, if provided.
]: any -> record<channel: string, messageId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_id: $channel_id} | format pattern "/channels/{channel_id}/messages"))
  let body = {"clientId": $client_id, "connectionId": $connection_id, "data": $data, "encoding": $encoding, "extras": $extras, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get presence of a channel
#
# GET /channels/{channel_id}/presence
# operationId: getPresenceOfChannel
export def "channels-presence get-presence-of" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string
  --connection-id: string
  --limit: int # default: 100
]: nothing -> table<action: string, clientId: string, connectionId: string, data: string, encoding: string, extras: record<push: record>, id: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "connectionId" $connection_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: $channel_id} | format pattern "/channels/{channel_id}/presence") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get presence history of a channel
#
# GET /channels/{channel_id}/presence/history
# operationId: getPresenceHistoryOfChannel
export def "channels-presence-history get-presence-history-of" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: string
  --limit: int # default: 100
  --end: string # default: now
  --direction: string@direction-completer # default: backwards
]: nothing -> table<action: string, clientId: string, connectionId: string, data: string, encoding: string, extras: record<push: record>, id: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: $channel_id} | format pattern "/channels/{channel_id}/presence/history") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request an access token
#
# POST /keys/{keyName}/requestToken
# operationId: requestAccessToken
export def "keys-request-token request-access" [
  key_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --capability: record # The [capabilities](https://www.ably.io/documentation/core-features/authentication#capabilities-explained) (i.e. a set of channel names/namespaces and, for each, a set of operations) which should be a subset of the set of capabilities associated with the key specified in keyName. (e.g. {channel1: [publish, subscribe]})
  --client-id: string # The [client ID](https://www.ably.io/documentation/core-features/authentication#identified-clients) to be assosciated with the token. Can be set to * to allow for any client ID to be used.
  --body-key-name: string # Name of the key used for the TokenRequest. The keyName comprises of the app ID and key ID on an API Key. (e.g. xVLyHw.LMJZxw)
  --nonce: string # An unquoted, un-escaped random string of at least 16 characters. Used to ensure the Ably TokenRequest cannot be reused.
  --timestamp: int # Time of creation of the Ably TokenRequest.
]: any -> record<capability: string, expires: int, issued: int, keyName: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key_name: $key_name} | format pattern "/keys/{key_name}/requestToken"))
  let body = {"capability": $capability, "clientId": $client_id, "keyName": $body_key_name, "nonce": $nonce, "timestamp": $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a registered device's update token
#
# DELETE /push/channelSubscriptions
# operationId: deletePushDeviceDetails
export def "push-channel-subscriptions delete-push-device-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The response format you would like
  --channel: string # Filter to restrict to subscriptions associated with that channel.
  --device-id: string # Must be set when clientId is empty, cannot be used with clientId.
  --client-id: string # Must be set when deviceId is empty, cannot be used with deviceId.
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "deviceId" $device_id "scalar") (serialize-qp "clientId" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/channelSubscriptions" $qp)
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List channel subscriptions
#
# GET /push/channelSubscriptions
# operationId: getPushSubscriptionsOnChannels
export def "push-channel-subscriptions get-push-subscriptions-on" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The response format you would like
  --channel: string # Filter to restrict to subscriptions associated with that channel.
  --device-id: string # Optional filter to restrict to devices associated with that deviceId. Cannot be used with clientId.
  --client-id: string # Optional filter to restrict to devices associated with that clientId. Cannot be used with deviceId.
  --limit: int # The maximum number of records to return. (default: 100)
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "deviceId" $device_id "scalar") (serialize-qp "clientId" $client_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/channelSubscriptions" $qp)
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe a device to a channel
#
# POST /push/channelSubscriptions
# operationId: subscribePushDeviceToChannel
export def "push-channel-subscriptions subscribe-push-device-to" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The response format you would like
  --x-ably-version: string # The version of the API you wish to use.
  --channel: string # Channel name.
  --device-id: string # Must be set when clientId is empty, cannot be used with clientId.
  --client-id: string # Must be set when deviceId is empty, cannot be used with deviceId.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/channelSubscriptions" $qp)
  let body = {"channel": $channel, "deviceId": $device_id, "clientId": $client_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all channels with at least one subscribed device
#
# GET /push/channels
# operationId: getChannelsWithPushSubscribers
export def "push-channels get-channels-with-push-subscribers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # The response format you would like
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/channels" $qp)
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unregister matching devices for push notifications
#
# DELETE /push/deviceRegistrations
# operationId: unregisterAllPushDevices
export def "push-device-registrations delete-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The response format you would like
  --device-id: string # Optional filter to restrict to devices associated with that deviceId. Cannot be used with clientId.
  --client-id: string # Optional filter to restrict to devices associated with that clientId. Cannot be used with deviceId.
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "deviceId" $device_id "scalar") (serialize-qp "clientId" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/deviceRegistrations" $qp)
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List devices registered for receiving push notifications
#
# GET /push/deviceRegistrations
# operationId: getRegisteredPushDevices
export def "push-device-registrations get-registered" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # The response format you would like
  --device-id: string # Optional filter to restrict to devices associated with that deviceId.
  --client-id: string # Optional filter to restrict to devices associated with that clientId.
  --limit: int # The maximum number of records to return. (default: 100)
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "deviceId" $device_id "scalar") (serialize-qp "clientId" $client_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/deviceRegistrations" $qp)
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register a device for receiving push notifications
#
# POST /push/deviceRegistrations
# operationId: registerPushDevice
# --push.recipient shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
export def "push-device-registrations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # The response format you would like
  --x-ably-version: string # The version of the API you wish to use.
  --client-id: string # Optional trusted client identifier for the device.
  --device-secret: string # Secret value for the device.
  --form-factor: string@form-factor-completer # Form factor of the push device.
  --id: string # Unique identifier for the device generated by the device itself.
  --metadata: record # Optional metadata object for this device. The metadata for a device may only be set by clients with push-admin privileges and will be used more extensively in the future with smart notifications.
  --platform: string@platform-completer # Platform of the push device.
  --push-recipient: record # Push recipient details for a device. — shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
]: any -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/deviceRegistrations" $qp)
  let body = {"clientId": $client_id, "deviceSecret": $device_secret, "formFactor": $form_factor, "id": $id, "metadata": $metadata, "platform": $platform, "push.recipient": $push_recipient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unregister a single device for push notifications
#
# DELETE /push/deviceRegistrations/{device_id}
# operationId: unregisterPushDevice
export def "push-device-registrations delete" [
  device_id: string
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_id: $device_id} | format pattern "/push/deviceRegistrations/{device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a device registration
#
# GET /push/deviceRegistrations/{device_id}
# operationId: getPushDeviceDetails
export def "push-device-registrations get-push-device-details" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_id: $device_id} | format pattern "/push/deviceRegistrations/{device_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a device registration
#
# PATCH /push/deviceRegistrations/{device_id}
# operationId: patchPushDeviceDetails
# --push.recipient shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
export def "push-device-registrations update-push-device-details-by-device_id" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string # Optional trusted client identifier for the device.
  --device-secret: string # Secret value for the device.
  --form-factor: string@form-factor-completer # Form factor of the push device.
  --id: string # Unique identifier for the device generated by the device itself.
  --metadata: record # Optional metadata object for this device. The metadata for a device may only be set by clients with push-admin privileges and will be used more extensively in the future with smart notifications.
  --platform: string@platform-completer # Platform of the push device.
  --push-recipient: record # Push recipient details for a device. — shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
]: any -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_id: $device_id} | format pattern "/push/deviceRegistrations/{device_id}"))
  let body = {"clientId": $client_id, "deviceSecret": $device_secret, "formFactor": $form_factor, "id": $id, "metadata": $metadata, "platform": $platform, "push.recipient": $push_recipient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a device registration
#
# PUT /push/deviceRegistrations/{device_id}
# operationId: putPushDeviceDetails
# --push.recipient shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
export def "push-device-registrations update-push-device-details-by-device_id-1" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string # Optional trusted client identifier for the device.
  --device-secret: string # Secret value for the device.
  --form-factor: string@form-factor-completer # Form factor of the push device.
  --id: string # Unique identifier for the device generated by the device itself.
  --metadata: record # Optional metadata object for this device. The metadata for a device may only be set by clients with push-admin privileges and will be used more extensively in the future with smart notifications.
  --platform: string@platform-completer # Platform of the push device.
  --push-recipient: record # Push recipient details for a device. — shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
]: any -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_id: $device_id} | format pattern "/push/deviceRegistrations/{device_id}"))
  let body = {"clientId": $client_id, "deviceSecret": $device_secret, "formFactor": $form_factor, "id": $id, "metadata": $metadata, "platform": $platform, "push.recipient": $push_recipient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset a registered device's update token
#
# GET /push/deviceRegistrations/{device_id}/resetUpdateToken
# operationId: updatePushDeviceDetails
export def "push-device-registrations-reset-update-token update-push-device-details" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({device_id: $device_id} | format pattern "/push/deviceRegistrations/{device_id}/resetUpdateToken"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Publish a push notification to device(s)
#
# POST /push/publish
# operationId: publishPushNotificationToDevices
# --push shape: {apns?: record, data?: string, fcm?: record, notification?: record, web?: record}
# --recipient shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
export def "push-publish publish-push-notification-to-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The response format you would like
  --x-ably-version: string # The version of the API you wish to use.
  --push: record # shape: {apns?: record, data?: string, fcm?: record, notification?: record, web?: record}
  recipient: record # Push recipient details for a device. — shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/publish" $qp)
  let body = {"push": $push, "recipient": $recipient} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve usage statistics for an application
#
# GET /stats
# operationId: getStats
export def "stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: string
  --limit: int # default: 100
  --end: string # default: now
  --direction: string@direction-completer # default: backwards
  --unit: string@unit-completer # Specifies the unit of aggregation in the returned results. (default: minute)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "unit" $unit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the service time
#
# GET /time
# operationId: getTime
export def "time get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # The response format you would like
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/time" $qp)
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
