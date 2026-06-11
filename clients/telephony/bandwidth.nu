# Auto-generated client for Bandwidth v1.0.0
# Source: https://raw.githubusercontent.com/Bandwidth/node-sdk/main/bandwidth.yml
# Auth: --token flag or $env.BANDWIDTH_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BANDWIDTH_TOKEN | default "" }
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
def base-url-completer [] { ["http://localhost" "https://messaging.bandwidth.com/api/v2" "https://voice.bandwidth.com/api/v2" "https://mfa.bandwidth.com/api/v1" "https://api.bandwidth.com/v2" "https://api.bandwidth.com/api/v2"] }
def auth-scheme-completer [] { ["basic" "bearer"] }

# Completers for enum parameters
def messageStatus-completer [] { ["ACCEPTED" "DELIVERED" "FAILED" "QUEUED" "RECEIVED" "SENDING" "SENT" "UNDELIVERED"] }
def messageDirection-completer [] { ["INBOUND" "OUTBOUND"] }
def messageType-completer [] { ["mms" "rcs" "sms"] }
def product-completer [] { ["ALPHA_NUMERIC" "HOSTED_SHORT_CODE" "LOCAL_A2P" "P2P" "RBM_CONVERSATIONAL" "RBM_MEDIA" "RBM_RICH" "SHORT_CODE_REACH" "TOLL_FREE"] }
def priority-completer [] { ["default" "high"] }
def answerMethod-completer [] { ["GET" "POST"] }
def answerFallbackMethod-completer [] { ["GET" "POST"] }
def disconnectMethod-completer [] { ["GET" "POST"] }
def state-completer [] { ["active" "completed"] }
def redirectMethod-completer [] { ["GET" "POST"] }
def redirectFallbackMethod-completer [] { ["GET" "POST"] }
def status-completer [] { ["active" "completed"] }
def state-completer-1 [] { ["paused" "recording"] }
def callbackMethod-completer [] { ["GET" "POST"] }
def businessRegistrationType-completer [] { ["ABN" "ACN" "BRN" "CBN" "CIF" "CNPJ" "CRN" "EIN" "NEQ" "NIF" "NZBN" "OTHER" "PROVINCIAL_NUMBER" "SIREN" "SIRET" "UID" "UST_IDNR" "VAT"] }
def businessEntityType-completer [] { ["GOVERNMENT" "NON_PROFIT" "PRIVATE_PROFIT" "PUBLIC_PROFIT" "SOLE_PROPRIETOR"] }
def type-completer [] { ["WEBRTC"] }
def status-completer-1 [] { ["CONNECTED" "DISCONNECTED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "users-media listMedia" } } | get name | first)
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

# List Media
#
# GET /users/{accountId}/media
# operationId: listMedia
export def "users-media listMedia" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Continuation-Token: string # Continuation token used to retrieve subsequent media. (e.g. 1XEi2tsFtLo1JbtLwETnM1ZJ+PqAa8w6ENvC5QKvwyrCDYII663Gy5M4s40owR1tjkuWUif6qbWvFtQJR5/ipqbUnfAqL254LKNlPy6tATCzioKSuHuOqgzloDkSwRtX0LtcL2otHS69hK343m+SjdL+vlj71tT39)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/users/($accountId)/media")
  let extra_headers = {"Continuation-Token": $Continuation_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Media
#
# GET /users/{accountId}/media/{mediaId}
# operationId: getMedia
export def "users-media get" [
  accountId: string
  mediaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/users/($accountId)/media/($mediaId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload Media
#
# PUT /users/{accountId}/media/{mediaId}
# operationId: uploadMedia
export def "users-media uploadMedia" [
  accountId: string
  mediaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # The media type of the entity-body. (e.g. audio/wav)
  --Cache-Control: string # General-header field is used to specify directives that MUST be obeyed by all caching mechanisms along the request/response chain. (e.g. no-cache)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/users/($accountId)/media/($mediaId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Cache-Control": $Cache_Control} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Media
#
# DELETE /users/{accountId}/media/{mediaId}
# operationId: deleteMedia
export def "users-media delete" [
  accountId: string
  mediaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/users/($accountId)/media/($mediaId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Messages
#
# GET /users/{accountId}/messages
# operationId: listMessages
export def "users-messages listMessages" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messageId: string # The ID of the message to search for. Special characters need to be encoded using URL encoding. Message IDs could come in different formats, e.g., 9e0df4ca-b18d-40d7-a59f-82fcdf5ae8e6 and 1589228074636lm4k2je7j7jklbn2 are valid message ID formats. Note that you must include at least one query parameter. (e.g. 9e0df4ca-b18d-40d7-a59f-82fcdf5ae8e6)
  --sourceTn: string # The phone number that sent the message. Accepted values are: a single full phone number a comma separated list of full phone numbers (maximum of 10) or a single partial phone number (minimum of 5 characters e.g. '%2B1919'). (e.g. %2B15554443333)
  --destinationTn: string # The phone number that received the message. Accepted values are: a single full phone number a comma separated list of full phone numbers (maximum of 10) or a single partial phone number (minimum of 5 characters e.g. '%2B1919'). (e.g. %2B15554443333)
  --messageStatus: string@messageStatus-completer # The status of the message. One of RECEIVED QUEUED SENDING SENT FAILED DELIVERED ACCEPTED UNDELIVERED. (e.g. RECEIVED)
  --messageDirection: string@messageDirection-completer # The direction of the message. One of INBOUND OUTBOUND. (e.g. INBOUND)
  --carrierName: string # The name of the carrier used for this message. Possible values include but are not limited to Verizon and TMobile. Special characters need to be encoded using URL encoding (i.e. AT&T should be passed as AT%26T). (e.g. Verizon)
  --messageType: string@messageType-completer # The type of message. Either sms or mms. (e.g. sms)
  --errorCode: int # The error code of the message. (e.g. 9902)
  --fromDateTime: string # The start of the date range to search in ISO 8601 format. Uses the message receive time. The date range to search in is currently 14 days. (e.g. 2022-09-14T18:20:16.000Z)
  --toDateTime: string # The end of the date range to search in ISO 8601 format. Uses the message receive time. The date range to search in is currently 14 days. (e.g. 2022-09-14T18:20:16.000Z)
  --campaignId: string # The campaign ID of the message. (e.g. CJEUMDK)
  --fromBwLatency: int # The minimum Bandwidth latency of the message in seconds. Only available for accounts with the Advanced Quality Metrics feature enabled. (e.g. 5)
  --bwQueued: string@bool-completer # A boolean value indicating whether the message is queued in the Bandwidth network. (e.g. true)
  --product: string@product-completer # Messaging product associated with the message. (e.g. P2P)
  --location: string # Location Id associated with the message. (e.g. 123ABC)
  --carrierQueued: string@bool-completer # A boolean value indicating whether the message is queued in the carrier network. Only available for OUTBOUND messages from accounts with the Advanced Quality Metrics feature enabled. (e.g. true)
  --fromCarrierLatency: int # The minimum carrier latency of the message in seconds. Only available for OUTBOUND messages from accounts with the Advanced Quality Metrics feature enabled. (e.g. 50)
  --callingNumberCountryA3: string # Calling number country in A3 format. (e.g. USA)
  --calledNumberCountryA3: string # Called number country in A3 format. (e.g. USA)
  --fromSegmentCount: int # Segment count (start range). (e.g. 1)
  --toSegmentCount: int # Segment count (end range). (e.g. 3)
  --fromMessageSize: int # Message size (start range). (e.g. 100)
  --toMessageSize: int # Message size (end range). (e.g. 120)
  --qp-sort: string # The field and direction to sort by combined with a colon. Direction is either asc or desc. (e.g. sourceTn:desc)
  --pageToken: string # A base64 encoded value used for pagination of results. (e.g. gdEewhcJLQRB5)
  --limit: int # The maximum records requested in search result. Default 100. The sum of limit and after cannot be more than 10000. (e.g. 50)
  --limitTotalCount: string@bool-completer # When set to true, the response's totalCount field will have a maximum value of 10,000. When set to false, or excluded, this will give an accurate totalCount of all messages that match the provided filters. If you are experiencing latency, try using this parameter to limit your results. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.bandwidth.com/api/v2")
  let qp = [(serialize-qp "messageId" $messageId "scalar") (serialize-qp "sourceTn" $sourceTn "scalar") (serialize-qp "destinationTn" $destinationTn "scalar") (serialize-qp "messageStatus" $messageStatus "scalar") (serialize-qp "messageDirection" $messageDirection "scalar") (serialize-qp "carrierName" $carrierName "scalar") (serialize-qp "messageType" $messageType "scalar") (serialize-qp "errorCode" $errorCode "scalar") (serialize-qp "fromDateTime" $fromDateTime "scalar") (serialize-qp "toDateTime" $toDateTime "scalar") (serialize-qp "campaignId" $campaignId "scalar") (serialize-qp "fromBwLatency" $fromBwLatency "scalar") (serialize-qp "bwQueued" $bwQueued "scalar") (serialize-qp "product" $product "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "carrierQueued" $carrierQueued "scalar") (serialize-qp "fromCarrierLatency" $fromCarrierLatency "scalar") (serialize-qp "callingNumberCountryA3" $callingNumberCountryA3 "scalar") (serialize-qp "calledNumberCountryA3" $calledNumberCountryA3 "scalar") (serialize-qp "fromSegmentCount" $fromSegmentCount "scalar") (serialize-qp "toSegmentCount" $toSegmentCount "scalar") (serialize-qp "fromMessageSize" $fromMessageSize "scalar") (serialize-qp "toMessageSize" $toMessageSize "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "limitTotalCount" $limitTotalCount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($accountId)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Message
#
# POST /users/{accountId}/messages
# operationId: createMessage
export def "users-messages createMessage" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  applicationId: string # The ID of the Application your from number or senderId is associated with in the Bandwidth App. (e.g. 93de2206-9669-4e07-948d-329f4b722ee2)
  --body-to: list # The phone number(s) the message should be sent to in E164 format. (e.g. [+15554443333, +15552223333])
  --body-from: string # Either an alphanumeric sender ID or the sender's Bandwidth phone number in E.164 format, which must be hosted within Bandwidth and linked to the account that is generating the message. Alphanumeric Sender IDs can contain up to 11 characters, upper-case letters A-Z, lower-case letters a-z, numbers 0-9, space, hyphen -, plus +, underscore _ and ampersand &. Alphanumeric Sender IDs must contain at least one letter. (e.g. +15551113333)
  --text: string # The contents of the text message. Must be 2048 characters or less. (e.g. Hello world)
  --media: list # A list of URLs to include as media attachments as part of the message. Each URL can be at most 4096 characters. (e.g. [https://dev.bandwidth.com/images/bandwidth-logo.png, https://dev.bandwidth.com/images/github_logo.png])
  --tag: string # A custom string that will be included in callback events of the message. Max 1024 characters. (e.g. custom string)
  --priority: string@priority-completer # Specifies the message's sending priority with respect to other messages in your account. For best results and optimal throughput, reserve the 'high' priority setting for critical messages only. (e.g. default)
  --expiration: string # A string with the date/time value that the message will automatically expire by. This must be a valid RFC-3339 value, e.g., 2021-03-14T01:59:26Z or 2021-03-13T20:59:26-05:00. Must be a date-time in the future. (format: date-time, e.g. 2021-02-01T11:29:18-05:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/users/($accountId)/messages")
  let body = {applicationId: $applicationId, to: $body_to, from: $body_from, text: $text, media: $media, tag: $tag, priority: $priority, expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Multi-Channel Message
#
# POST /users/{accountId}/messages/multiChannel
# operationId: createMultiChannelMessage
export def "users-messages-multi-channel createMultiChannelMessage" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # The phone number the message should be sent to in E164 format. (e.g. +15552223333)
  channelList: list # A list of message bodies. The messages will be attempted in the order they are listed. Once a message sends successfully, the others will be ignored.
  --tag: string # A custom string that will be included in callback events of the message. Max 1024 characters. (e.g. custom string)
  --priority: string@priority-completer # Specifies the message's sending priority with respect to other messages in your account. For best results and optimal throughput, reserve the 'high' priority setting for critical messages only. (e.g. default)
  --expiration: string # A string with the date/time value that the message will automatically expire by. This must be a valid RFC-3339 value, e.g., 2021-03-14T01:59:26Z or 2021-03-13T20:59:26-05:00. Must be a date-time in the future. (format: date-time, e.g. 2021-02-01T11:29:18-05:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/users/($accountId)/messages/multiChannel")
  let body = {to: $body_to, channelList: $channelList, tag: $tag, priority: $priority, expiration: $expiration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Call
#
# POST /accounts/{accountId}/calls
# operationId: createCall
# --machineDetection shape: {mode?: "sync"|"async", detectionTimeout?: float, silenceTimeout?: float, speechThreshold?: float, speechEndThreshold?: float, machineSpeechEndThreshold?: float, delayResult?: bool, callbackUrl?: string, callbackMethod?: "GET"|"POST", username?: string, password?: string, fallbackUrl?: string, fallbackMethod?: "GET"|"POST", fallbackUsername?: string, fallbackPassword?: string}
export def "accounts-calls createCall" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # The destination to call (must be an E.164 formatted number (e.g. `+15555551212`) or a SIP URI (e.g. `sip:user@server.example`)). (e.g. +19195551234)
  --body-from: string # A Bandwidth phone number on your account the call should come from (must be in E.164 format, like `+15555551212`) even if `privacy` is set to true. (e.g. +15555551212)
  --privacy: string@bool-completer # Hide the calling number. The `displayName` field can be used to customize the displayed name. (nullable, e.g. false)
  --displayName: string # The caller display name to use when the call is created. May not exceed 256 characters nor contain control characters such as new lines. If `privacy` is true, only the following values are valid: `Restricted`, `Anonymous`, `Private`, or `Unavailable`. (nullable, e.g. John Doe)
  --uui: string # A comma-separated list of 'User-To-User' headers to be sent in the INVITE when calling a SIP URI. Each value must end with an 'encoding' parameter as described in <a href='https://tools.ietf.org/html/rfc7433'>RFC 7433</a>. Only 'jwt', 'base64' and 'hex' encodings are allowed. The entire value cannot exceed 350 characters, including parameters and separators. (nullable, e.g. eyJhbGciOiJIUzI1NiJ9.WyJoaSJd.-znkjYyCkgz4djmHUPSXl9YrJ6Nix_XvmlwKGFh5ERM;encoding=jwt,aGVsbG8gd29ybGQ;encoding=base64)
  applicationId: string # The id of the application associated with the `from` number. (e.g. 1234-qwer-5679-tyui)
  answerUrl: string # The full URL to send the <a href='/docs/voice/webhooks/answer'>Answer</a> event to when the called party answers. This endpoint should return the first <a href='/docs/voice/bxml'>BXML document</a> to be executed in the call.  Must use `https` if specifying `username` and `password`. (format: uri, e.g. https://www.myCallbackServer.example/webhooks/answer)
  --answerMethod: string@answerMethod-completer # The HTTP method to use to deliver the callback. GET or POST. Default value is POST. (nullable, default: POST, e.g. POST)
  --username: string # Basic auth username. (nullable, e.g. mySecretUsername)
  --password: string # Basic auth password. (nullable, e.g. mySecretPassword1!)
  --answerFallbackUrl: string # A fallback url which, if provided, will be used to retry the `answer` webhook delivery in case `answerUrl` fails to respond  Must use `https` if specifying `fallbackUsername` and `fallbackPassword`. (nullable, format: uri, e.g. https://www.myFallbackServer.example/webhooks/answer)
  --answerFallbackMethod: string@answerFallbackMethod-completer # The HTTP method to use to deliver the callback. GET or POST. Default value is POST. (nullable, default: POST, e.g. POST)
  --fallbackUsername: string # Basic auth username. (nullable, e.g. mySecretUsername)
  --fallbackPassword: string # Basic auth password. (nullable, e.g. mySecretPassword1!)
  --disconnectUrl: string # The URL to send the <a href='/docs/voice/webhooks/disconnect'>Disconnect</a> event to when the call ends. This event does not expect a BXML response. (nullable, format: uri, e.g. https://www.myCallbackServer.example/webhooks/disconnect)
  --disconnectMethod: string@disconnectMethod-completer # The HTTP method to use to deliver the callback. GET or POST. Default value is POST. (nullable, default: POST, e.g. POST)
  --callTimeout: float # The timeout (in seconds) for the callee to answer the call after it starts ringing. If the call does not start ringing within 30s, the call will be cancelled regardless of this value.  Can be any numeric value (including decimals) between 1 and 300. (nullable, format: double, default: 30, e.g. 30)
  --callbackTimeout: float # This is the timeout (in seconds) to use when delivering webhooks for the call. Can be any numeric value (including decimals) between 1 and 25. (nullable, format: double, default: 15, e.g. 15)
  --machineDetection: record # The machine detection request used to perform <a href='/docs/voice/guides/machineDetection'>machine detection</a> on the call. Currently, there is an issue where decimal values are not getting processed correctly. Please use whole number values. We are working to resolve this issue. Please contact Bandwidth Support if you need more information. — shape: {mode?: "sync"|"async", detectionTimeout?: float, silenceTimeout?: float, speechThreshold?: float, speechEndThreshold?: float, machineSpeechEndThreshold?: float, delayResult?: bool, callbackUrl?: string, callbackMethod?: "GET"|"POST", username?: string, password?: string, fallbackUrl?: string, fallbackMethod?: "GET"|"POST", fallbackUsername?: string, fallbackPassword?: string}
  --priority: int # The priority of this call over other calls from your account. For example, if during a call your application needs to place a new call and bridge it with the current call, you might want to create the call with priority 1 so that it will be the next call picked off your queue, ahead of other less time sensitive calls. A lower value means higher priority, so a priority 1 call takes precedence over a priority 2 call. (nullable, default: 5, e.g. 5)
  --tag: string # A custom string that will be sent with all webhooks for this call unless overwritten by a future <a href='/docs/voice/bxml/tag'>`<Tag>`</a> verb or `tag` attribute on another verb, or cleared.  May be cleared by setting `tag=""`  Max length 4096 characters. (nullable, e.g. arbitrary text here)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls")
  let body = {to: $body_to, from: $body_from, privacy: $privacy, displayName: $displayName, uui: $uui, applicationId: $applicationId, answerUrl: $answerUrl, answerMethod: $answerMethod, username: $username, password: $password, answerFallbackUrl: $answerFallbackUrl, answerFallbackMethod: $answerFallbackMethod, fallbackUsername: $fallbackUsername, fallbackPassword: $fallbackPassword, disconnectUrl: $disconnectUrl, disconnectMethod: $disconnectMethod, callTimeout: $callTimeout, callbackTimeout: $callbackTimeout, machineDetection: $machineDetection, priority: $priority, tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Calls
#
# GET /accounts/{accountId}/calls
# operationId: listCalls
export def "accounts-calls listCalls" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-to: string # Filter results by the `to` field. (e.g. %2b19195551234)
  --qp-from: string # Filter results by the `from` field. (e.g. %2b19195554321)
  --minStartTime: string # Filter results to calls which have a `startTime` after or including `minStartTime` (in ISO8601 format). (e.g. 2022-06-21T19:13:21Z)
  --maxStartTime: string # Filter results to calls which have a `startTime` before or including `maxStartTime` (in ISO8601 format). (e.g. 2022-06-21T19:13:21Z)
  --disconnectCause: string # Filter results to calls with specified call Disconnect Cause. (e.g. hangup)
  --pageSize: int # Specifies the max number of calls that will be returned. (format: int32, default: 1000, e.g. 500)
  --pageToken: string # Not intended for explicit use. To use pagination, follow the links in the `Link` header of the response, as indicated in the endpoint description. (e.g. eyJwYWdlVG9rZW4iOiJ0b2tlbiJ9)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let qp = [(serialize-qp "to" $qp_to "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "minStartTime" $minStartTime "scalar") (serialize-qp "maxStartTime" $maxStartTime "scalar") (serialize-qp "disconnectCause" $disconnectCause "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/calls" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Call State Information
#
# GET /accounts/{accountId}/calls/{callId}
# operationId: getCallState
export def "accounts-calls get" [
  accountId: string
  callId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Call
#
# POST /accounts/{accountId}/calls/{callId}
# operationId: updateCall
export def "accounts-calls updateCall" [
  accountId: string
  callId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --state: string@state-completer # The call state. Possible values:<br>`active` to redirect the call (default)<br>`completed` to hang up the call if it is answered, cancel it if it is an unanswered outbound call, or reject it if it an unanswered inbound call (nullable, default: active, e.g. completed)
  --redirectUrl: string # The URL to send the [Redirect](/docs/voice/bxml/redirect) event to which will provide new BXML.  Required if `state` is `active`.  Not allowed if `state` is `completed`. (nullable, format: uri, e.g. https://myServer.example/bandwidth/webhooks/redirect)
  --redirectMethod: string@redirectMethod-completer # The HTTP method to use for the request to `redirectUrl`. GET or POST. Default value is POST.<br><br>Not allowed if `state` is `completed`. (nullable, default: POST, e.g. POST)
  --username: string # Basic auth username. (nullable, e.g. mySecretUsername)
  --password: string # Basic auth password. (nullable, e.g. mySecretPassword1!)
  --redirectFallbackUrl: string # A fallback url which, if provided, will be used to retry the redirect callback delivery in case `redirectUrl` fails to respond. (nullable, format: uri, e.g. https://myFallbackServer.example/bandwidth/webhooks/redirect)
  --redirectFallbackMethod: string@redirectFallbackMethod-completer # The HTTP method to use for the request to `redirectUrl`. GET or POST. Default value is POST.<br><br>Not allowed if `state` is `completed`. (nullable, default: POST, e.g. POST)
  --fallbackUsername: string # Basic auth username. (nullable, e.g. mySecretUsername)
  --fallbackPassword: string # Basic auth password. (nullable, e.g. mySecretPassword1!)
  --tag: string # A custom string that will be sent with this and all future callbacks unless overwritten by a future `tag` attribute or [`<Tag>`](/docs/voice/bxml/tag) verb, or cleared.  May be cleared by setting `tag=""`.  Max length 4096 characters.  Not allowed if `state` is `completed`. (nullable, e.g. My Custom Tag)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)")
  let body = {state: $state, redirectUrl: $redirectUrl, redirectMethod: $redirectMethod, username: $username, password: $password, redirectFallbackUrl: $redirectFallbackUrl, redirectFallbackMethod: $redirectFallbackMethod, fallbackUsername: $fallbackUsername, fallbackPassword: $fallbackPassword, tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Call BXML
#
# PUT /accounts/{accountId}/calls/{callId}/bxml
# operationId: updateCallBxml
export def "accounts-calls-bxml updateCallBxml" [
  accountId: string
  callId: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/bxml")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/xml" $body
}

# Get Conferences
#
# GET /accounts/{accountId}/conferences
# operationId: listConferences
export def "accounts-conferences listConferences" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Filter results by the `name` field. (e.g. my-custom-name)
  --minCreatedTime: string # Filter results to conferences which have a `createdTime` after or at `minCreatedTime` (in ISO8601 format). (e.g. 2022-06-21T19:13:21Z)
  --maxCreatedTime: string # Filter results to conferences which have a `createdTime` before or at `maxCreatedTime` (in ISO8601 format). (e.g. 2022-06-21T19:13:21Z)
  --pageSize: int # Specifies the max number of conferences that will be returned. (format: int32, default: 1000, e.g. 500)
  --pageToken: string # Not intended for explicit use. To use pagination, follow the links in the `Link` header of the response, as indicated in the endpoint description. (e.g. eyJwYWdlVG9rZW4iOiJ0b2tlbiJ9)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "minCreatedTime" $minCreatedTime "scalar") (serialize-qp "maxCreatedTime" $maxCreatedTime "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/conferences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Conference Information
#
# GET /accounts/{accountId}/conferences/{conferenceId}
# operationId: getConference
export def "accounts-conferences get" [
  accountId: string
  conferenceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/conferences/($conferenceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Conference
#
# POST /accounts/{accountId}/conferences/{conferenceId}
# operationId: updateConference
export def "accounts-conferences updateConference" [
  accountId: string
  conferenceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer # Setting the conference state to `completed` ends the conference and ejects all members. (nullable, default: active, e.g. completed)
  --redirectUrl: string # The URL to send the [conferenceRedirect](/docs/voice/webhooks/conferenceRedirect) event which will provide new BXML. Not allowed if `state` is `completed`, but required if `state` is `active`. (nullable, format: uri, e.g. https://myServer.example/bandwidth/webhooks/conferenceRedirect)
  --redirectMethod: string@redirectMethod-completer # The HTTP method to use for the request to `redirectUrl`. GET or POST. Default value is POST.<br><br>Not allowed if `state` is `completed`. (nullable, default: POST, e.g. POST)
  --username: string # Basic auth username. (nullable, e.g. mySecretUsername)
  --password: string # Basic auth password. (nullable, e.g. mySecretPassword1!)
  --redirectFallbackUrl: string # A fallback url which, if provided, will be used to retry the `conferenceRedirect` webhook delivery in case `redirectUrl` fails to respond.  Not allowed if `state` is `completed`. (nullable, format: uri, e.g. https://myFallbackServer.example/bandwidth/webhooks/conferenceRedirect)
  --redirectFallbackMethod: string@redirectFallbackMethod-completer # The HTTP method to use for the request to `redirectUrl`. GET or POST. Default value is POST.<br><br>Not allowed if `state` is `completed`. (nullable, default: POST, e.g. POST)
  --fallbackUsername: string # Basic auth username. (nullable, e.g. mySecretUsername)
  --fallbackPassword: string # Basic auth password. (nullable, e.g. mySecretPassword1!)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/conferences/($conferenceId)")
  let body = {status: $status, redirectUrl: $redirectUrl, redirectMethod: $redirectMethod, username: $username, password: $password, redirectFallbackUrl: $redirectFallbackUrl, redirectFallbackMethod: $redirectFallbackMethod, fallbackUsername: $fallbackUsername, fallbackPassword: $fallbackPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Conference BXML
#
# PUT /accounts/{accountId}/conferences/{conferenceId}/bxml
# operationId: updateConferenceBxml
export def "accounts-conferences-bxml updateConferenceBxml" [
  accountId: string
  conferenceId: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/conferences/($conferenceId)/bxml")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/xml" $body
}

# Get Conference Member
#
# GET /accounts/{accountId}/conferences/{conferenceId}/members/{memberId}
# operationId: getConferenceMember
export def "accounts-conferences-members get" [
  accountId: string
  conferenceId: string
  memberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/conferences/($conferenceId)/members/($memberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Conference Member
#
# PUT /accounts/{accountId}/conferences/{conferenceId}/members/{memberId}
# operationId: updateConferenceMember
export def "accounts-conferences-members updateConferenceMember" [
  accountId: string
  conferenceId: string
  memberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --mute: string@bool-completer # Whether or not this member is currently muted. Members who are muted are still able to hear other participants.  Updates this member's mute status. Has no effect if omitted. (e.g. false)
  --hold: string@bool-completer # Whether or not this member is currently on hold. Members who are on hold are not able to hear or speak in the conference.  Updates this member's hold status. Has no effect if omitted. (e.g. false)
  --callIdsToCoach: list # If this member had a value set for `callIdsToCoach` in its [Conference](/docs/voice/bxml/conference) verb or this list was added with a previous PUT request to modify the member, this is that list of calls.  Modifies the calls that this member is coaching. Has no effect if omitted. See the documentation for the [Conference](/docs/voice/bxml/conference) verb for more details about coaching.  Note that this will not add the matching calls to the conference; each call must individually execute a Conference verb to join. (nullable, e.g. [c-25ac29a2-1331029c-2cb0-4a07-b215-b22865662d85])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/conferences/($conferenceId)/members/($memberId)")
  let body = {mute: $mute, hold: $hold, callIdsToCoach: $callIdsToCoach} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Conference Recordings
#
# GET /accounts/{accountId}/conferences/{conferenceId}/recordings
# operationId: listConferenceRecordings
export def "accounts-conferences-recordings listConferenceRecordings" [
  accountId: string
  conferenceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/conferences/($conferenceId)/recordings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Conference Recording Information
#
# GET /accounts/{accountId}/conferences/{conferenceId}/recordings/{recordingId}
# operationId: getConferenceRecording
export def "accounts-conferences-recordings get" [
  accountId: string
  conferenceId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/conferences/($conferenceId)/recordings/($recordingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Conference Recording
#
# GET /accounts/{accountId}/conferences/{conferenceId}/recordings/{recordingId}/media
# operationId: downloadConferenceRecording
export def "accounts-conferences-recordings-media downloadConferenceRecording" [
  accountId: string
  conferenceId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/conferences/($conferenceId)/recordings/($recordingId)/media")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Call Recordings
#
# GET /accounts/{accountId}/recordings
# operationId: listAccountCallRecordings
export def "accounts-recordings listAccountCallRecordings" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-to: string # Filter results by the `to` field. (e.g. %2b19195551234)
  --qp-from: string # Filter results by the `from` field. (e.g. %2b19195554321)
  --minStartTime: string # Filter results to recordings which have a `startTime` after or including `minStartTime` (in ISO8601 format). (e.g. 2022-06-21T19:13:21Z)
  --maxStartTime: string # Filter results to recordings which have a `startTime` before `maxStartTime` (in ISO8601 format). (e.g. 2022-06-21T19:13:21Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let qp = [(serialize-qp "to" $qp_to "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "minStartTime" $minStartTime "scalar") (serialize-qp "maxStartTime" $maxStartTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Recording
#
# PUT /accounts/{accountId}/calls/{callId}/recording
# operationId: updateCallRecordingState
export def "accounts-calls-recording updateCallRecordingState" [
  accountId: string
  callId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  state: string@state-completer-1 # The recording state. Possible values:  `paused` to pause an active recording  `recording` to resume a paused recording (e.g. paused)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recording")
  let body = {state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Call Recordings
#
# GET /accounts/{accountId}/calls/{callId}/recordings
# operationId: listCallRecordings
export def "accounts-calls-recordings listCallRecordings" [
  accountId: string
  callId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recordings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Call Recording
#
# GET /accounts/{accountId}/calls/{callId}/recordings/{recordingId}
# operationId: getCallRecording
export def "accounts-calls-recordings get" [
  accountId: string
  callId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recordings/($recordingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Recording
#
# DELETE /accounts/{accountId}/calls/{callId}/recordings/{recordingId}
# operationId: deleteRecording
export def "accounts-calls-recordings delete" [
  accountId: string
  callId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recordings/($recordingId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Download Recording
#
# GET /accounts/{accountId}/calls/{callId}/recordings/{recordingId}/media
# operationId: downloadCallRecording
export def "accounts-calls-recordings-media downloadCallRecording" [
  accountId: string
  callId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recordings/($recordingId)/media")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Recording Media
#
# DELETE /accounts/{accountId}/calls/{callId}/recordings/{recordingId}/media
# operationId: deleteRecordingMedia
export def "accounts-calls-recordings-media delete" [
  accountId: string
  callId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recordings/($recordingId)/media")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Transcription
#
# GET /accounts/{accountId}/calls/{callId}/recordings/{recordingId}/transcription
# operationId: getRecordingTranscription
export def "accounts-calls-recordings-transcription get" [
  accountId: string
  callId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recordings/($recordingId)/transcription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Transcription Request
#
# POST /accounts/{accountId}/calls/{callId}/recordings/{recordingId}/transcription
# operationId: transcribeCallRecording
export def "accounts-calls-recordings-transcription transcribeCallRecording" [
  accountId: string
  callId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callbackUrl: string # The URL to send the [TranscriptionAvailable](/docs/voice/webhooks/transcriptionAvailable) event to. You should not include sensitive or personally-identifiable information in the callbackUrl field! Always use the proper username and password fields for authorization. (format: uri, e.g. https://myServer.example/bandwidth/webhooks/transcriptionAvailable)
  --callbackMethod: string@callbackMethod-completer # The HTTP method to use to deliver the callback. GET or POST. Default value is POST. (nullable, default: POST, e.g. POST)
  --username: string # Basic auth username. (nullable, e.g. mySecretUsername)
  --password: string # Basic auth password. (nullable, e.g. mySecretPassword1!)
  --tag: string # (optional) The tag specified on call creation. If no tag was specified or it was previously cleared, this field will not be present. (nullable, e.g. exampleTag)
  --callbackTimeout: float # This is the timeout (in seconds) to use when delivering the webhook to `callbackUrl`. Can be any numeric value (including decimals) between 1 and 25. (nullable, format: double, default: 15, e.g. 5.5)
  --detectLanguage: string@bool-completer # A boolean value to indicate that the recording may not be in English, and the transcription service will need to detect the dominant language the recording is in and transcribe accordingly. Current supported languages are English, French, and Spanish. (nullable, default: false, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recordings/($recordingId)/transcription")
  let body = {callbackUrl: $callbackUrl, callbackMethod: $callbackMethod, username: $username, password: $password, tag: $tag, callbackTimeout: $callbackTimeout, detectLanguage: $detectLanguage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Transcription
#
# DELETE /accounts/{accountId}/calls/{callId}/recordings/{recordingId}/transcription
# operationId: deleteRecordingTranscription
export def "accounts-calls-recordings-transcription delete" [
  accountId: string
  callId: string
  recordingId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/recordings/($recordingId)/transcription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Account Statistics
#
# GET /accounts/{accountId}/statistics
# operationId: getStatistics
export def "accounts-statistics get" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/statistics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Real-time Transcriptions
#
# GET /accounts/{accountId}/calls/{callId}/transcriptions
# operationId: listRealTimeTranscriptions
export def "accounts-calls-transcriptions listRealTimeTranscriptions" [
  accountId: string
  callId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/transcriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Real-time Transcription
#
# GET /accounts/{accountId}/calls/{callId}/transcriptions/{transcriptionId}
# operationId: getRealTimeTranscription
export def "accounts-calls-transcriptions get" [
  accountId: string
  callId: string
  transcriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/transcriptions/($transcriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Real-time Transcription
#
# DELETE /accounts/{accountId}/calls/{callId}/transcriptions/{transcriptionId}
# operationId: deleteRealTimeTranscription
export def "accounts-calls-transcriptions delete" [
  accountId: string
  callId: string
  transcriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/calls/($callId)/transcriptions/($transcriptionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Voice Authentication Code
#
# POST /accounts/{accountId}/code/voice
# operationId: generateVoiceCode
export def "accounts-code-voice generateVoiceCode" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # The phone number to send the mfa code to. (e.g. +19195551234)
  --body-from: string # The application phone number, the sender of the mfa code. (e.g. +19195554321)
  applicationId: string # The application unique ID, obtained from Bandwidth. (e.g. 66fd98ae-ac8d-a00f-7fcd-ba3280aeb9b1)
  --scope: string # An optional field to denote what scope or action the mfa code is addressing.  If not supplied, defaults to "2FA". (e.g. 2FA)
  message: string # The message format of the mfa code.  There are three values that the system will replace "{CODE}", "{NAME}", "{SCOPE}".  The "{SCOPE}" and "{NAME} value template are optional, while "{CODE}" must be supplied.  As the name would suggest, code will be replace with the actual mfa code.  Name is replaced with the application name, configured during provisioning of mfa.  The scope value is the same value sent during the call and partitioned by the server. (e.g. Your temporary {NAME} {SCOPE} code is {CODE})
  digits: int # The number of digits for your mfa code.  The valid number ranges from 2 to 8, inclusively. (e.g. 6)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://mfa.bandwidth.com/api/v1")
  let full_url = (build-url $base $"/accounts/($accountId)/code/voice")
  let body = {to: $body_to, from: $body_from, applicationId: $applicationId, scope: $scope, message: $message, digits: $digits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Messaging Authentication Code
#
# POST /accounts/{accountId}/code/messaging
# operationId: generateMessagingCode
export def "accounts-code-messaging generateMessagingCode" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # The phone number to send the mfa code to. (e.g. +19195551234)
  --body-from: string # The application phone number, the sender of the mfa code. (e.g. +19195554321)
  applicationId: string # The application unique ID, obtained from Bandwidth. (e.g. 66fd98ae-ac8d-a00f-7fcd-ba3280aeb9b1)
  --scope: string # An optional field to denote what scope or action the mfa code is addressing.  If not supplied, defaults to "2FA". (e.g. 2FA)
  message: string # The message format of the mfa code.  There are three values that the system will replace "{CODE}", "{NAME}", "{SCOPE}".  The "{SCOPE}" and "{NAME} value template are optional, while "{CODE}" must be supplied.  As the name would suggest, code will be replace with the actual mfa code.  Name is replaced with the application name, configured during provisioning of mfa.  The scope value is the same value sent during the call and partitioned by the server. (e.g. Your temporary {NAME} {SCOPE} code is {CODE})
  digits: int # The number of digits for your mfa code.  The valid number ranges from 2 to 8, inclusively. (e.g. 6)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://mfa.bandwidth.com/api/v1")
  let full_url = (build-url $base $"/accounts/($accountId)/code/messaging")
  let body = {to: $body_to, from: $body_from, applicationId: $applicationId, scope: $scope, message: $message, digits: $digits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Verify Authentication Code
#
# POST /accounts/{accountId}/code/verify
# operationId: verifyCode
export def "accounts-code-verify verifyCode" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-to: string # The phone number to send the mfa code to. (e.g. +19195551234)
  --scope: string # An optional field to denote what scope or action the mfa code is addressing.  If not supplied, defaults to "2FA". (e.g. 2FA)
  expirationTimeInMinutes: float # The time period, in minutes, to validate the mfa code.  By setting this to 3 minutes, it will mean any code generated within the last 3 minutes are still valid.  The valid range for expiration time is between 0 and 15 minutes, exclusively and inclusively, respectively. (e.g. 3)
  code: string # The generated mfa code to check if valid. (e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://mfa.bandwidth.com/api/v1")
  let full_url = (build-url $base $"/accounts/($accountId)/code/verify")
  let body = {to: $body_to, scope: $scope, expirationTimeInMinutes: $expirationTimeInMinutes, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Synchronous Number Lookup
#
# POST /accounts/{accountId}/phoneNumberLookup
# operationId: createSyncLookup
export def "accounts-phone-number-lookup createSyncLookup" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phoneNumbers: list # Telephone numbers in E.164 format.
  --rcsAgent: string # Override the default RCS sender/agent ID used when checking RCS capabilities. When provided, this value is used as the `sender` in the RCS capability-check request instead of the account default. Must be 1–40 characters and contain only letters, digits, underscores, or hyphens. (e.g. MyCustomRcsAgent)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/phoneNumberLookup")
  let body = {phoneNumbers: $phoneNumbers, rcsAgent: $rcsAgent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Asynchronous Bulk Number Lookup
#
# POST /accounts/{accountId}/phoneNumberLookup/bulk
# operationId: createAsyncBulkLookup
export def "accounts-phone-number-lookup-bulk createAsyncBulkLookup" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phoneNumbers: list # Telephone numbers in E.164 format.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/phoneNumberLookup/bulk")
  let body = {phoneNumbers: $phoneNumbers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Asynchronous Bulk Number Lookup
#
# GET /accounts/{accountId}/phoneNumberLookup/bulk/{requestId}
# operationId: getAsyncBulkLookup
export def "accounts-phone-number-lookup-bulk get" [
  accountId: string
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/phoneNumberLookup/bulk/($requestId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Request Toll-Free Verification
#
# POST /accounts/{accountId}/tollFreeVerification
# operationId: requestTollFreeVerification
# --businessAddress shape: {name: string, addr1: string, addr2?: string, city: string, state: string, zip: string, url: string}
# --businessContact shape: {firstName: string, lastName: string, email: string, phoneNumber: string}
# --optInWorkflow shape: {description: string, imageUrls: list, confirmationResponse?: string}
export def "accounts-toll-free-verification requestTollFreeVerification" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  businessAddress: record # shape: {name: string, addr1: string, addr2?: string, city: string, state: string, zip: string, url: string}
  businessContact: record # shape: {firstName: string, lastName: string, email: string, phoneNumber: string}
  messageVolume: int # Estimated monthly volume of messages from the toll-free number. (e.g. 10000)
  phoneNumbers: list
  useCase: string # The category of the use case. (e.g. 2FA)
  useCaseSummary: string # A general idea of the use case and customer. (e.g. Text summarizing the use case for the toll-free number)
  productionMessageContent: string # Example of message content. (e.g. Production message content)
  optInWorkflow: record # shape: {description: string, imageUrls: list, confirmationResponse?: string}
  --additionalInformation: string # Any additional information. (nullable, e.g. Any additional information)
  --isvReseller: string # ISV name. (nullable, e.g. Test ISV)
  --privacyPolicyUrl: string # The Toll-Free Verification request privacy policy URL. (e.g. http://your-company.com/privacyPolicy)
  --termsAndConditionsUrl: string # The Toll-Free Verification request terms and conditions policy URL. (e.g. http://your-company.com/termsAndConditions)
  --businessDba: string # The company 'Doing Business As'. (e.g. Another Company Name Inc.)
  --businessRegistrationNumber: string # Government-issued business identifying number.  **Note: As of October 19th, 2026 this field will be required when `businessEntityType` is _not_ `SOLE_PROPRIETOR`. If this field is provided, `businessRegistrationType` and `businessRegistrationIssuingCountry` are also required.**  (nullable, e.g. 12-3456789)
  --businessRegistrationType: string@businessRegistrationType-completer # The type of business registration number.  **Note: As of October 19th, 2026 this field will be required when `businessRegistrationNumber` is provided.**  (nullable, e.g. EIN)
  --businessRegistrationIssuingCountry: string # The country issuing the business registration in ISO-3166-1 alpha-3 format. Alpha-2 format is accepted by the API, but alpha-3 is highly encouraged.  **Note: As of October 19th, 2026 this field will be required when `businessRegistrationNumber` is provided.**  | Registration Type     | Supported Countries                | |----------------------|------------------------------------| | EIN                  | USA                                | | CBN                  | CAN                                | | NEQ                  | CAN                                | | PROVINCIAL_NUMBER    | CAN                                | | CRN                  | GBR, HKG                           | | VAT                  | GBR, IRL, BRA, NLD                 | | ACN                  | AUS                                | | ABN                  | AUS                                | | BRN                  | HKG                                | | SIREN                | FRA                                | | SIRET                | FRA                                | | NZBN                 | NZL                                | | UST_IDNR             | DEU                                | | CIF                  | ESP                                | | NIF                  | ESP                                | | CNPJ                 | BRA                                | | UID                  | CHE                                | | OTHER                | Must Provide Country Code          | (nullable, e.g. USA)
  businessEntityType: string@businessEntityType-completer # The type of registered business.  **Note: As of October 19th, 2026 submissions using a value other than `SOLE_PROPRIETOR` must provide a value for `businessRegistrationNumber`, `businessRegistrationType`, and `businessRegistrationIssuingCountry`.  Submissions using `SOLE_PROPRIETOR` must _omit_ `businessRegistrationNumber`, `businessRegistrationType`, and `businessRegistrationIssuingCountry`. Failure to adhere to these constraints will result in a 400 Bad Request rejection.**  (e.g. PRIVATE_PROFIT)
  --helpMessageResponse: string # A message that gets sent to users requesting help. (nullable, e.g. Please contact support for assistance.)
  --ageGatedContent: string@bool-completer # Indicates whether the content is age-gated. (e.g. false)
  --cvToken: string # The token provided by Campaign Verify to validate your political use case. Only required for 527 political organizations. If you are not a 527 political organization, this field should be omitted. Supplying an empty string will likely result in rejection. (nullable, e.g. cv.user123|sess456|mno|tfree|read_write|X7yZ9aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVwXyZ0123456789aBcDeFgHiJkLmNoPqRsTuVw)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/tollFreeVerification")
  let body = {businessAddress: $businessAddress, businessContact: $businessContact, messageVolume: $messageVolume, phoneNumbers: $phoneNumbers, useCase: $useCase, useCaseSummary: $useCaseSummary, productionMessageContent: $productionMessageContent, optInWorkflow: $optInWorkflow, additionalInformation: $additionalInformation, isvReseller: $isvReseller, privacyPolicyUrl: $privacyPolicyUrl, termsAndConditionsUrl: $termsAndConditionsUrl, businessDba: $businessDba, businessRegistrationNumber: $businessRegistrationNumber, businessRegistrationType: $businessRegistrationType, businessRegistrationIssuingCountry: $businessRegistrationIssuingCountry, businessEntityType: $businessEntityType, helpMessageResponse: $helpMessageResponse, ageGatedContent: $ageGatedContent, cvToken: $cvToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Toll-Free Verification Status
#
# GET /accounts/{accountId}/phoneNumbers/{phoneNumber}/tollFreeVerification
# operationId: getTollFreeVerificationStatus
export def "accounts-phone-numbers-toll-free-verification get" [
  accountId: string
  phoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/phoneNumbers/($phoneNumber)/tollFreeVerification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Toll-Free Verification Request
#
# PUT /accounts/{accountId}/phoneNumbers/{phoneNumber}/tollFreeVerification
# operationId: updateTollFreeVerificationRequest
# --submission shape: {businessAddress: record, businessContact: record, messageVolume: int, useCase: string, useCaseSummary: string, productionMessageContent: string, optInWorkflow: record, additionalInformation?: string, isvReseller?: string, privacyPolicyUrl?: string, termsAndConditionsUrl?: string, businessDba?: string, businessRegistrationNumber?: string, businessRegistrationType?: "EIN"|"CBN"|"NEQ"|"PROVINCIAL_NUMBER"|"CRN"|"VAT"|"ACN"|"ABN"|"BRN"|"SIREN"|"SIRET"|"NZBN"|"UST_IDNR"|"CIF"|"NIF"|"CNPJ"|"UID"|"OTHER", businessEntityType?: "SOLE_PROPRIETOR"|"PRIVATE_PROFIT"|"PUBLIC_PROFIT"|"NON_PROFIT"|"GOVERNMENT", businessRegistrationIssuingCountry?: string, helpMessageResponse?: string, ageGatedContent?: bool, cvToken?: string}
export def "accounts-phone-numbers-toll-free-verification updateTollFreeVerificationRequest" [
  accountId: string
  phoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --submission: record # shape: {businessAddress: record, businessContact: record, messageVolume: int, useCase: string, useCaseSummary: string, productionMessageContent: string, optInWorkflow: record, additionalInformation?: string, isvReseller?: string, privacyPolicyUrl?: string, termsAndConditionsUrl?: string, businessDba?: string, businessRegistrationNumber?: string, businessRegistrationType?: "EIN"|"CBN"|"NEQ"|"PROVINCIAL_NUMBER"|"CRN"|"VAT"|"ACN"|"ABN"|"BRN"|"SIREN"|"SIRET"|"NZBN"|"UST_IDNR"|"CIF"|"NIF"|"CNPJ"|"UID"|"OTHER", businessEntityType?: "SOLE_PROPRIETOR"|"PRIVATE_PROFIT"|"PUBLIC_PROFIT"|"NON_PROFIT"|"GOVERNMENT", businessRegistrationIssuingCountry?: string, helpMessageResponse?: string, ageGatedContent?: bool, cvToken?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/phoneNumbers/($phoneNumber)/tollFreeVerification")
  let body = {submission: $submission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a Toll-Free Verification Submission
#
# DELETE /accounts/{accountId}/phoneNumbers/{phoneNumber}/tollFreeVerification
# operationId: deleteVerificationRequest
export def "accounts-phone-numbers-toll-free-verification delete" [
  accountId: string
  phoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/phoneNumbers/($phoneNumber)/tollFreeVerification")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Webhook Subscriptions
#
# GET /accounts/{accountId}/tollFreeVerification/webhooks/subscriptions
# operationId: listWebhookSubscriptions
export def "accounts-toll-free-verification-webhooks-subscriptions listWebhookSubscriptions" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/tollFreeVerification/webhooks/subscriptions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Webhook Subscription
#
# POST /accounts/{accountId}/tollFreeVerification/webhooks/subscriptions
# operationId: createWebhookSubscription
# --basicAuthentication shape: {username: string, password: string}
export def "accounts-toll-free-verification-webhooks-subscriptions createWebhookSubscription" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --basicAuthentication: record # shape: {username: string, password: string}
  --callbackUrl: string # Callback URL to receive status updates from Bandwidth. When a webhook subscription is registered with Bandwidth under a given account ID, it will be used to send status updates for all requests submitted under that account ID. (nullable, format: url, e.g. https://www.example.com/path/to/resource)
  --sharedSecretKey: string # An ASCII string submitted by the user as a shared secret key for generating an HMAC header for callbacks. (nullable, e.g. This is my $3cret)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/tollFreeVerification/webhooks/subscriptions")
  let body = {basicAuthentication: $basicAuthentication, callbackUrl: $callbackUrl, sharedSecretKey: $sharedSecretKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Webhook Subscription
#
# DELETE /accounts/{accountId}/tollFreeVerification/webhooks/subscriptions/{id}
# operationId: deleteWebhookSubscription
export def "accounts-toll-free-verification-webhooks-subscriptions delete" [
  accountId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/tollFreeVerification/webhooks/subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Webhook Subscription
#
# PUT /accounts/{accountId}/tollFreeVerification/webhooks/subscriptions/{id}
# operationId: updateWebhookSubscription
# --basicAuthentication shape: {username: string, password: string}
export def "accounts-toll-free-verification-webhooks-subscriptions updateWebhookSubscription" [
  accountId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --basicAuthentication: record # shape: {username: string, password: string}
  --callbackUrl: string # Callback URL to receive status updates from Bandwidth. When a webhook subscription is registered with Bandwidth under a given account ID, it will be used to send status updates for all requests submitted under that account ID. (nullable, format: url, e.g. https://www.example.com/path/to/resource)
  --sharedSecretKey: string # An ASCII string submitted by the user as a shared secret key for generating an HMAC header for callbacks. (nullable, e.g. This is my $3cret)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/tollFreeVerification/webhooks/subscriptions/($id)")
  let body = {basicAuthentication: $basicAuthentication, callbackUrl: $callbackUrl, sharedSecretKey: $sharedSecretKey} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Toll-Free Use Cases
#
# GET /tollFreeVerification/useCases
# operationId: listTollFreeUseCases
export def "toll-free-verification-use-cases listTollFreeUseCases" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/api/v2")
  let full_url = (build-url $base "/tollFreeVerification/useCases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Endpoints
#
# GET /accounts/{accountId}/endpoints
# operationId: listEndpoints
export def "accounts-endpoints listEndpoints" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer # The type of endpoint.
  --status: string@status-completer-1 # The status of the endpoint.
  --afterCursor: string # The cursor to use for pagination. This is the value of the `next` link in the previous response. (e.g. TWF5IHRoZSBmb3JjZSBiZSB3aXRoIHlvdQ==)
  --limit: int # The maximum number of endpoints to return in the response. (default: 100, e.g. 2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/v2")
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "afterCursor" $afterCursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/accounts/($accountId)/endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Endpoint
#
# POST /accounts/{accountId}/endpoints
# Discriminator (request): type = WEBRTC
# operationId: createEndpoint
export def "accounts-endpoints createEndpoint" [
  accountId: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/endpoints")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Endpoint
#
# GET /accounts/{accountId}/endpoints/{endpointId}
# operationId: getEndpoint
export def "accounts-endpoints get" [
  accountId: string
  endpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/endpoints/($endpointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete Endpoint
#
# DELETE /accounts/{accountId}/endpoints/{endpointId}
# operationId: deleteEndpoint
export def "accounts-endpoints delete" [
  accountId: string
  endpointId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/endpoints/($endpointId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Endpoint BXML
#
# PUT /accounts/{accountId}/endpoints/{endpointId}/bxml
# operationId: updateEndpointBxml
export def "accounts-endpoints-bxml updateEndpointBxml" [
  accountId: string
  endpointId: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://api.bandwidth.com/v2")
  let full_url = (build-url $base $"/accounts/($accountId)/endpoints/($endpointId)/bxml")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/xml" $body
}
