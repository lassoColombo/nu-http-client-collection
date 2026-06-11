# Auto-generated client for sms77.io API v1.0.0
# Source: https://api.apis.guru/v2/specs/sms77.io/1.0.0/openapi.json
# Auth: --token flag or $env.SMS77_IO_API_TOKEN

const BASE_URL = "https://gateway.sms77.io/api"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SMS77_IO_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["https://gateway.sms77.io/api"] }
def auth-scheme-completer [] { ["x-api-key"] }

# Completers for enum parameters
def group-by-completer [] { ["country" "date" "label" "subaccount"] }
def action-completer [] { ["read"] }
def json-completer [] { ["0" "1"] }
def accept-completer [] { ["application/json" "text/csv"] }
def action-completer-1 [] { ["del" "write"] }
def accept-completer-1 [] { ["application/json" "text/plain"] }
def action-completer-2 [] { ["subscribe" "unsubscribe"] }
def event-type-completer [] { ["all" "dlr" "sms_mo" "voice_status"] }
def request-method-completer [] { ["GET" "JSON" "POST"] }
def debug-completer [] { ["0" "1"] }
def no-reload-completer [] { ["0" "1"] }
def unicode-completer [] { ["0" "1"] }
def flash-completer [] { ["0" "1"] }
def utf8-completer [] { ["0" "1"] }
def details-completer [] { ["0" "1"] }
def return-msg-id-completer [] { ["0" "1"] }
def performance-tracking-completer [] { ["0" "1"] }
def xml-completer [] { ["0" "1"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "analytics Analytics" } } | get name | first)
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

# GET /analytics
#
# operationId: Analytics
export def "analytics Analytics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: string # Start date of the statistics in the format YYYY-MM-DD. By default, the date of 30 days ago is set.
  --end: string # End date of the statistics in the format YYYY-MM-DD. By default, the current day.
  --label: string # Shows only data of a specific label.
  --subaccounts: string # Receive the data only for the main account, all your (sub-)accounts or only for specific subaccounts.
  --group-by: string@group-by-completer # Defines the grouping of the data.
]: nothing -> record<date: string, direct: int, economy: int, hlr: int, inbound: int, mnp: int, usage_eur: float, voice: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "subaccounts" $subaccounts "scalar") (serialize-qp "group_by" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/analytics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /balance
#
# operationId: Balance
export def "balance Balance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/balance")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /contacts
#
# operationId: ContactsGet
export def "contacts ContactsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --action: string@action-completer # Determines the action to execute.
  --json: float@json-completer # Defines whether to return the response as JSON or CSV separated by semicolon. (default: 0)
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "json" $json "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /contacts
#
# operationId: ContactsPOST
export def "contacts ContactsPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --action: string@action-completer-1 # Determines the action to execute.
  --json: float@json-completer # Defines whether to return the response as JSON or CSV separated by semicolon. (default: 0)
  --id: string # The contact ID for editing/deletion.
  --nick: string # The contacts name.
  --empfaenger: string # The contacts phone number.
  --email: string # The contacts email address.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "json" $json "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "nick" $nick "scalar") (serialize-qp "empfaenger" $empfaenger "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/contacts" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /hooks
#
# operationId: HooksGet
export def "hooks HooksGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer # Determines the action to execute.
]: nothing -> record<hooks: table<created: string, event_type: string, id: string, request_method: string, target_url: string>, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /hooks
#
# operationId: HooksPOST
export def "hooks HooksPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string@action-completer-2 # Determines the action to execute.
  --id: int # The Webhook ID you wish to unsubscribe.
  --target-url: string # Target URL of your Webhook.
  --event-type: string@event-type-completer # Type of event for which you would like to receive a webhook.
  --request-method: string@request-method-completer # Request method in which you want to receive the webhook. (default: POST)
]: nothing -> record<id: int, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "target_url" $target_url "scalar") (serialize-qp "event_type" $event_type "scalar") (serialize-qp "request_method" $request_method "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lookup
#
# operationId: Lookup
export def "lookup Lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # Allowed values are "cnam", "format", "hlr" and "mnp".
  --number: list # The phone number to look up.
  --json: string # Determines whether the response shall be returned in JSON format. Does not work with type "format".
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "number" $number "csv") (serialize-qp "json" $json "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lookup/cnam
#
# operationId: LookupCnam
export def "lookup-cnam LookupCnam" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --number: list # The phone number to look up.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/lookup/cnam" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lookup/format
#
# operationId: LookupFormat
export def "lookup-format LookupFormat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --number: list # The phone number to look up.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/lookup/format" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lookup/hlr
#
# operationId: LookupHlr
export def "lookup-hlr LookupHlr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --number: list # The phone number to look up.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/lookup/hlr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lookup/mnp
#
# operationId: LookupMnp
export def "lookup-mnp LookupMnp" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --number: list # The phone number to look up.
  --json: string # Determines whether the response shall be returned in JSON format.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "csv") (serialize-qp "json" $json "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lookup/mnp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /pricing
#
# operationId: Pricing
export def "pricing Pricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
  --country: string # The countries ISO code to get pricings for. Allowed values are de, fr, at. Omit to show pricings for all channels.
  --format: string # Determines the response format. Allowed values are json and csv. The default value is json.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/pricing" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /sms
#
# operationId: Sms
export def "sms Sms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer-1 # Response content type
  --text: string # The actual text message to send.
  --qp-to: string # The recipient number or group name.
  --qp-from: string # Set a custom sender name.
  --foreign-id: string # Identifier to return in callbacks.
  --label: string # A custom label.
  --udh: string # A custom User Data Header.
  --delay: string # Date/Time for delayed dispatch.
  --debug: float@debug-completer # Disable message sending. (default: 0)
  --no-reload: float@no-reload-completer # Enable sending of duplicated messages within 180 seconds. (default: 0)
  --unicode: float@unicode-completer # Force unicode encoding. Reduces sms length to 70 chars. (default: 0)
  --flash: float@flash-completer # Send as flash. (default: 0)
  --utf8: float@utf8-completer # Force UTF8 encoding. (default: 0)
  --details: float@details-completer # Attach message details to response. (default: 0)
  --return-msg-id: float@return-msg-id-completer # Attach message ID to second row in a text response. (default: 0)
  --json: float@json-completer # Return a detailed JSON response. (default: 0)
  --performance-tracking: float@performance-tracking-completer # Enable performance tracking for found URLs. (default: 0)
]: nothing -> record<balance: float, debug: string, messages: table<encoding: string, error: string, error_text: string, id: string, messages: list, parts: int, price: int, recipient: string, sender: string, success: bool, text: string>, sms_type: string, success: string, total_price: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "foreign_id" $foreign_id "scalar") (serialize-qp "label" $label "scalar") (serialize-qp "udh" $udh "scalar") (serialize-qp "delay" $delay "scalar") (serialize-qp "debug" $debug "scalar") (serialize-qp "no_reload" $no_reload "scalar") (serialize-qp "unicode" $unicode "scalar") (serialize-qp "flash" $flash "scalar") (serialize-qp "utf8" $utf8 "scalar") (serialize-qp "details" $details "scalar") (serialize-qp "return_msg_id" $return_msg_id "scalar") (serialize-qp "json" $json "scalar") (serialize-qp "performance_tracking" $performance_tracking "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sms" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /status
#
# operationId: Status
export def "status Status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --msg-id: string # The ID from the SMS.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "msg_id" $msg_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /validate_for_voice
#
# operationId: ValidateForVoice
export def "validate-for-voice ValidateForVoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --number: string # Determines the recipient. Can only be a number, not a contact from your address book.
  --callback: string # The callback URL which gets queried right after validation. (format: uri)
]: nothing -> record<code: string, error: string, success: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "number" $number "scalar") (serialize-qp "callback" $callback "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/validate_for_voice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /voice
#
# operationId: Voice
export def "voice Voice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-to: string # Determines the receiver. Must be a valid phone number or contact from the address book.
  --text: string # The text to convert to a voice message. Accepts valid XML too.
  --xml: float@xml-completer # Decides whether the parameter "text" is plain text or XML. The default value is 0.
  --qp-from: string # Sets the sender. Must be a verified sender. Use an inbound number of yours or one of ours.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "to" $qp_to "scalar") (serialize-qp "text" $text "scalar") (serialize-qp "xml" $xml "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/voice" $qp)
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
