# Auto-generated client for BulkSMS JSON REST API v1.0.0
# Source: https://api.apis.guru/v2/specs/bulksms.com/1.0.0/openapi.json
# Auth: --token flag or $env.BULKSMS_JSON_REST_API_TOKEN

const BASE_URL = "https://api.bulksms.com/v1"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BULKSMS_JSON_REST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.bulksms.com/v1"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def sort-order-completer [] { ["ASCENDING"] }
def invoke-option-completer [] { ["MANY" "ONE"] }
def trigger-scope-completer [] { ["RECEIVED" "SENT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "blocked-numbers get" } } | get name | first)
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

# List blocked numbers
#
# GET /blocked-numbers
export def "blocked-numbers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --min-id: int # Records with an `id` that is greater or equal to min-id will be returned. The default value is `0`. You can add 1 to an id that you previously retrieved, to return subsequent records. (format: int32)
  --limit: int # The maximum number of records to return. The default value is `10000`. The value cannot be greater than 10000. (format: int32)
]: nothing -> record<id: float, phoneNumber: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "min-id" $min_id "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blocked-numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a blocked number
#
# POST /blocked-numbers
export def "blocked-numbers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocked-numbers")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Transfer credits to another account
#
# POST /credit/transfer
export def "credit-transfer create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --comment-on-from: string # An optional note that will be shown on the credit history of your account. The maximum length of the comment is 100. (e.g. Tranfer to Bobby)
  --comment-on-to: string # An optional note that will be shown on the credit history of the recipient's account. The maximum length of the comment is 100. (e.g. Tranfer from Danny)
  credits: float # The amount of credits to transfer. (e.g. 2345)
  to_user_id: float # The numeric user ID of the account that will receive the credits. The ID must match the username. (e.g. 2345)
  to_username: string # The username of the account that will receive the credits. (e.g. roboto)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credit/transfer")
  let req_body = {"commentOnFrom": $comment_on_from, "commentOnTo": $comment_on_to, "credits": $credits, "toUserId": $to_user_id, "toUsername": $to_username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Retrieve Messages
#
# GET /messages
export def "messages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: float # The maximum number of messages that are returned. The default is 1000. The value of `limit` is not a guarantee that a specific number of messages will be in the response, even if there are more messages available. Consider the case where you have 150 messages and you specify `limit=50`. It is possible that only 49 messages will be returned. The way to make sure that there are no more messages is to submit a new call using the `id` filter field with the `<` operator (described below). (format: int)
  --filter: string # See the message filtering for more information.
  --sort-order: string@sort-order-completer # The default value is DESCENDING If the `sortOrder` is DESCENDING, the newest messages be first in the result. ASCENDING places the oldest messages on top of the response.
]: nothing -> table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sortOrder" $sort_order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send Messages
#
# POST /messages
export def "messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --deduplication-id: int # Safeguards against the possibility of sending the same messages more than once. If a communication failure occurs during a submission, you cannot be sure that the submission was processed; therefore you would have to submit it again. When you post the retry, you must use the `deduplication-id` of the original post. The BulkSMS system uses this ID to check that the request was not previously processed. (If it was previously processed, the submission will succeed, and the behaviour will be indistinguishable to you from a non-duplicated submission). The ID expires after about 12 hours. (format: int32)
  --auto-unicode: oneof<nothing, bool> # Specifies how to deal with message text that contains characters not present in the GSM 03.38 character set. Messages that contain only GSM 03.38 characters are not affected by this setting. If the value is `true` then a message containing non-GSM 03.38 characters will be transmitted as a Unicode SMS (which is most likely more costly). Please note: when `auto-unicode` is `true` and the value of the `encoding` property is specified as `UNICODE`, the message will always be sent as `UNICODE`. If the value is `false` and the `encoding` property is `TEXT` then non-GSM 03.38 characters will be replaced by the `?` character. When using this setting on the API, you should take case to ensure that your message is _clean_. Invisible unicode and unexpected characters could unintentionally convert an message to `UNICODE`. A common mistake is to use the backtick character (\`) which is unicode and will turn your `TEXT` message into a `UNICODE` message. (default: false)
  --schedule-date: string # Allows you to send a message in the future. An example value is `2019-02-18T13:00:00+02:00`. It encodes to `2019-02-18T13%3A00%3A00%2B02%3A00`. Credits are deducted from your account immediately. Once submitted, scheduled messages cannot be changed or cancelled. The date can be a maximum of two years in the future. If the value is in the past, the message will be sent immediately. The date format requires you to supply an offset from UTC. You can decide to use the offset of your timezone, or maybe the zone of the recipient's location is more appropriate. If the destination is a group, the group members are determined at the time that you submit the message; not the time the message is scheduled to be sent. (format: date-time)
  --schedule-description: string # A note that is stored together with a scheduled submission, which could be used to more easily identify the scheduled submission at a later date. The value of this field is ignored if the `schedule-date` is not provided. A value that is longer than 256 characters is truncated.
  --body: record
]: any -> table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "deduplication-id" $deduplication_id "scalar") (serialize-qp "auto-unicode" $auto_unicode "scalar") (serialize-qp "schedule-date" $schedule_date "scalar") (serialize-qp "schedule-description" $schedule_description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Send message by simple GET or POST
#
# GET /messages/send
export def "messages-send get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-to: string # The phone number of the recipient.
  --body: string # The text you want to send.
  --deduplication-id: int # Refer to the `deduplication-id` parameter. (format: int-32)
]: nothing -> table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "to" $qp_to "scalar") (serialize-qp "body" $body "scalar") (serialize-qp "deduplication-id" $deduplication_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages/send" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Show Message
#
# GET /messages/{id}
export def "messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Related Messages
#
# GET /messages/{id}/relatedReceivedMessages
export def "messages-related-received-messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<body: any, creditCost: float, encoding: string, from: string, id: string, messageClass: int, numberOfParts: int, protocolId: int, relatedSentMessageId: string, status: record<id: string, subtype: string, type: string>, submission: record<date: string, id: string>, to: string, type: string, userSuppliedId: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}/relatedReceivedMessages"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get profile
#
# GET /profile
export def "profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commerce: record<address: record<city: string, country: string, postalCode: string, region: string, street: list>, bankPaymentReference: string>, company: record<name: string, taxReference: string>, created: string, credits: record<balance: float, isTransferAllowed: bool, limit: int>, id: string, originAddresses: record<allowed: list<string>, isFullControlAllowed: bool>, quota: record<remaining: int, size: int>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload an attachment via a signed URL
#
# POST /rmm/pre-sign-attachment
export def "rmm-pre-sign-attachment create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --file-extension: string # The extension of the file. Usually related to the media type. (e.g. pdf)
  --media-type: string # The media type of the file you would like to upload. If you are not sure what value to use here, check out the standard [list of media types](https://www.iana.org/assignments/media-types/media-types.xhtml). (e.g. application/pdf)
]: any -> record<fetchUrl: string, fields: table<name: string, value: string>, putUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rmm/pre-sign-attachment")
  let req_body = {"fileExtension": $file_extension, "mediaType": $media_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List webhooks
#
# GET /webhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /webhooks
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Indicates whether you want the webhook activated. If the value is `true`, the webhook at the given `url` will be invoked with an empty array (`[]`) as part of the validation process. If the webhook responds with a `2xx` status code, the submission is accepted; if not the webhook is not created (or updated). If the value is `false` the webhook will be inactive, and it will not be invoked when messages are `SENT` or `RECEIVED`. The default value is `true`. (e.g. true)
  --contact-email-address: string # The email address to which emails will be sent if there are problem with invoking the webhook. The value must be a valid email address. If this value is `null`, no email will be sent. It is `null` by default. (e.g. tech_team@example.com)
  --invoke-option: string@invoke-option-completer # Specifies how to invoke your webhook. If the value is `ONE` the array POSTed to your webhook will contain no more than a single message. Use this option if your webhook logic is unable to handle more than one messages at a time. If the value is `MANY` the array POSTed to your webhook can contain up to 10 messages. This is the recommended option. The number of calls made to your webhook would be less and this will speed up your total processing time. If your webhook fails for an invoke that has more than one message, each message in the array will automatically be retried one at a time. This value defaults to `ONE` - but it is recommended that you set this property to `MANY`. (e.g. MANY)
  name: string # A text identifier for the webhook. More than one webhook cannot have the same name. (e.g. My MT Webhook)
  --on-web-app: oneof<nothing, bool> # Indicates whether you want to show this webhook on the Web App. Webhooks shown there can be updated by the user that use the public Web site. The default value is `true`. (e.g. true)
  trigger_scope: string@trigger-scope-completer # Specifies when the webhook will be triggered. Please note the values are case sensitive. If the value is `SENT`, the webhook will be called when a status update becomes available for a message you sent (i.e. a mobile terminating (MT) message). If the value is `RECEIVED`, the webhook will be called when a message is received (i.e. a mobile originating (MO) message). Note that this field forces you to create two separate webhook entries if you want to collect all messages. However, you can use the same `url` for both webhooks if you want. (e.g. SENT)
  url: string # The location of the webhook. In addition to being a [valid URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier#Syntax), the url must also start with `http` or `https`. (e.g. https://www.example.com)
]: any -> record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let req_body = {"active": $active, "contactEmailAddress": $contact_email_address, "invokeOption": $invoke_option, "name": $name, "onWebApp": $on_web_app, "triggerScope": $trigger_scope, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a webhook
#
# DELETE /webhooks/{id}
export def "webhooks delete" [
  id: string
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/webhooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Read a webhook
#
# GET /webhooks/{id}
export def "webhooks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/webhooks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a webhook
#
# POST /webhooks/{id}
export def "webhooks create-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Indicates whether you want the webhook activated. If the value is `true`, the webhook at the given `url` will be invoked with an empty array (`[]`) as part of the validation process. If the webhook responds with a `2xx` status code, the submission is accepted; if not the webhook is not created (or updated). If the value is `false` the webhook will be inactive, and it will not be invoked when messages are `SENT` or `RECEIVED`. The default value is `true`. (e.g. true)
  --contact-email-address: string # The email address to which emails will be sent if there are problem with invoking the webhook. The value must be a valid email address. If this value is `null`, no email will be sent. It is `null` by default. (e.g. tech_team@example.com)
  --invoke-option: string@invoke-option-completer # Specifies how to invoke your webhook. If the value is `ONE` the array POSTed to your webhook will contain no more than a single message. Use this option if your webhook logic is unable to handle more than one messages at a time. If the value is `MANY` the array POSTed to your webhook can contain up to 10 messages. This is the recommended option. The number of calls made to your webhook would be less and this will speed up your total processing time. If your webhook fails for an invoke that has more than one message, each message in the array will automatically be retried one at a time. This value defaults to `ONE` - but it is recommended that you set this property to `MANY`. (e.g. MANY)
  name: string # A text identifier for the webhook. More than one webhook cannot have the same name. (e.g. My MT Webhook)
  --on-web-app: oneof<nothing, bool> # Indicates whether you want to show this webhook on the Web App. Webhooks shown there can be updated by the user that use the public Web site. The default value is `true`. (e.g. true)
  trigger_scope: string@trigger-scope-completer # Specifies when the webhook will be triggered. Please note the values are case sensitive. If the value is `SENT`, the webhook will be called when a status update becomes available for a message you sent (i.e. a mobile terminating (MT) message). If the value is `RECEIVED`, the webhook will be called when a message is received (i.e. a mobile originating (MO) message). Note that this field forces you to create two separate webhook entries if you want to collect all messages. However, you can use the same `url` for both webhooks if you want. (e.g. SENT)
  url: string # The location of the webhook. In addition to being a [valid URI](https://en.wikipedia.org/wiki/Uniform_Resource_Identifier#Syntax), the url must also start with `http` or `https`. (e.g. https://www.example.com)
]: any -> record<active: bool, contactEmailAddress: string, id: float, name: string, onWebApp: bool, triggerScope: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/webhooks/{id}"))
  let req_body = {"active": $active, "contactEmailAddress": $contact_email_address, "invokeOption": $invoke_option, "name": $name, "onWebApp": $on_web_app, "triggerScope": $trigger_scope, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
