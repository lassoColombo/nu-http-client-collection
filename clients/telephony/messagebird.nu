# Auto-generated client for MessageBird SMS API v1.0.0
# Source: https://raw.githubusercontent.com/messagebird/openapi-specs/master/sms/openapi.yaml
# Auth: --token flag or $env.MESSAGEBIRD_SMS_API_TOKEN

const BASE_URL = "https://rest.messagebird.com/messages"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MESSAGEBIRD_SMS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://rest.messagebird.com/messages"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["binary" "flash" "sms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "messages post" } } | get name | first)
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

# Send message
#
# POST /messages
export def "messages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Content-Type: string # e.g. application/json
  --Authorization: string # e.g. AccessKey wNmtVQTcLO4uf22uJxjvzwJ223
  originator: string # The sender of the message. This can be a telephone number (including country code) or an alphanumeric string. In case of an alphanumeric string, the maximum length is 11 characters. (e.g. MessageBird)
  --body-body: string # The body of the SMS message. (e.g. +380999999999)
  recipients: list # An array of recipients msisdns. (e.g. ["380999999999", "380999999999"])
  --groupIds: list # An array of group id's. If provided recipients can be omitted.
  --type: string@type-completer # The type of message. Values can be: sms, binary, or flash.
  --reference: string # A client reference. Is required for a status report callback to be sent.
  --reportUrl: string # The status report URL to be used on a per-message basis. This value overrides the standard status report url configured on the customer account. (e.g. https://example.ua/report-here)
  --validity: int # The amount of seconds that the message is valid. If a message is not delivered within this time, the message will be discarded. (e.g. 60)
  --gateway: int # The SMS route that is used to send the message. (e.g. 11)
  --typeDetails: record # A hashmap with extra information. (e.g. {"udh":"050003340201"})
  --datacoding: string # The datacoding used, defaults to plain (GSM 03.38 characters only), or it can be set to unicode (contains non-GSM 03.38 characters) or set to auto and we will set unicode or plain depending on the body content. (e.g. unicode)
  --mclass: int # Indicated the message type. 1 is a normal message, 0 is a flash message. (0-3 are valid values). (e.g. 1)
  --shortenUrls: oneof<nothing, bool> # \*beta\* Shorten all the URLs present in the message body. (e.g. false)
  --scheduledDatetime: int # The scheduled date and time of the message in RFC3339 format (Y-m-d\TH:i:sP), when you want to schedule a message in the future. Don't set this value when message needs to be send directly. (e.g. 2022-05-20T12:50:28Z)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages")
  let body = {originator: $originator, body: $body_body, recipients: $recipients, groupIds: $groupIds, type: $type, reference: $reference, reportUrl: $reportUrl, validity: $validity, gateway: $gateway, typeDetails: $typeDetails, datacoding: $datacoding, mclass: $mclass, shortenUrls: $shortenUrls, scheduledDatetime: $scheduledDatetime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Type": $Content_Type, "Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List messages
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
  --originator: string # Display messages by the specified originator. (e.g. ValTesting)
  --recipient: int # Display messages for the specified recipient. (e.g. 380999999999)
  --direction: string # Display either mt (sent) or mo (received) messages. (e.g. mt)
  --limit: int # Limit the amount of messages listed. (e.g. 50)
  --offset: int # Skip first n results. (e.g. 0)
  --searchterm: string # Display messages including the specified searchterm in recipient and originator (e.g. val)
  --type: string # Display messages of type sms, binary, or flash (e.g. sms)
  --contact-id: string # Display messages by contact_id. See Contacts API for more info. (e.g. 61afc0531573b08ddbe36e1c85602827)
  --status: string # Display messages with status scheduled, sent, buffered, delivered, expired, or delivery_failed. (e.g. buffered)
  --qp-from: string # Display messages starting from the specified date in RFC3339 format (Y-m-d\TH:i:sP). (e.g. 2022-05-20T12:50:28Z)
  --until: string # Display messages until the specified date in RFC3339 format (Y-m-d\TH:i:sP). (e.g. 2022-06-29T12:50:28Z)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "originator" $originator "scalar") (serialize-qp "recipient" $recipient "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "searchterm" $searchterm "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "contact_id" $contact_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get message by ID
#
# GET /messages/{messageId}
export def "messages get" [
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($messageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete message by ID
#
# DELETE /messages/{messageId}
export def "messages delete" [
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
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/messages/($messageId)")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
