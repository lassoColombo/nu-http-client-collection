# Auto-generated client for Platform API v1.1.0
# Source: https://api.apis.guru/v2/specs/ably.io/platform/1.1.0/openapi.json
# Auth: --token flag or $env.PLATFORM_API_TOKEN

const BASE_URL = "https://rest.ably.io"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PLATFORM_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://rest.ably.io"] }
def auth-scheme-completer [] { ["basic" "bearer" "none" "basic-credentials"] }

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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "channels get-metadata-of-list" } } | get name | first)
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
export def "channels get-metadata-of-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "limit": $limit, "prefix": $prefix, "by": $by} | compact), body: null}
}

# Get metadata of a channel
#
# GET /channels/{channel_id}
# operationId: getMetadataOfChannel
export def "channels get-metadata" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<channelId: string, isGlobalMaster: bool, region: string, status: record<isActive: bool, occupancy: record<presenceConnections: int, presenceMembers: int, presenceSubscribers: int, publishers: int, subscribers: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: string
  --limit: int # default: 100
  --end: string # default: now
  --direction: string@direction-completer # default: backwards
]: nothing -> table<clientId: string, connectionId: string, data: string, encoding: string, extras: record<push: record>, id: string, name: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/messages") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "limit": $limit, "end": $end, "direction": $direction} | compact), body: null}
}

# Publish a message to a channel
#
# POST /channels/{channel_id}/messages
# operationId: publishMessagesToChannel
# --extras shape: {push?: record}
export def "channels-messages publish" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/messages"))
  let req_body = {"clientId": $client_id, "connectionId": $connection_id, "data": $data, "encoding": $encoding, "extras": $extras, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get presence of a channel
#
# GET /channels/{channel_id}/presence
# operationId: getPresenceOfChannel
export def "channels-presence get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --client-id: string
  --connection-id: string
  --limit: int # default: 100
]: nothing -> table<action: string, clientId: string, connectionId: string, data: string, encoding: string, extras: record<push: record>, id: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let qp = [(serialize-qp "clientId" $client_id "scalar") (serialize-qp "connectionId" $connection_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/presence") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"clientId": $client_id, "connectionId": $connection_id, "limit": $limit} | compact), body: null}
}

# Get presence history of a channel
#
# GET /channels/{channel_id}/presence/history
# operationId: getPresenceHistoryOfChannel
export def "channels-presence-history get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: string
  --limit: int # default: 100
  --end: string # default: now
  --direction: string@direction-completer # default: backwards
]: nothing -> table<action: string, clientId: string, connectionId: string, data: string, encoding: string, extras: record<push: record>, id: string, timestamp: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_id | is-empty) { error make --unspanned { msg: "path parameter 'channel_id' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "direction" $direction "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/channels/{channel_id}/presence/history") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "limit": $limit, "end": $end, "direction": $direction} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($key_name | is-empty) { error make --unspanned { msg: "path parameter 'keyName' must be non-empty" } }
  let full_url = (build-url $base ({key_name: (encode-path-segment $key_name)} | format pattern "/keys/{key_name}/requestToken"))
  let req_body = {"capability": $capability, "clientId": $client_id, "keyName": $body_key_name, "nonce": $nonce, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a registered device's update token
#
# DELETE /push/channelSubscriptions
# operationId: deletePushDeviceDetails
export def "push-channel-subscriptions delete-device-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "channel": $channel, "deviceId": $device_id, "clientId": $client_id} | compact), body: null}
}

# List channel subscriptions
#
# GET /push/channelSubscriptions
# operationId: getPushSubscriptionsOnChannels
export def "push-channel-subscriptions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "channel": $channel, "deviceId": $device_id, "clientId": $client_id, "limit": $limit} | compact), body: null}
}

# Subscribe a device to a channel
#
# POST /push/channelSubscriptions
# operationId: subscribePushDeviceToChannel
export def "push-channel-subscriptions subscribe-device" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"channel": $channel, "deviceId": $device_id, "clientId": $client_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"format": $format} | compact), body: $req_body}
}

# List all channels with at least one subscribed device
#
# GET /push/channels
# operationId: getChannelsWithPushSubscribers
export def "push-channels get-with-subscribers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # The response format you would like
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/push/channels" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format} | compact), body: null}
}

# Unregister matching devices for push notifications
#
# DELETE /push/deviceRegistrations
# operationId: unregisterAllPushDevices
export def "push-device-registrations delete-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "deviceId": $device_id, "clientId": $client_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format, "deviceId": $device_id, "clientId": $client_id, "limit": $limit} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"clientId": $client_id, "deviceSecret": $device_secret, "formFactor": $form_factor, "id": $id, "metadata": $metadata, "platform": $platform, "push.recipient": $push_recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"format": $format} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'device_id' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/push/deviceRegistrations/{device_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a device registration
#
# GET /push/deviceRegistrations/{device_id}
# operationId: getPushDeviceDetails
export def "push-device-registrations get-details" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'device_id' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/push/deviceRegistrations/{device_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a device registration
#
# PATCH /push/deviceRegistrations/{device_id}
# operationId: patchPushDeviceDetails
# --push.recipient shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
export def "push-device-registrations update-details-by-device-id" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'device_id' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/push/deviceRegistrations/{device_id}"))
  let req_body = {"clientId": $client_id, "deviceSecret": $device_secret, "formFactor": $form_factor, "id": $id, "metadata": $metadata, "platform": $platform, "push.recipient": $push_recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update a device registration
#
# PUT /push/deviceRegistrations/{device_id}
# operationId: putPushDeviceDetails
# --push.recipient shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
export def "push-device-registrations update-details-by-device-id-1" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'device_id' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/push/deviceRegistrations/{device_id}"))
  let req_body = {"clientId": $client_id, "deviceSecret": $device_secret, "formFactor": $form_factor, "id": $id, "metadata": $metadata, "platform": $platform, "push.recipient": $push_recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reset a registered device's update token
#
# GET /push/deviceRegistrations/{device_id}/resetUpdateToken
# operationId: updatePushDeviceDetails
export def "push-device-registrations-reset-update-token update-details" [
  device_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<clientId: string, deviceSecret: string, formFactor: string, id: string, metadata: record, platform: string, push_recipient: record<clientId: string, deviceId: string, deviceToken: string, registrationToken: string, transportType: string>, push_state: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($device_id | is-empty) { error make --unspanned { msg: "path parameter 'device_id' must be non-empty" } }
  let full_url = (build-url $base ({device_id: (encode-path-segment $device_id)} | format pattern "/push/deviceRegistrations/{device_id}/resetUpdateToken"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Publish a push notification to device(s)
#
# POST /push/publish
# operationId: publishPushNotificationToDevices
# --push shape: {apns?: record, data?: string, fcm?: record, notification?: record, web?: record}
# --recipient shape: {clientId?: string, deviceId?: string, deviceToken?: string, registrationToken?: string, transportType?: "apns"|"fcm"|"gcm"}
export def "push-publish publish-notification-to-devices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"push": $push, "recipient": $recipient} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"format": $format} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "limit": $limit, "end": $end, "direction": $direction, "unit": $unit} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --format: string@format-completer # The response format you would like
  --x-ably-version: string # The version of the API you wish to use.
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/time" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Ably-Version": $x_ably_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"format": $format} | compact), body: null}
}
