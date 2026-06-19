# Auto-generated client for Telnyx API v2.0.0
# Source: https://api.apis.guru/v2/specs/telnyx.com/2.0.0/openapi.json
# Auth: --token flag or $env.TELNYX_API_TOKEN

const BASE_URL = "https://api.telnyx.com/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TELNYX_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://api.telnyx.com/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def status-completer [] { ["disabled" "enabled" "standby"] }
def sort-completer [] { ["business_name" "created_at" "first_name" "last_name" "street_address"] }
def sort-completer-1 [] { ["-active" "-created_at" "-name" "-short_name" "-updated_at" "active" "created_at" "name" "short_name" "updated_at"] }
def filter-number-type-completer [] { ["toll-free"] }
def filter-number-type-completer-1 [] { ["local" "mobile" "national" "toll-free"] }
def sort-completer-2 [] { ["active" "connection_name" "created_at"] }
def anchorsite-override-completer [] { ["Ashburn, VA" "Chicago, IL" "Latency" "San Jose, CA"] }
def dtmf-type-completer [] { ["Inband" "RFC 2833" "SIP INFO"] }
def webhook-api-version-completer [] { ["1" "2"] }
def filter-status-completer [] { ["delivered" "failed"] }
def filter-type-completer [] { ["command" "webhook"] }
def answering-machine-detection-completer [] { ["detect" "detect_beep" "detect_words" "disabled" "greeting_end"] }
def webhook-url-method-completer [] { ["GET" "POST"] }
def stream-type-completer [] { ["decrypted" "raw"] }
def language-completer [] { ["arb" "cmn-CN" "cy-GB" "da-DK" "de-DE" "en-AU" "en-GB" "en-GB-WLS" "en-IN" "en-US" "es-ES" "es-MX" "es-US" "fr-CA" "fr-FR" "hi-IN" "is-IS" "it-IT" "ja-JP" "ko-KR" "nb-NO" "nl-NL" "pl-PL" "pt-BR" "pt-PT" "ro-RO" "ru-RU" "sv-SE" "tr-TR"] }
def payload-type-completer [] { ["ssml" "text"] }
def service-level-completer [] { ["basic" "premium"] }
def voice-completer [] { ["female" "male"] }
def channels-completer [] { ["dual" "single"] }
def format-completer [] { ["mp3" "wav"] }
def cause-completer [] { ["CALL_REJECTED" "USER_BUSY"] }
def language-completer-1 [] { ["de" "en" "es" "fr" "it" "pl"] }
def comment-record-type-completer [] { ["number_order" "number_order_phone_number" "sub_number_order"] }
def beep-enabled-completer [] { ["always" "never" "on_enter" "on_exit"] }
def supervisor-role-completer [] { ["barge" "monitor" "none" "whisper"] }
def anchorsite-override-completer-1 [] { ["Amsterdam, Netherlands" "Ashburn, VA" "Chicago, IL" "Frankfurt, Germany" "Latency" "London, UK" "San Jose, CA" "Sydney, Australia" "Toronto, Canada" "Vancouver, Canada"] }
def encrypted-media-completer [] { ["SRTP" "ZRTP"] }
def sip-uri-calling-preference-completer [] { ["disabled" "internal" "unrestricted"] }
def transport-protocol-completer [] { ["TCP" "TLS" "UDP"] }
def filter-number-type-completer-2 [] { ["did" "toll-free"] }
def filter-phone-number-type-completer [] { ["landline" "local" "mobile" "national" "shared_cost" "toll_free"] }
def filter-country-code-completer [] { ["CA" "GB" "US"] }
def filter-group-by-completer [] { ["locality" "national_destination_code" "npa" "nxx" "rate_center"] }
def sort-completer-3 [] { ["created_at" "email"] }
def direction-completer [] { ["INBOUND" "OUTBOUND"] }
def status-completer-1 [] { ["DELIVERED" "DLR_TIMEOUT" "DLR_UNCONFIRMED" "FAILED" "GW_REJECT" "GW_TIMEOUT" "RECEIVED"] }
def message-type-completer [] { ["audio" "contacts" "document" "hsm" "image" "location" "template" "text" "unknown" "video" "voice"] }
def product-completer [] { ["ALPHANUMERIC_ID" "LONG_CODE" "RCS" "SHORT_CODE" "SHORT_CODE_FTEU" "TOLL_FREE"] }
def type-completer [] { ["MMS" "SMS"] }
def time-frame-completer [] { ["1h" "24h" "30d" "3d" "3h" "7d"] }
def webhook-api-version-completer-1 [] { ["1" "2" "2010-04-01"] }
def filter-channel-type-id-eq-completer [] { ["email" "sms" "voice" "webhook"] }
def channel-type-id-completer [] { ["email" "sms" "voice" "webhook"] }
def filter-associated-record-type-eq-completer [] { ["account" "phone_number"] }
def filter-status-eq-completer [] { ["delete-pending" "delete-received" "delete-submitted" "deleted" "enable-pending" "enable-received" "enable-submtited" "enabled"] }
def type-completer-1 [] { ["caller-name" "carrier"] }
def filter-status-completer-1 [] { ["completed" "failed" "in-progress"] }
def filter-type-completer-1 [] { ["sim_card_network_preferences"] }
def sort-completer-4 [] { ["-created_at" "-enabled" "-name" "-service_plan" "-traffic_type" "-usage_payment_method" "created_at" "enabled" "name" "service_plan" "traffic_type" "usage_payment_method"] }
def service-plan-completer [] { ["global" "international" "us"] }
def traffic-type-completer [] { ["conversational" "short_duration"] }
def usage-payment-method-completer [] { ["rate-deck" "tariff"] }
def filter-type-completer-2 [] { ["delete_phone_number_block"] }
def filter-status-completer-2 [] { ["completed" "failed" "in_progress" "pending"] }
def sort-completer-5 [] { ["created_at"] }
def filter-status-completer-3 [] { ["active" "deleted" "emergency_only" "port_failed" "port_out_pending" "port_pending" "ported_out" "purchase_failed" "purchase_pending"] }
def filter-usage-payment-method-completer [] { ["channel" "pay-per-minute"] }
def sort-completer-6 [] { ["connection_name" "phone_number" "purchased_at" "usage_payment_method"] }
def filter-type-completer-3 [] { ["delete_phone_numbers" "update_emergency_settings" "update_phone_numbers"] }
def number-level-routing-completer [] { ["disabled" "enabled"] }
def usage-payment-method-completer-1 [] { ["channel" "pay-per-minute"] }
def filter-misc-type-completer [] { ["full" "partial"] }
def sort-completer-7 [] { ["-activation_settings.foc_datetime_requested" "-created_at" "activation_settings.foc_datetime_requested" "created_at"] }
def filter-activation-status-completer [] { ["Activate RDY" "Active" "Cancel Pending" "Canceled" "Concurred" "Concurrence Sent" "Conflict" "Disconnect Pending" "Failed" "New" "Old" "Pending" "Sending"] }
def filter-portability-status-completer [] { ["confirmed" "pending" "provisional"] }
def filter-status-completer-4 [] { ["authorized" "canceled" "pending" "ported" "rejected" "rejected-pending"] }
def aggregation-type-completer [] { ["BILLING_GROUP" "CONNECTION" "NO_AGGREGATION" "TAG"] }
def product-breakdown-completer [] { ["COUNTRY" "DID_VS_TOLL_FREE" "DID_VS_TOLL_FREE_PER_COUNTRY" "NO_BREAKDOWN"] }
def aggregation-type-completer-1 [] { ["NO_AGGREGATION" "PROFILE" "TAGS"] }
def message-type-completer-1 [] { ["MMS" "SMS"] }
def sort-completer-8 [] { ["created_at" "name" "updated_at"] }
def filter-phone-number-type-completer-1 [] { ["local" "national" "toll-free"] }
def filter-action-completer [] { ["ordering" "porting"] }
def sort-completer-9 [] { ["action" "country_code" "locality" "phone_number_type"] }
def filter-type-completer-4 [] { ["remove_private_wireless_gateway" "set_private_wireless_gateway"] }
def status-callback-method-completer [] { ["get" "post"] }
def voice-method-completer [] { ["get" "post"] }
def currency-completer [] { ["AUD" "CAD" "EUR" "GBP" "USD"] }
def filter-status-eq-completer-1 [] { ["delivered" "failed"] }
def blocking-completer [] { ["no_wait" "wait"] }
def type-completer-2 [] { ["audio" "contacts" "document" "hsm" "image" "location" "template" "text" "unknown" "video" "voice"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "actions-bulk-telephony-credentials delete" } } | get name | first)
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

# Delete several credentials
#
# DELETE /actions/bulk/telephony_credentials
# operationId: DeleteBulkTelephonyCredential
export def "actions-bulk-telephony-credentials delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-tag: string # Filter by tag, required by bulk operations.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[tag]" $filter_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/actions/bulk/telephony_credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[tag]": $filter_tag} | compact), body: null}
}

# Update several credentials
#
# PATCH /actions/bulk/telephony_credentials
# operationId: UpdateBulkTelephonyCredential
export def "actions-bulk-telephony-credentials update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-tag: string # Filter by tag, required by bulk operations.
  --amount: int # Amount of credentials to be created. A single tag can hold at maximum 1000 credentials (e.g. 100)
  connection_id: string # Identifies the connection this credential is associated with. (e.g. 1234567890)
  --name: string # A default name for all credentials. (e.g. Default Credentials)
  tag: string # Tags a credential for bulk operations. A single tag can hold at maximum 1000 credentials. (e.g. My Credentials)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[tag]" $filter_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/actions/bulk/telephony_credentials" $qp)
  let req_body = {"amount": $amount, "connection_id": $connection_id, "name": $name, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"filter[tag]": $filter_tag} | compact), body: $req_body}
}

# Creates several credentials
#
# POST /actions/bulk/telephony_credentials
# operationId: CreateBulkTelephonyCredential
export def "actions-bulk-telephony-credentials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: int # Amount of credentials to be created. A single tag can hold at maximum 1000 credentials (e.g. 100)
  connection_id: string # Identifies the connection this credential is associated with. (e.g. 1234567890)
  --name: string # A default name for all credentials. (e.g. Default Credentials)
  tag: string # Tags a credential for bulk operations. A single tag can hold at maximum 1000 credentials. (e.g. My Credentials)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/actions/bulk/telephony_credentials")
  let req_body = {"amount": $amount, "connection_id": $connection_id, "name": $name, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bulk Network Preferences for SIM cards
#
# PUT /actions/network_preferences/sim_cards
# operationId: BulkSIMCardNetworkPreferences
# --mobile_operator_networks_preferences item shape: {mobile_operator_network_id?: string, priority?: int}
export def "actions-network-preferences-sim-cards update-bulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mobile-operator-networks-preferences: list # A list of mobile operator networks and the priority that should be applied when the SIM is connecting to the network. — item shape: {mobile_operator_network_id?: string, priority?: int}
  --sim-card-ids: list<string> # e.g. [6b14e151-8493-4fa1-8664-1cc4e6d14158, 6b14e151-8493-4fa1-8664-1cc4e6d14158]
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/actions/network_preferences/sim_cards")
  let req_body = {"mobile_operator_networks_preferences": $mobile_operator_networks_preferences, "sim_card_ids": $sim_card_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Register SIM cards
#
# POST /actions/register/sim_cards
# operationId: SimCardRegister
export def "actions-register-sim-cards create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  registration_codes: list<string> # e.g. [0000000001, 0000000002, 0000000003]
  --sim-card-group-id: string # The group SIMCardGroup identification. This attribute can be null when it's present in an associated resource. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --status: string@status-completer # Status on which the SIM card will be set after being successful registered. (default: enabled, e.g. standby)
  --tags: list<string> # Searchable tags associated with the SIM card (e.g. [personal, customers, active-customers])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/actions/register/sim_cards")
  let req_body = {"registration_codes": $registration_codes, "sim_card_group_id": $sim_card_group_id, "status": $status, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Perform activate or deactivate action on all credentials filtered by the provided tag.
#
# POST /actions/{action}/telephony_credentials
# operationId: BulkCredentialAction
export def "actions-telephony-credentials create-bulk" [
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-tag: string # Filter by tag, required by bulk operations.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($action | is-empty) { error make --unspanned { msg: "path parameter 'action' must be non-empty" } }
  let qp = [(serialize-qp "filter[tag]" $filter_tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({action: (encode-path-segment $action)} | format pattern "/actions/{action}/telephony_credentials") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[tag]": $filter_tag} | compact), body: null}
}

# List all addresses
#
# GET /addresses
# operationId: findAddresss
export def "addresses find-addresss" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-customer-reference-eq: string # Filter addresses via the customer reference set. Matching is not case-sensitive.
  --filter-customer-reference-contains: string # If present, addresses with customer_reference containing the given value will be returned. Matching is not case-sensitive.
  --filter-used-as-emergency: string # If set as 'true', only addresses used as the emergency address for at least one active phone-number will be returned. When set to 'false', the opposite happens: only addresses not used as the emergency address from phone-numbers will be returned. (default: null)
  --filter-street-address-contains: string # If present, addresses with street_address containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-address-book-eq: string # If present, only returns results with the address_book flag set to the given value. (default: null)
  --qp-sort: string@sort-completer # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: street_address: sorts the result by the street_address field in ascending order. -street_address: sorts the result by the street_address field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. street_address)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[customer_reference][eq]" $filter_customer_reference_eq "scalar") (serialize-qp "filter[customer_reference][contains]" $filter_customer_reference_contains "scalar") (serialize-qp "filter[used_as_emergency]" $filter_used_as_emergency "scalar") (serialize-qp "filter[street_address][contains]" $filter_street_address_contains "scalar") (serialize-qp "filter[address_book][eq]" $filter_address_book_eq "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[customer_reference][eq]": $filter_customer_reference_eq, "filter[customer_reference][contains]": $filter_customer_reference_contains, "filter[used_as_emergency]": $filter_used_as_emergency, "filter[street_address][contains]": $filter_street_address_contains, "filter[address_book][eq]": $filter_address_book_eq, "sort": $qp_sort} | compact), body: null}
}

# Creates an address
#
# POST /addresses
# operationId: CreateAddress
export def "addresses create-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address-book: oneof<nothing, bool> # Indicates whether or not the address should be considered part of your list of addresses that appear for regular use. (default: true, e.g. false)
  --administrative-area: string # The locality of the address. For US addresses, this corresponds to the state of the address. (e.g. IL)
  --borough: string # The borough of the address. This field is not used for addresses in the US but is used for some international addresses. (e.g. Guadalajara)
  business_name: string # The business name associated with the address. An address must have either a first last name or a business name. (e.g. Toy-O'Kon)
  country_code: string # The two-character (ISO 3166-1 alpha-2) country code of the address. (e.g. US)
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --extended-address: string # Additional street address information about the address such as, but not limited to, unit number or apartment number. (e.g. #504)
  first_name: string # The first name associated with the address. An address must have either a first last name or a business name. (e.g. Alfred)
  last_name: string # The last name associated with the address. An address must have either a first last name or a business name. (e.g. Foster)
  locality: string # The locality of the address. For US addresses, this corresponds to the city of the address. (e.g. Chicago)
  --neighborhood: string # The neighborhood of the address. This field is not used for addresses in the US but is used for some international addresses. (e.g. Ciudad de los deportes)
  --phone-number: string # The phone number associated with the address. (e.g. +12125559000)
  --postal-code: string # The postal code of the address. (e.g. 60654)
  street_address: string # The primary street address information about the address. (e.g. 311 W Superior Street)
  --validate-address: oneof<nothing, bool> # Indicates whether or not the address should be validated for emergency use upon creation or not. This should be left with the default value of `true` unless you have used the `/addresses/actions/validate` endpoint to validate the address separately prior to creation. If an address is not validated for emergency use upon creation and it is not valid, it will not be able to be used for emergency services. (default: true, e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addresses")
  let req_body = {"address_book": $address_book, "administrative_area": $administrative_area, "borough": $borough, "business_name": $business_name, "country_code": $country_code, "customer_reference": $customer_reference, "extended_address": $extended_address, "first_name": $first_name, "last_name": $last_name, "locality": $locality, "neighborhood": $neighborhood, "phone_number": $phone_number, "postal_code": $postal_code, "street_address": $street_address, "validate_address": $validate_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Validate an address
#
# POST /addresses/actions/validate
# operationId: validateAddress
export def "addresses-actions-validate validate-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --administrative-area: string # The locality of the address. For US addresses, this corresponds to the state of the address. (e.g. IL)
  country_code: string # The two-character (ISO 3166-1 alpha-2) country code of the address. (e.g. US)
  --extended-address: string # Additional street address information about the address such as, but not limited to, unit number or apartment number. (e.g. #504)
  --locality: string # The locality of the address. For US addresses, this corresponds to the city of the address. (e.g. Chicago)
  postal_code: string # The postal code of the address. (e.g. 60654)
  street_address: string # The primary street address information about the address. (e.g. 311 W Superior Street)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/addresses/actions/validate")
  let req_body = {"administrative_area": $administrative_area, "country_code": $country_code, "extended_address": $extended_address, "locality": $locality, "postal_code": $postal_code, "street_address": $street_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an address
#
# DELETE /addresses/{id}
# operationId: DeleteAddress
export def "addresses delete-address" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/addresses/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an address
#
# GET /addresses/{id}
# operationId: getAddress
export def "addresses get-address" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/addresses/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all SSO authentication providers
#
# GET /authentication_providers
# operationId: findAuthenticationProviders
export def "authentication-providers find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --qp-sort: string@sort-completer-1 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: name: sorts the result by the name field in ascending order. -name: sorts the result by the name field in descending order. If not given, results are sorted by created_at in descending order. (default: -created_at, e.g. name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/authentication_providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "sort": $qp_sort} | compact), body: null}
}

# Creates an authentication provider
#
# POST /authentication_providers
# operationId: CreateAuthenticationProvider
# --settings shape: {idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm?: "sha1"|"sha256"|"sha384"|"sha512", idp_entity_id: string, idp_sso_target_url: string}
export def "authentication-providers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # The active status of the authentication provider (default: true, e.g. true)
  name: string # The name associated with the authentication provider. (e.g. Okta)
  settings: record # The settings associated with the authentication provider. — shape: {idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm?: "sha1"|"sha256"|"sha384"|"sha512", idp_entity_id: string, idp_sso_target_url: string}
  --settings-url: string # The URL for the identity provider metadata file to populate the settings automatically. If the settings attribute is provided, that will be used instead. (e.g. https://myorg.myidp.com/saml/metadata)
  short_name: string # The short name associated with the authentication provider. This must be unique and URL-friendly, as it's going to be part of the login URL. (e.g. myorg)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/authentication_providers")
  let req_body = {"active": $active, "name": $name, "settings": $settings, "settings_url": $settings_url, "short_name": $short_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes an authentication provider
#
# DELETE /authentication_providers/{id}
# operationId: DeleteAuthenticationProvider
export def "authentication-providers delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/authentication_providers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an authentication provider
#
# GET /authentication_providers/{id}
# operationId: getAuthenticationProvider
export def "authentication-providers get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/authentication_providers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a authentication provider
#
# PATCH /authentication_providers/{id}
# operationId: updateAuthenticationProvider
# --settings shape: {idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm?: "sha1"|"sha256"|"sha384"|"sha512", idp_entity_id: string, idp_sso_target_url: string}
export def "authentication-providers update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # The active status of the authentication provider (default: true, e.g. true)
  --name: string # The name associated with the authentication provider. (e.g. Okta)
  --settings: record # The settings associated with the authentication provider. — shape: {idp_cert_fingerprint: string, idp_cert_fingerprint_algorithm?: "sha1"|"sha256"|"sha384"|"sha512", idp_entity_id: string, idp_sso_target_url: string}
  --settings-url: string # The URL for the identity provider metadata file to populate the settings automatically. If the settings attribute is provided, that will be used instead. (e.g. https://myorg.myidp.com/saml/metadata)
  --short-name: string # The short name associated with the authentication provider. This must be unique and URL-friendly, as it's going to be part of the login URL. (e.g. myorg)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/authentication_providers/{id}"))
  let req_body = {"active": $active, "name": $name, "settings": $settings, "settings_url": $settings_url, "short_name": $short_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List available phone number blocks
#
# GET /available_phone_number_blocks
# operationId: listAvailablePhoneNumberBlocks
export def "available-phone-number-blocks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-phone-number-starts-with: string # Filter number blocks that start with a pattern (meant to be used after `national_destination_code` filter has been set). (e.g. 201)
  --filter-phone-number-ends-with: string # Filter numbers ending with a pattern. (e.g. 8000)
  --filter-phone-number-contains: string # Filter numbers containing a pattern. (e.g. 456)
  --filter-locality: string # Filter phone numbers by city.
  --filter-administrative-area: string # Filter phone numbers by US state/CA province. (e.g. IL)
  --filter-country-code: string # Filter phone numbers by ISO alpha-2 country code. (e.g. US)
  --filter-national-destination-code: string # Filter by the national destination code of the number. This filter is only applicable to North American numbers.
  --filter-rate-center: string # Filter phone numbers by NANP rate center. This filter is only applicable to North American numbers. (e.g. CHICAGO HEIGHTS)
  --filter-number-type: string@filter-number-type-completer # Filter phone numbers by number type. (e.g. toll-free)
  --filter-features: list<string> # Filter if the phone number should be used for voice, fax, mms, sms, emergency. (e.g. voice,sms)
  --filter-minimum-block-size: int # Filter number blocks by minimum blocks size (e.g. 100)
  --filter-limit: int # Limits the number of results. (e.g. 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[phone_number][starts_with]" $filter_phone_number_starts_with "scalar") (serialize-qp "filter[phone_number][ends_with]" $filter_phone_number_ends_with "scalar") (serialize-qp "filter[phone_number][contains]" $filter_phone_number_contains "scalar") (serialize-qp "filter[locality]" $filter_locality "scalar") (serialize-qp "filter[administrative_area]" $filter_administrative_area "scalar") (serialize-qp "filter[country_code]" $filter_country_code "scalar") (serialize-qp "filter[national_destination_code]" $filter_national_destination_code "scalar") (serialize-qp "filter[rate_center]" $filter_rate_center "scalar") (serialize-qp "filter[number_type]" $filter_number_type "scalar") (serialize-qp "filter[features]" $filter_features "multi") (serialize-qp "filter[minimum_block_size]" $filter_minimum_block_size "scalar") (serialize-qp "filter[limit]" $filter_limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/available_phone_number_blocks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[phone_number][starts_with]": $filter_phone_number_starts_with, "filter[phone_number][ends_with]": $filter_phone_number_ends_with, "filter[phone_number][contains]": $filter_phone_number_contains, "filter[locality]": $filter_locality, "filter[administrative_area]": $filter_administrative_area, "filter[country_code]": $filter_country_code, "filter[national_destination_code]": $filter_national_destination_code, "filter[rate_center]": $filter_rate_center, "filter[number_type]": $filter_number_type, "filter[features]": $filter_features, "filter[minimum_block_size]": $filter_minimum_block_size, "filter[limit]": $filter_limit} | compact), body: null}
}

# List available phone numbers
#
# GET /available_phone_numbers
# operationId: listAvailablePhoneNumbers
export def "available-phone-numbers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-phone-number-starts-with: string # Filter numbers starting with a pattern (meant to be used after `national_destination_code` filter has been set).
  --filter-phone-number-ends-with: string # Filter numbers ending with a pattern.
  --filter-phone-number-contains: string # Filter numbers containing a pattern.
  --filter-locality: string # Filter phone numbers by city.
  --filter-administrative-area: string # Filter phone numbers by US state/CA province. (e.g. IL)
  --filter-country-code: string # Filter phone numbers by ISO alpha-2 country code. (e.g. US)
  --filter-national-destination-code: string # Filter by the national destination code of the number. This filter is only applicable to North American numbers.
  --filter-rate-center: string # Filter phone numbers by NANP rate center. This filter is only applicable to North American numbers. (e.g. CHICAGO HEIGHTS)
  --filter-number-type: string@filter-number-type-completer-1 # Filter phone numbers by number type. (e.g. local)
  --filter-features: list<string> # Filter if the phone number should be used for voice, fax, mms, sms, emergency. (e.g. voice,sms)
  --filter-limit: int # Limits the number of results. (e.g. 100)
  --filter-best-effort: oneof<nothing, bool> # Filter to determine if best effort results should be included. (e.g. false)
  --filter-quickship: oneof<nothing, bool> # Filter to exclude phone numbers that need additional time after to purchase to receive phone calls. (e.g. true)
  --filter-reservable: oneof<nothing, bool> # Filter to exclude phone numbers that cannot be reserved before purchase. (e.g. true)
  --filter-exclude-held-numbers: oneof<nothing, bool> # Filter to exclude phone numbers that are currently on hold for your account. (e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[phone_number][starts_with]" $filter_phone_number_starts_with "scalar") (serialize-qp "filter[phone_number][ends_with]" $filter_phone_number_ends_with "scalar") (serialize-qp "filter[phone_number][contains]" $filter_phone_number_contains "scalar") (serialize-qp "filter[locality]" $filter_locality "scalar") (serialize-qp "filter[administrative_area]" $filter_administrative_area "scalar") (serialize-qp "filter[country_code]" $filter_country_code "scalar") (serialize-qp "filter[national_destination_code]" $filter_national_destination_code "scalar") (serialize-qp "filter[rate_center]" $filter_rate_center "scalar") (serialize-qp "filter[number_type]" $filter_number_type "scalar") (serialize-qp "filter[features]" $filter_features "multi") (serialize-qp "filter[limit]" $filter_limit "scalar") (serialize-qp "filter[best_effort]" $filter_best_effort "scalar") (serialize-qp "filter[quickship]" $filter_quickship "scalar") (serialize-qp "filter[reservable]" $filter_reservable "scalar") (serialize-qp "filter[exclude_held_numbers]" $filter_exclude_held_numbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/available_phone_numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[phone_number][starts_with]": $filter_phone_number_starts_with, "filter[phone_number][ends_with]": $filter_phone_number_ends_with, "filter[phone_number][contains]": $filter_phone_number_contains, "filter[locality]": $filter_locality, "filter[administrative_area]": $filter_administrative_area, "filter[country_code]": $filter_country_code, "filter[national_destination_code]": $filter_national_destination_code, "filter[rate_center]": $filter_rate_center, "filter[number_type]": $filter_number_type, "filter[features]": $filter_features, "filter[limit]": $filter_limit, "filter[best_effort]": $filter_best_effort, "filter[quickship]": $filter_quickship, "filter[reservable]": $filter_reservable, "filter[exclude_held_numbers]": $filter_exclude_held_numbers} | compact), body: null}
}

# Retrieve user balance details
#
# GET /balance
# operationId: getUserBalance
export def "balance get-user" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/balance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all billing groups
#
# GET /billing_groups
# operationId: listBillingGroups
export def "billing-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/billing_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a billing group
#
# POST /billing_groups
# operationId: createBillingGroup
export def "billing-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A name for the billing group
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/billing_groups")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a billing group
#
# DELETE /billing_groups/{id}
# operationId: deleteBillingGroup
export def "billing-groups delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/billing_groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a billing group
#
# GET /billing_groups/{id}
# operationId: retrieveBillingGroup
export def "billing-groups get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/billing_groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a billing group
#
# PATCH /billing_groups/{id}
# operationId: updateBillingGroup
export def "billing-groups update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A name for the billing group
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/billing_groups/{id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List call control applications
#
# GET /call_control_applications
# operationId: listCallControlApplications
export def "call-control-applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-application-name-contains: string # If present, applications with application_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --qp-sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[application_name][contains]" $filter_application_name_contains "scalar") (serialize-qp "filter[outbound_voice_profile_id]" $filter_outbound_voice_profile_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/call_control_applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[application_name][contains]": $filter_application_name_contains, "filter[outbound_voice_profile_id]": $filter_outbound_voice_profile_id, "sort": $qp_sort} | compact), body: null}
}

# Create a call control application
#
# POST /call_control_applications
# operationId: createCallControlApplication
# --inbound shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
# --outbound shape: {channel_limit?: int, outbound_voice_profile_id?: string}
export def "call-control-applications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true)
  --anchorsite-override: string@anchorsite-override-completer # Latency directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: "Latency", e.g. "Amsterdam, Netherlands")
  application_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --first-command-timeout: oneof<nothing, bool> # Specifies whether calls to phone numbers associated with this connection should hangup after timing out. (default: false, e.g. true)
  --first-command-timeout-secs: int # Specifies how many seconds to wait before timing out a dial command. (default: 30, e.g. 10)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  webhook_event_url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/call_control_applications")
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "application_name": $application_name, "dtmf_type": $dtmf_type, "first_command_timeout": $first_command_timeout, "first_command_timeout_secs": $first_command_timeout_secs, "inbound": $inbound, "outbound": $outbound, "webhook_api_version": $webhook_api_version, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a call control application
#
# DELETE /call_control_applications/{id}
# operationId: deleteCallControlApplication
export def "call-control-applications delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/call_control_applications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a call control application
#
# GET /call_control_applications/{id}
# operationId: retrieveCallControlApplication
export def "call-control-applications get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/call_control_applications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a call control application
#
# PATCH /call_control_applications/{id}
# operationId: updateCallControlApplication
# --inbound shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
# --outbound shape: {channel_limit?: int, outbound_voice_profile_id?: string}
export def "call-control-applications update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true)
  --anchorsite-override: string@anchorsite-override-completer # Latency directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: "Latency", e.g. "Amsterdam, Netherlands")
  application_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --first-command-timeout: oneof<nothing, bool> # Specifies whether calls to phone numbers associated with this connection should hangup after timing out. (default: false, e.g. true)
  --first-command-timeout-secs: int # Specifies how many seconds to wait before timing out a dial command. (default: 30, e.g. 10)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  webhook_event_url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/call_control_applications/{id}"))
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "application_name": $application_name, "dtmf_type": $dtmf_type, "first_command_timeout": $first_command_timeout, "first_command_timeout_secs": $first_command_timeout_secs, "inbound": $inbound, "outbound": $outbound, "webhook_api_version": $webhook_api_version, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List call events
#
# GET /call_events
# operationId: listCallEvents
export def "call-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-call-leg-id: string # The unique identifier of an individual call leg. (format: uuid)
  --filter-call-session-id: string # The unique identifier of the call control session. A session may include multiple call leg events. (format: uuid)
  --filter-status: string@filter-status-completer # Event status (e.g. delivered)
  --filter-type: string@filter-type-completer # Event type (e.g. webhook)
  --filter-event-timestamp-gt: string # Event timestamp: greater than (e.g. 2019-03-29T11:10:00Z)
  --filter-event-timestamp-gte: string # Event timestamp: greater than or equal (e.g. 2019-03-29T11:10:00Z)
  --filter-event-timestamp-lt: string # Event timestamp: lower than (e.g. 2019-03-29T11:10:00Z)
  --filter-event-timestamp-lte: string # Event timestamp: lower than or equal (e.g. 2019-03-29T11:10:00Z)
  --filter-event-timestamp-eq: string # Event timestamp: equal (e.g. 2019-03-29T11:10:00Z)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[call_leg_id]" $filter_call_leg_id "scalar") (serialize-qp "filter[call_session_id]" $filter_call_session_id "scalar") (serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "filter[type]" $filter_type "scalar") (serialize-qp "filter[event_timestamp][gt]" $filter_event_timestamp_gt "scalar") (serialize-qp "filter[event_timestamp][gte]" $filter_event_timestamp_gte "scalar") (serialize-qp "filter[event_timestamp][lt]" $filter_event_timestamp_lt "scalar") (serialize-qp "filter[event_timestamp][lte]" $filter_event_timestamp_lte "scalar") (serialize-qp "filter[event_timestamp][eq]" $filter_event_timestamp_eq "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/call_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[call_leg_id]": $filter_call_leg_id, "filter[call_session_id]": $filter_call_session_id, "filter[status]": $filter_status, "filter[type]": $filter_type, "filter[event_timestamp][gt]": $filter_event_timestamp_gt, "filter[event_timestamp][gte]": $filter_event_timestamp_gte, "filter[event_timestamp][lt]": $filter_event_timestamp_lt, "filter[event_timestamp][lte]": $filter_event_timestamp_lte, "filter[event_timestamp][eq]": $filter_event_timestamp_eq, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Dial
#
# POST /calls
# operationId: callDial
# --answering_machine_detection_config shape: {after_greeting_silence_millis?: int, between_words_silence_millis?: int, greeting_duration_millis?: int, greeting_silence_duration_millis?: int, greeting_total_analysis_time_millis?: int, initial_silence_millis?: int, maximum_number_of_words?: int, maximum_word_length_millis?: int, silence_threshold?: int, total_analysis_time_millis?: int}
# --custom_headers item shape: {name: string, value: string}
export def "calls create-dial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --answering-machine-detection: string@answering-machine-detection-completer # Enables Answering Machine Detection. When a call is answered, Telnyx runs real-time detection to determine if it was picked up by a human or a machine and sends an `call.machine.detection.ended` webhook with the analysis result. If 'greeting_end' or 'detect_words' is used and a 'machine' is detected, you will receive another 'call.machine.greeting.ended' webhook when the answering machine greeting ends with a beep or silence. If `detect_beep` is used, you will only receive 'call.machine.greeting.ended' if a beep is detected. (default: disabled)
  --answering-machine-detection-config: record # Optional configuration parameters to modify 'answering_machine_detection' performance. — shape: {after_greeting_silence_millis?: int, between_words_silence_millis?: int, greeting_duration_millis?: int, greeting_silence_duration_millis?: int, greeting_total_analysis_time_millis?: int, initial_silence_millis?: int, maximum_number_of_words?: int, maximum_word_length_millis?: int, silence_threshold?: int, total_analysis_time_millis?: int}
  --audio-url: string # The URL of a file to be played back to the callee when the call is answered. The URL can point to either a WAV or MP3 file. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --billing-group-id: string # Use this field to set the Billing Group ID for the call. Must be a valid and existing Billing Group ID. (format: uuid, e.g. f5586561-8ff0-4291-a0ac-84fe544797bd)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  connection_id: string # The ID of the Call Control App (formerly ID of the connection) to be used when dialing the destination.
  --custom-headers: list # Custom headers to be added to the SIP INVITE. (e.g. [{name: head_1, value: val_1}, {name: head_2, value: val_2}]) — item shape: {name: string, value: string}
  --body-from: string # The `from` number to be used as the caller id presented to the destination (`to` number). The number should be in +E164 format. This attribute will default to the `from` number of the original call if omitted. (e.g. +18005550101)
  --from-display-name: string # The `from_display_name` string to be used as the caller id name (SIP From Display Name) presented to the destination (`to` number). The string should have a maximum of 128 characters, containing only letters, numbers, spaces, and -_~!.+ special characters. If ommited, the display name will be the same as the number in the `from` field. (e.g. Company Name)
  --link-to: string # Use another call's control id for sharing the same call session id (e.g. ilditnZK_eVysupV21KzmzN_sM29ygfauQojpm4BgFtfX5hXAcjotg==)
  --media-name: string # The media_name of a file to be played back to the callee when the call is answered. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --sip-auth-password: string # SIP Authentication password used for SIP challenges.
  --sip-auth-username: string # SIP Authentication username used for SIP challenges.
  --time-limit-secs: int # Sets the maximum duration of a Call Control Leg in seconds. If the time limit is reached, the call will hangup and a `call.hangup` webhook with a `hangup_cause` of `time_limit` will be sent. For example, by setting a time limit of 120 seconds, a Call Leg will be automatically terminated two minutes after being answered. The default time limit is 14400 seconds or 4 hours and this is also the maximum allowed call length. (format: int32, default: 14400, e.g. 600)
  --timeout-secs: int # The number of seconds that Telnyx will wait for the call to be answered by the destination to which it is being called. If the timeout is reached before an answer is received, the call will hangup and a `call.hangup` webhook with a `hangup_cause` of `timeout` will be sent. Minimum value is 5 seconds. Maximum value is 120 seconds. (format: int32, default: 30, e.g. 60)
  --body-to: string # The DID or SIP URI to dial out to. (e.g. +18005550100 or sip:username@sip.telnyx.com)
  --webhook-url: string # Use this field to override the URL for which Telnyx will send subsequent webhooks to for this call. (e.g. https://www.example.com/server-b/)
  --webhook-url-method: string@webhook-url-method-completer # HTTP request type used for `webhook_url`. (default: POST, e.g. GET)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls")
  let req_body = {"answering_machine_detection": $answering_machine_detection, "answering_machine_detection_config": $answering_machine_detection_config, "audio_url": $audio_url, "billing_group_id": $billing_group_id, "client_state": $client_state, "command_id": $command_id, "connection_id": $connection_id, "custom_headers": $custom_headers, "from": $body_from, "from_display_name": $from_display_name, "link_to": $link_to, "media_name": $media_name, "sip_auth_password": $sip_auth_password, "sip_auth_username": $sip_auth_username, "time_limit_secs": $time_limit_secs, "timeout_secs": $timeout_secs, "to": $body_to, "webhook_url": $webhook_url, "webhook_url_method": $webhook_url_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a call status
#
# GET /calls/{call_control_id}
# operationId: retrieveCallStatus
export def "calls get-status" [
  call_control_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Answer call
#
# POST /calls/{call_control_id}/actions/answer
# operationId: callAnswer
export def "calls-actions-answer create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # Use this field to set the Billing Group ID for the call. Must be a valid and existing Billing Group ID. (format: uuid, e.g. f5586561-8ff0-4291-a0ac-84fe544797bd)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --webhook-url: string # Use this field to override the URL for which Telnyx will send subsequent webhooks to for this call. (e.g. https://www.example.com/server-b/)
  --webhook-url-method: string@webhook-url-method-completer # HTTP request type used for `webhook_url`. (default: POST, e.g. GET)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/answer"))
  let req_body = {"billing_group_id": $billing_group_id, "client_state": $client_state, "command_id": $command_id, "webhook_url": $webhook_url, "webhook_url_method": $webhook_url_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Bridge calls
#
# POST /calls/{call_control_id}/actions/bridge
# operationId: callBridge
export def "calls-actions-bridge create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-call-control-id: string # The Call Control ID of the call you want to bridge with. (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQ)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --park-after-unbridge: string # Specifies behavior after the bridge ends (i.e. the opposite leg either hangs up or is transferred). If supplied with the value `self`, the current leg will be parked after unbridge. If not set, the default behavior is to hang up the leg. (e.g. self)
  --queue: string # The name of the queue you want to bridge with, can't be used together with call_control_id parameter. Bridging with a queue means bridging with the first call in the queue. The call will always be removed from the queue regardless of whether bridging succeeds. Returns an error when the queue is empty. (e.g. support)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/bridge"))
  let req_body = {"call_control_id": $body_call_control_id, "client_state": $client_state, "command_id": $command_id, "park_after_unbridge": $park_after_unbridge, "queue": $queue} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Enqueue call
#
# POST /calls/{call_control_id}/actions/enqueue
# operationId: callEnqueue
export def "calls-actions-enqueue create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --max-size: int # The maximum number of calls allowed in the queue at a given time. Can't be modified for an existing queue. (default: 100, e.g. 200)
  --max-wait-time-secs: int # The number of seconds after which the call will be removed from the queue. (e.g. 600)
  --queue-name: string # The name of the queue the call should be put in. If a queue with a given name doesn't exist yet it will be created. (e.g. tier_1_support)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/enqueue"))
  let req_body = {"client_state": $client_state, "command_id": $command_id, "max_size": $max_size, "max_wait_time_secs": $max_wait_time_secs, "queue_name": $queue_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Forking start
#
# POST /calls/{call_control_id}/actions/fork_start
# operationId: callForkStart
export def "calls-actions-fork-start start" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --rx: string # The network target, <udp:ip_address:port>, where the call's incoming RTP media packets should be forwarded. (e.g. 192.0.2.1:9000)
  --stream-type: string@stream-type-completer # Optionally specify a media type to stream. If `decrpyted` selected, Telnyx will decrypt incoming SIP media before forking to the target. `rx` and `tx` are required fields if `decrypted` selected. (default: raw, e.g. decrypted)
  --target: string # The network target, <udp:ip_address:port>, where the call's RTP media packets should be forwarded. Both incoming and outgoing media packets will be delivered to the specified target, and information about the stream will be included in the encapsulation protocol header, including the direction (0 = inbound; 1 = outbound), leg (0 = A-leg; 1 = B-leg), and call_leg_id. (e.g. udp:192.0.2.1:9000)
  --tx: string # The network target, <udp:ip_address:port>, where the call's outgoing RTP media packets should be forwarded. (e.g. 192.0.2.1:9001)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/fork_start"))
  let req_body = {"client_state": $client_state, "command_id": $command_id, "rx": $rx, "stream_type": $stream_type, "target": $target, "tx": $tx} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Forking stop
#
# POST /calls/{call_control_id}/actions/fork_stop
# operationId: callForkStop
export def "calls-actions-fork-stop stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/fork_stop"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gather stop
#
# POST /calls/{call_control_id}/actions/gather_stop
# operationId: callGatherStop
export def "calls-actions-gather-stop stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/gather_stop"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gather using audio
#
# POST /calls/{call_control_id}/actions/gather_using_audio
# operationId: callGatherUsingAudio
export def "calls-actions-gather-using-audio create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-url: string # The URL of a file to be played back at the beginning of each prompt. The URL can point to either a WAV or MP3 file. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --inter-digit-timeout-millis: int # The number of milliseconds to wait for input between digits. (format: int32, default: 5000, e.g. 10000)
  --invalid-audio-url: string # The URL of a file to play when digits don't match the `valid_digits` parameter or the number of digits is not between `min` and `max`. The URL can point to either a WAV or MP3 file. invalid_media_name and invalid_audio_url cannot be used together in one request. (e.g. http://example.com/invalid.wav)
  --invalid-media-name: string # The media_name of a file to be played back when digits don't match the `valid_digits` parameter or the number of digits is not between `min` and `max`. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --maximum-digits: int # The maximum number of digits to fetch. This parameter has a maximum value of 128. (format: int32, default: 128, e.g. 10)
  --maximum-tries: int # The maximum number of times the file should be played if there is no input from the user on the call. (format: int32, default: 3, e.g. 3)
  --media-name: string # The media_name of a file to be played back at the beginning of each prompt. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --minimum-digits: int # The minimum number of digits to fetch. This parameter has a minimum value of 1. (format: int32, default: 1, e.g. 1)
  --terminating-digit: string # The digit used to terminate input if fewer than `maximum_digits` digits have been gathered. (default: #, e.g. #)
  --timeout-millis: int # The number of milliseconds to wait for a DTMF response after file playback ends before a replaying the sound file. (format: int32, default: 60000, e.g. 60000)
  --valid-digits: string # A list of all digits accepted as valid. (default: 0123456789#*, e.g. 123)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/gather_using_audio"))
  let req_body = {"audio_url": $audio_url, "client_state": $client_state, "command_id": $command_id, "inter_digit_timeout_millis": $inter_digit_timeout_millis, "invalid_audio_url": $invalid_audio_url, "invalid_media_name": $invalid_media_name, "maximum_digits": $maximum_digits, "maximum_tries": $maximum_tries, "media_name": $media_name, "minimum_digits": $minimum_digits, "terminating_digit": $terminating_digit, "timeout_millis": $timeout_millis, "valid_digits": $valid_digits} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Gather using speak
#
# POST /calls/{call_control_id}/actions/gather_using_speak
# operationId: callGatherUsingSpeak
export def "calls-actions-gather-using-speak create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --inter-digit-timeout-millis: int # The number of milliseconds to wait for input between digits. (format: int32, default: 5000, e.g. 10000)
  --invalid-payload: string # The text or SSML to be converted into speech when digits don't match the `valid_digits` parameter or the number of digits is not between `min` and `max`. There is a 5,000 character limit. (e.g. Say this on the call)
  language: string@language-completer # The language you want spoken. (e.g. en-US)
  --maximum-digits: int # The maximum number of digits to fetch. This parameter has a maximum value of 128. (format: int32, default: 128, e.g. 10)
  --maximum-tries: int # The maximum number of times that a file should be played back if there is no input from the user on the call. (format: int32, default: 3, e.g. 3)
  --minimum-digits: int # The minimum number of digits to fetch. This parameter has a minimum value of 1. (format: int32, default: 1, e.g. 1)
  payload: string # The text or SSML to be converted into speech. There is a 5,000 character limit. (e.g. Say this on the call)
  --payload-type: string@payload-type-completer # The type of the provided payload. The payload can either be plain text, or Speech Synthesis Markup Language (SSML). (default: text, e.g. ssml)
  --service-level: string@service-level-completer # This parameter impacts speech quality, language options and payload types. When using `basic`, only the `en-US` language and payload type `text` are allowed. (default: premium, e.g. premium)
  --terminating-digit: string # The digit used to terminate input if fewer than `maximum_digits` digits have been gathered. (default: #, e.g. #)
  --timeout-millis: int # The number of milliseconds to wait for a DTMF response after speak ends before a replaying the sound file. (format: int32, default: 60000, e.g. 60000)
  --valid-digits: string # A list of all digits accepted as valid. (default: 0123456789#*, e.g. 123)
  voice: string@voice-completer # The gender of the voice used to speak back the text. (e.g. female)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/gather_using_speak"))
  let req_body = {"client_state": $client_state, "command_id": $command_id, "inter_digit_timeout_millis": $inter_digit_timeout_millis, "invalid_payload": $invalid_payload, "language": $language, "maximum_digits": $maximum_digits, "maximum_tries": $maximum_tries, "minimum_digits": $minimum_digits, "payload": $payload, "payload_type": $payload_type, "service_level": $service_level, "terminating_digit": $terminating_digit, "timeout_millis": $timeout_millis, "valid_digits": $valid_digits, "voice": $voice} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Hangup call
#
# POST /calls/{call_control_id}/actions/hangup
# operationId: callHangup
export def "calls-actions-hangup create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/hangup"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Remove call from a queue
#
# POST /calls/{call_control_id}/actions/leave_queue
# operationId: leaveQueue
export def "calls-actions-leave-queue create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/leave_queue"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Play audio URL
#
# POST /calls/{call_control_id}/actions/playback_start
# operationId: callPlaybackStart
export def "calls-actions-playback-start start" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-url: string # The URL of a file to be played back on the call. The URL can point to either a WAV or MP3 file. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --body-loop: any
  --media-name: string # The media_name of a file to be played back on the call. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --body-overlay: oneof<nothing, bool> # When enabled, audio will be mixed on top of any other audio that is actively being played back. Note that `overlay: true` will only work if there is another audio file already being played on the call. (default: false, e.g. true)
  --stop: string # When specified, it stops the current audio being played. Specify `current` to stop the current audio being played, and to play the next file in the queue. Specify `all` to stop the current audio file being played and to also clear all audio files from the queue. (default: all, e.g. current)
  --target-legs: string # Specifies the leg or legs on which audio will be played. If supplied, the value must be either `self`, `opposite` or `both`. (default: self, e.g. self)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/playback_start"))
  let req_body = {"audio_url": $audio_url, "client_state": $client_state, "command_id": $command_id, "loop": $body_loop, "media_name": $media_name, "overlay": $body_overlay, "stop": $stop, "target_legs": $target_legs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stop audio playback
#
# POST /calls/{call_control_id}/actions/playback_stop
# operationId: callPlaybackStop
export def "calls-actions-playback-stop stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --stop: string # Use `current` to stop only the current audio or `all` to stop all audios in the queue. (default: all, e.g. current)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/playback_stop"))
  let req_body = {"client_state": $client_state, "command_id": $command_id, "stop": $stop} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Record pause
#
# POST /calls/{call_control_id}/actions/record_pause
# operationId: callRecordPause
export def "calls-actions-record-pause pause" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/record_pause"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Record resume
#
# POST /calls/{call_control_id}/actions/record_resume
# operationId: callRecordResume
export def "calls-actions-record-resume create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/record_resume"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Recording start
#
# POST /calls/{call_control_id}/actions/record_start
# operationId: callRecordStart
export def "calls-actions-record-start start" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: string@channels-completer # When `dual`, final audio file will be stereo recorded with the first leg on channel A, and the rest on channel B. (e.g. single)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  format: string@format-completer # The audio file format used when storing the call recording. Can be either `mp3` or `wav`. (e.g. mp3)
  --max-length: int # Defines the maximum length for the recording in seconds. Minimum value is 0. Maximum value is 14400. Default is 0 (infinite) (format: int32, default: 0, e.g. 100)
  --play-beep: oneof<nothing, bool> # If enabled, a beep sound will be played at the start of a recording. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/record_start"))
  let req_body = {"channels": $channels, "client_state": $client_state, "command_id": $command_id, "format": $format, "max_length": $max_length, "play_beep": $play_beep} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Recording stop
#
# POST /calls/{call_control_id}/actions/record_stop
# operationId: callRecordStop
export def "calls-actions-record-stop stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/record_stop"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# SIP Refer a call
#
# POST /calls/{call_control_id}/actions/refer
# operationId: callRefer
# --custom_headers item shape: {name: string, value: string}
export def "calls-actions-refer create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --custom-headers: list # Custom headers to be added to the SIP INVITE. (e.g. [{name: head_1, value: val_1}, {name: head_2, value: val_2}]) — item shape: {name: string, value: string}
  sip_address: string # The SIP URI to which the call will be referred to. (e.g. sip:username@sip.non-telnyx-address.com)
  --sip-auth-password: string # SIP Authentication password used for SIP challenges.
  --sip-auth-username: string # SIP Authentication username used for SIP challenges.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/refer"))
  let req_body = {"client_state": $client_state, "command_id": $command_id, "custom_headers": $custom_headers, "sip_address": $sip_address, "sip_auth_password": $sip_auth_password, "sip_auth_username": $sip_auth_username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reject a call
#
# POST /calls/{call_control_id}/actions/reject
# operationId: callReject
export def "calls-actions-reject reject" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cause: string@cause-completer # Cause for call rejection. (e.g. USER_BUSY)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/reject"))
  let req_body = {"cause": $cause, "client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send DTMF
#
# POST /calls/{call_control_id}/actions/send_dtmf
# operationId: callSendDTMF
export def "calls-actions-send-dtmf send" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  digits: string # DTMF digits to send. Valid digits are 0-9, A-D, *, and #. Pauses can be added using w (0.5s) and W (1s). (e.g. 1www2WABCDw9)
  --duration-millis: int # Specifies for how many milliseconds each digit will be played in the audio stream. Ranges from 100 to 500ms (format: int32, default: 250, e.g. 500)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/send_dtmf"))
  let req_body = {"client_state": $client_state, "command_id": $command_id, "digits": $digits, "duration_millis": $duration_millis} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Speak text
#
# POST /calls/{call_control_id}/actions/speak
# operationId: callSpeak
export def "calls-actions-speak create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  language: string@language-completer # The language you want spoken. (e.g. en-US)
  payload: string # The text or SSML to be converted into speech. There is a 5,000 character limit. (e.g. Say this on the call)
  --payload-type: string@payload-type-completer # The type of the provided payload. The payload can either be plain text, or Speech Synthesis Markup Language (SSML). (default: text, e.g. ssml)
  --service-level: string@service-level-completer # This parameter impacts speech quality, language options and payload types. When using `basic`, only the `en-US` language and payload type `text` are allowed. (default: premium, e.g. premium)
  --stop: string # When specified, it stops the current audio being played. Specify `current` to stop the current audio being played, and to play the next file in the queue. Specify `all` to stop the current audio file being played and to also clear all audio files from the queue. (e.g. current)
  voice: string@voice-completer # The gender of the voice used to speak back the text. (e.g. female)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/speak"))
  let req_body = {"client_state": $client_state, "command_id": $command_id, "language": $language, "payload": $payload, "payload_type": $payload_type, "service_level": $service_level, "stop": $stop, "voice": $voice} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Transcription start
#
# POST /calls/{call_control_id}/actions/transcription_start
# operationId: callTranscriptionStart
export def "calls-actions-transcription-start start" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --language: string@language-completer-1 # Language to use for speech recognition (default: en, e.g. en)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/transcription_start"))
  let req_body = {"client_state": $client_state, "command_id": $command_id, "language": $language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Transcription stop
#
# POST /calls/{call_control_id}/actions/transcription_stop
# operationId: callTranscriptionStop
export def "calls-actions-transcription-stop stop" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/transcription_stop"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Transfer call
#
# POST /calls/{call_control_id}/actions/transfer
# operationId: callTransfer
# --answering_machine_detection_config shape: {after_greeting_silence_millis?: int, between_words_silence_millis?: int, greeting_duration_millis?: int, greeting_silence_duration_millis?: int, greeting_total_analysis_time_millis?: int, initial_silence_millis?: int, maximum_number_of_words?: int, maximum_word_length_millis?: int, silence_threshold?: int, total_analysis_time_millis?: int}
# --custom_headers item shape: {name: string, value: string}
export def "calls-actions-transfer create" [
  call_control_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --answering-machine-detection: string@answering-machine-detection-completer # Enables Answering Machine Detection. When a call is answered, Telnyx runs real-time detection to determine if it was picked up by a human or a machine and sends an `call.machine.detection.ended` webhook with the analysis result. If 'greeting_end' or 'detect_words' is used and a 'machine' is detected, you will receive another 'call.machine.greeting.ended' webhook when the answering machine greeting ends with a beep or silence. If `detect_beep` is used, you will only receive 'call.machine.greeting.ended' if a beep is detected. (default: disabled)
  --answering-machine-detection-config: record # Optional configuration parameters to modify 'answering_machine_detection' performance. — shape: {after_greeting_silence_millis?: int, between_words_silence_millis?: int, greeting_duration_millis?: int, greeting_silence_duration_millis?: int, greeting_total_analysis_time_millis?: int, initial_silence_millis?: int, maximum_number_of_words?: int, maximum_word_length_millis?: int, silence_threshold?: int, total_analysis_time_millis?: int}
  --audio-url: string # The URL of a file to be played back when the transfer destination answers before bridging the call. The URL can point to either a WAV or MP3 file. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --custom-headers: list # Custom headers to be added to the SIP INVITE. (e.g. [{name: head_1, value: val_1}, {name: head_2, value: val_2}]) — item shape: {name: string, value: string}
  --body-from: string # The `from` number to be used as the caller id presented to the destination (`to` number). The number should be in +E164 format. This attribute will default to the `from` number of the original call if omitted. (e.g. +18005550101)
  --from-display-name: string # The `from_display_name` string to be used as the caller id name (SIP From Display Name) presented to the destination (`to` number). The string should have a maximum of 128 characters, containing only letters, numbers, spaces, and -_~!.+ special characters. If ommited, the display name will be the same as the number in the `from` field. (e.g. Company Name)
  --media-name: string # The media_name of a file to be played back when the transfer destination answers before bridging the call. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
  --sip-auth-password: string # SIP Authentication password used for SIP challenges. (e.g. password)
  --sip-auth-username: string # SIP Authentication username used for SIP challenges. (e.g. username)
  --target-leg-client-state: string # Use this field to add state to every subsequent webhook for the new leg. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --time-limit-secs: int # Sets the maximum duration of a Call Control Leg in seconds. If the time limit is reached, the call will hangup and a `call.hangup` webhook with a `hangup_cause` of `time_limit` will be sent. For example, by setting a time limit of 120 seconds, a Call Leg will be automatically terminated two minutes after being answered. The default time limit is 14400 seconds or 4 hours and this is also the maximum allowed call length. (format: int32, default: 14400, e.g. 600)
  --timeout-secs: int # The number of seconds that Telnyx will wait for the call to be answered by the destination to which it is being transferred. If the timeout is reached before an answer is received, the call will hangup and a `call.hangup` webhook with a `hangup_cause` of `timeout` will be sent. Minimum value is 5 seconds. Maximum value is 120 seconds. (format: int32, default: 30, e.g. 60)
  --body-to: string # The DID or SIP URI to dial out and bridge to the given call. (e.g. +18005550100 or sip:username@sip.telnyx.com)
  --webhook-url: string # Use this field to override the URL for which Telnyx will send subsequent webhooks to for this call. (e.g. https://www.example.com/server-b/)
  --webhook-url-method: string@webhook-url-method-completer # HTTP request type used for `webhook_url`. (default: POST, e.g. GET)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({call_control_id: (encode-path-segment $call_control_id)} | format pattern "/calls/{call_control_id}/actions/transfer"))
  let req_body = {"answering_machine_detection": $answering_machine_detection, "answering_machine_detection_config": $answering_machine_detection_config, "audio_url": $audio_url, "client_state": $client_state, "command_id": $command_id, "custom_headers": $custom_headers, "from": $body_from, "from_display_name": $from_display_name, "media_name": $media_name, "sip_auth_password": $sip_auth_password, "sip_auth_username": $sip_auth_username, "target_leg_client_state": $target_leg_client_state, "time_limit_secs": $time_limit_secs, "timeout_secs": $timeout_secs, "to": $body_to, "webhook_url": $webhook_url, "webhook_url_method": $webhook_url_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve all comments
#
# GET /comments
# operationId: listComments
export def "comments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-comment-record-type: string # Record type that the comment relates to i.e number_order, sub_number_order or number_order_phone_number (e.g. sub_number_order)
  --filter-comment-record-id: string # ID of the record the comments relate to (e.g. 8ffb3622-7c6b-4ccc-b65f-7a3dc0099576)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[comment_record_type]" $filter_comment_record_type "scalar") (serialize-qp "filter[comment_record_id]" $filter_comment_record_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[comment_record_type]": $filter_comment_record_type, "filter[comment_record_id]": $filter_comment_record_id} | compact), body: null}
}

# Create a comment
#
# POST /comments
# operationId: createComment
export def "comments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # e.g. Hi there, ....
  --comment-record-id: string # format: uuid, e.g. 8ffb3622-7c6b-4ccc-b65f-7a3dc0099576
  --comment-record-type: string@comment-record-type-completer # e.g. sub_number_order
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/comments")
  let req_body = {"body": $body, "comment_record_id": $comment_record_id, "comment_record_type": $comment_record_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a comment
#
# GET /comments/{id}
# operationId: retrieveComment
export def "comments get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/comments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Mark a comment as read
#
# PATCH /comments/{id}/read
# operationId: markCommentRead
export def "comments-read get-mark" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/comments/{id}/read"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List conferences
#
# GET /conferences
# operationId: listConferences
export def "conferences list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: string # If present, conferences will be filtered to those with a matching `name` attribute. Matching is case-sensitive
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conferences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[name]": $filter_name, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create conference
#
# POST /conferences
# operationId: createConference
export def "conferences create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beep-enabled: string@beep-enabled-completer # Whether a beep sound should be played when participants join and/or leave the conference. (default: never, e.g. on_exit)
  call_control_id: string # Unique identifier and token for controlling the call (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQczRrZvZakpWxBlpw48KyZQ==)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --comfort-noise: oneof<nothing, bool> # Toggle background comfort noise. (default: true, e.g. false)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --duration-minutes: int # Time length (minutes) after which the conference will end. (e.g. 5)
  --hold-audio-url: string # The URL of a file to be played to participants joining the conference. The URL can point to either a WAV or MP3 file. hold_media_name and hold_audio_url cannot be used together in one request. Takes effect only when "start_conference_on_create" is set to "false". (e.g. http://example.com/message.wav)
  --hold-media-name: string # The media_name of a file to be played to participants joining the conference. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. Takes effect only when "start_conference_on_create" is set to "false". (e.g. my_media_uploaded_to_media_storage_api)
  name: string # Name of the conference (e.g. Business)
  --start-conference-on-create: oneof<nothing, bool> # Whether the conference should be started on creation. If the conference isn't started all participants that join are automatically put on hold. Defaults to "true". (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conferences")
  let req_body = {"beep_enabled": $beep_enabled, "call_control_id": $call_control_id, "client_state": $client_state, "comfort_noise": $comfort_noise, "command_id": $command_id, "duration_minutes": $duration_minutes, "hold_audio_url": $hold_audio_url, "hold_media_name": $hold_media_name, "name": $name, "start_conference_on_create": $start_conference_on_create} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List conference participants
#
# GET /conferences/{conference_id}/participants
# operationId: listConferenceParticipants
export def "conferences-participants list" [
  conference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-muted: oneof<nothing, bool> # If present, participants will be filtered to those who are/are not muted
  --filter-on-hold: oneof<nothing, bool> # If present, participants will be filtered to those who are/are not put on hold
  --filter-whispering: oneof<nothing, bool> # If present, participants will be filtered to those who are whispering or are not
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($conference_id | is-empty) { error make --unspanned { msg: "path parameter 'conference_id' must be non-empty" } }
  let qp = [(serialize-qp "filter[muted]" $filter_muted "scalar") (serialize-qp "filter[on_hold]" $filter_on_hold "scalar") (serialize-qp "filter[whispering]" $filter_whispering "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conference_id: (encode-path-segment $conference_id)} | format pattern "/conferences/{conference_id}/participants") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[muted]": $filter_muted, "filter[on_hold]": $filter_on_hold, "filter[whispering]": $filter_whispering, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Retrieve a conference
#
# GET /conferences/{id}
# operationId: retrieveConference
export def "conferences get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Dial a new participant into a conference
#
# POST /conferences/{id}/actions/dial_participant
# operationId: conferenceDialParticipantIn
export def "conferences-actions-dial-participant create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  call_control_id: string # Unique identifier and token for controlling the call (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQczRrZvZakpWxBlpw48KyZQ==)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --body-from: string # The `from` number to be used as the caller id presented to the destination (`to` number). (e.g. +18005550101)
  --hold: oneof<nothing, bool> # Whether the participant should be put on hold immediately after joining the conference. (default: false, e.g. true)
  --hold-audio-url: string # The URL of a file to be played to the participant when they are put on hold after joining the conference. If media_name is also supplied, this is currently ignored. Takes effect only when "start_conference_on_create" is set to "false". This property takes effect only if "hold" is set to "true". (e.g. http://example.com/message.wav)
  --hold-media-name: string # The media_name of a file to be played to the participant when they are put on hold after joining the conference. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. Takes effect only when "start_conference_on_create" is set to "false". This property takes effect only if "hold" is set to "true". (e.g. my_media_uploaded_to_media_storage_api)
  --mute: oneof<nothing, bool> # Whether the participant should be muted immediately after joining the conference. (default: false, e.g. false)
  --start-conference-on-enter: oneof<nothing, bool> # Whether the conference should be started after the participant joins the conference. (default: false, e.g. true)
  --supervisor-role: string@supervisor-role-completer # Sets the joining participant as a supervisor for the conference. A conference can have multiple supervisors. "barge" means the supervisor enters the conference as a normal participant. This is the same as "none". "monitor" means the supervisor is muted but can hear all participants. "whisper" means that only the specified "whisper_call_control_ids" can hear the supervisor. Defaults to "none". (e.g. whisper)
  --body-to: string # The DID or SIP URI to dial out and bridge to the given call. (e.g. +18005550100 or sip:username@sip.telnyx.com)
  --whisper-call-control-ids: list<string> # Array of unique call_control_ids the joining supervisor can whisper to. If none provided, the supervisor will join the conference as a monitoring participant only. (e.g. [v2:Sg1xxxQ_U3ixxxyXT_VDNI3xxxazZdg6Vxxxs4-GNYxxxVaJPOhFMRQ, v2:qqpb0mmvd-ovhhBr0BUQQn0fld5jIboaaX3-De0DkqXHzbf8d75xkw])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/dial_participant"))
  let req_body = {"call_control_id": $call_control_id, "client_state": $client_state, "command_id": $command_id, "from": $body_from, "hold": $hold, "hold_audio_url": $hold_audio_url, "hold_media_name": $hold_media_name, "mute": $mute, "start_conference_on_enter": $start_conference_on_enter, "supervisor_role": $supervisor_role, "to": $body_to, "whisper_call_control_ids": $whisper_call_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Hold conference participants
#
# POST /conferences/{id}/actions/hold
# operationId: conferenceHoldParticipants
export def "conferences-actions-hold create-participants" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-url: string # The URL of a file to be played to the participants when they are put on hold. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --call-control-ids: list<string> # List of unique identifiers and tokens for controlling the call. When empty all participants will be placed on hold.
  --media-name: string # The media_name of a file to be played to the participants when they are put on hold. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/hold"))
  let req_body = {"audio_url": $audio_url, "call_control_ids": $call_control_ids, "media_name": $media_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Join a conference
#
# POST /conferences/{id}/actions/join
# operationId: conferenceJoin
export def "conferences-actions-join create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beep-enabled: string@beep-enabled-completer # Whether a beep sound should be played when the participant joins and/or leaves the conference. Can be used to override the conference-level setting. (e.g. on_exit)
  call_control_id: string # Unique identifier and token for controlling the call (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQczRrZvZakpWxBlpw48KyZQ==)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  --end-conference-on-exit: oneof<nothing, bool> # Whether the conference should end and all remaining participants be hung up after the participant leaves the conference. Defaults to "false". (e.g. true)
  --hold: oneof<nothing, bool> # Whether the participant should be put on hold immediately after joining the conference. Defaults to "false". (e.g. true)
  --hold-audio-url: string # The URL of a file to be played to the participant when they are put on hold after joining the conference. hold_media_name and hold_audio_url cannot be used together in one request. Takes effect only when "start_conference_on_create" is set to "false". This property takes effect only if "hold" is set to "true". (e.g. http://example.com/message.wav)
  --hold-media-name: string # The media_name of a file to be played to the participant when they are put on hold after joining the conference. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. Takes effect only when "start_conference_on_create" is set to "false". This property takes effect only if "hold" is set to "true". (e.g. my_media_uploaded_to_media_storage_api)
  --mute: oneof<nothing, bool> # Whether the participant should be muted immediately after joining the conference. Defaults to "false". (e.g. true)
  --soft-end-conference-on-exit: oneof<nothing, bool> # Whether the conference should end after the participant leaves the conference. NOTE this doesn't hang up the other participants. Defaults to "false". (e.g. true)
  --start-conference-on-enter: oneof<nothing, bool> # Whether the conference should be started after the participant joins the conference. Defaults to "false". (e.g. true)
  --supervisor-role: string@supervisor-role-completer # Sets the joining participant as a supervisor for the conference. A conference can have multiple supervisors. "barge" means the supervisor enters the conference as a normal participant. This is the same as "none". "monitor" means the supervisor is muted but can hear all participants. "whisper" means that only the specified "whisper_call_control_ids" can hear the supervisor. Defaults to "none". (e.g. whisper)
  --whisper-call-control-ids: list<string> # Array of unique call_control_ids the joining supervisor can whisper to. If none provided, the supervisor will join the conference as a monitoring participant only. (e.g. [v2:Sg1xxxQ_U3ixxxyXT_VDNI3xxxazZdg6Vxxxs4-GNYxxxVaJPOhFMRQ, v2:qqpb0mmvd-ovhhBr0BUQQn0fld5jIboaaX3-De0DkqXHzbf8d75xkw])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/join"))
  let req_body = {"beep_enabled": $beep_enabled, "call_control_id": $call_control_id, "client_state": $client_state, "command_id": $command_id, "end_conference_on_exit": $end_conference_on_exit, "hold": $hold, "hold_audio_url": $hold_audio_url, "hold_media_name": $hold_media_name, "mute": $mute, "soft_end_conference_on_exit": $soft_end_conference_on_exit, "start_conference_on_enter": $start_conference_on_enter, "supervisor_role": $supervisor_role, "whisper_call_control_ids": $whisper_call_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Leave a conference
#
# POST /conferences/{id}/actions/leave
# operationId: conferenceLeave
export def "conferences-actions-leave create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --beep-enabled: string@beep-enabled-completer # Whether a beep sound should be played when the participant leaves the conference. Can be used to override the conference-level setting. (e.g. on_exit)
  call_control_id: string # Unique identifier and token for controlling the call (e.g. f91269aa-61d1-417f-97b3-10e020e8bc47)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/leave"))
  let req_body = {"beep_enabled": $beep_enabled, "call_control_id": $call_control_id, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Mute conference participants
#
# POST /conferences/{id}/actions/mute
# operationId: conferenceMuteParticipants
export def "conferences-actions-mute create-participants" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-control-ids: list<string> # Array of unique identifiers and tokens for controlling the call. When empty all participants will be muted.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/mute"))
  let req_body = {"call_control_ids": $call_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Play audio to conference participants
#
# POST /conferences/{id}/actions/play
# operationId: conferencePlayAudio
export def "conferences-actions-play create-audio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-url: string # The URL of a file to be played back in the conference. media_name and audio_url cannot be used together in one request. (e.g. http://example.com/message.wav)
  --call-control-ids: list<string> # List of call control ids identifying participants the audio file should be played to. If not given, the audio file will be played to the entire conference.
  --body-loop: any
  --media-name: string # The media_name of a file to be played back in the conference. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. The file must either be a WAV or MP3 file. (e.g. my_media_uploaded_to_media_storage_api)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/play"))
  let req_body = {"audio_url": $audio_url, "call_control_ids": $call_control_ids, "loop": $body_loop, "media_name": $media_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Conference recording start
#
# POST /conferences/{id}/actions/record_start
# operationId: conferenceStartRecording
export def "conferences-actions-record-start start-recording" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: string@channels-completer # When `dual`, final audio file will be stereo recorded with the first leg on channel A, and the rest on channel B. (e.g. single)
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  format: string@format-completer # The audio file format used when storing the call recording. Can be either `mp3` or `wav`. (e.g. mp3)
  --max-length: int # Defines the maximum length for the recording in seconds. Minimum value is 0. Maximum value is 14400. Default is 0 (infinite) (format: int32, default: 0, e.g. 100)
  --play-beep: oneof<nothing, bool> # If enabled, a beep sound will be played at the start of a recording. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/record_start"))
  let req_body = {"channels": $channels, "client_state": $client_state, "command_id": $command_id, "format": $format, "max_length": $max_length, "play_beep": $play_beep} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Conference recording stop
#
# POST /conferences/{id}/actions/record_stop
# operationId: conferenceStopRecording
export def "conferences-actions-record-stop stop-recording" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-state: string # Use this field to add state to every subsequent webhook. It must be a valid Base-64 encoded string. (e.g. aGF2ZSBhIG5pY2UgZGF5ID1d)
  --command-id: string # Use this field to avoid duplicate commands. Telnyx will ignore commands with the same `command_id`. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/record_stop"))
  let req_body = {"client_state": $client_state, "command_id": $command_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Speak text to conference participants
#
# POST /conferences/{id}/actions/speak
# operationId: conferenceSpeakText
export def "conferences-actions-speak create-text" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-control-ids: list<string> # Call Control IDs of participants who will hear the spoken text. When empty all participants will hear the spoken text.
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  language: string@language-completer # The language used to speak the text. (e.g. en-US)
  payload: string # The text or SSML to be converted into speech. There is a 5,000 character limit. (e.g. Say this to participants)
  --payload-type: string@payload-type-completer # The type of the provided payload. The payload can either be plain text, or Speech Synthesis Markup Language (SSML). (default: text, e.g. ssml)
  voice: string@voice-completer # The gender of the voice used to speak the text. (e.g. female)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/speak"))
  let req_body = {"call_control_ids": $call_control_ids, "command_id": $command_id, "language": $language, "payload": $payload, "payload_type": $payload_type, "voice": $voice} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Stop audio being played on the conference
#
# POST /conferences/{id}/actions/stop
# operationId: conferenceStopAudio
export def "conferences-actions-stop stop-audio" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-control-ids: list<string> # List of call control ids identifying participants the audio file should stop be played to. If not given, the audio will be stoped to the entire conference.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/stop"))
  let req_body = {"call_control_ids": $call_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unhold conference participants
#
# POST /conferences/{id}/actions/unhold
# operationId: conferenceUnholdParticipants
export def "conferences-actions-unhold create-participants" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  call_control_ids: list<string> # List of unique identifiers and tokens for controlling the call. Enter each call control ID to be unheld.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/unhold"))
  let req_body = {"call_control_ids": $call_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unmute conference participants
#
# POST /conferences/{id}/actions/unmute
# operationId: conferenceUnmuteParticipants
export def "conferences-actions-unmute create-participants" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-control-ids: list<string> # List of unique identifiers and tokens for controlling the call. Enter each call control ID to be unmuted. When empty all participants will be unmuted.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/unmute"))
  let req_body = {"call_control_ids": $call_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update conference participant
#
# POST /conferences/{id}/actions/update
# operationId: conferenceUpdate
export def "conferences-actions-update update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  call_control_id: string # Unique identifier and token for controlling the call (e.g. v2:T02llQxIyaRkhfRKxgAP8nY511EhFLizdvdUKJiSw8d6A9BborherQczRrZvZakpWxBlpw48KyZQ==)
  --command-id: string # Use this field to avoid execution of duplicate commands. Telnyx will ignore subsequent commands with the same `command_id` as one that has already been executed. (e.g. 891510ac-f3e4-11e8-af5b-de00688a4901)
  supervisor_role: string@supervisor-role-completer # Sets the participant as a supervisor for the conference. A conference can have multiple supervisors. "barge" means the supervisor enters the conference as a normal participant. This is the same as "none". "monitor" means the supervisor is muted but can hear all participants. "whisper" means that only the specified "whisper_call_control_ids" can hear the supervisor. Defaults to "none". (e.g. whisper)
  --whisper-call-control-ids: list<string> # Array of unique call_control_ids the supervisor can whisper to. If none provided, the supervisor will join the conference as a monitoring participant only. (e.g. [v2:Sg1xxxQ_U3ixxxyXT_VDNI3xxxazZdg6Vxxxs4-GNYxxxVaJPOhFMRQ, v2:qqpb0mmvd-ovhhBr0BUQQn0fld5jIboaaX3-De0DkqXHzbf8d75xkw])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/conferences/{id}/actions/update"))
  let req_body = {"call_control_id": $call_control_id, "command_id": $command_id, "supervisor_role": $supervisor_role, "whisper_call_control_ids": $whisper_call_control_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List connections
#
# GET /connections
# operationId: listConnections
export def "connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-name-contains: string # If present, connections with connection_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters.
  --filter-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --qp-sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[connection_name][contains]" $filter_connection_name_contains "scalar") (serialize-qp "filter[outbound_voice_profile_id]" $filter_outbound_voice_profile_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[connection_name][contains]": $filter_connection_name_contains, "filter[outbound_voice_profile_id]": $filter_outbound_voice_profile_id, "sort": $qp_sort} | compact), body: null}
}

# Retrieve a connection
#
# GET /connections/{id}
# operationId: retrieveConnection
export def "connections get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/connections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List credential connections
#
# GET /credential_connections
# operationId: listCredentialConnections
export def "credential-connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-name-contains: string # If present, connections with connection_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters.
  --filter-outbound-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --qp-sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[connection_name][contains]" $filter_connection_name_contains "scalar") (serialize-qp "filter[outbound.outbound_voice_profile_id]" $filter_outbound_outbound_voice_profile_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/credential_connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[connection_name][contains]": $filter_connection_name_contains, "filter[outbound.outbound_voice_profile_id]": $filter_outbound_outbound_voice_profile_id, "sort": $qp_sort} | compact), body: null}
}

# Create a credential connection
#
# POST /credential_connections
# operationId: createCredentialConnection
# --inbound shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, timeout_1xx_secs?: int, timeout_2xx_secs?: string}
# --outbound shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru"}
# --rtcp_settings shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
export def "credential-connections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  connection_name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: false)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: G722, default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, timeout_1xx_secs?: int, timeout_2xx_secs?: string}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false)
  --outbound: record # e.g. {ani_override: always, call_parking_enabled: true, channel_limit: 10, generate_ringback_tone: true, instant_ringback_enabled: true, localization: US, outbound_voice_profile_id: 1293384261075731499, t38_reinvite_source: telnyx} — shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru"}
  password: string # The password to be used as part of the credentials. Must be 8 to 128 characters long. (e.g. my123secure456password789)
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --sip-uri-calling-preference: string@sip-uri-calling-preference-completer # This feature enables inbound SIP URI calls to your Credential Auth Connection. If enabled for all (unrestricted) then anyone who calls the SIP URI <your-username>@telnyx.com will be connected to your Connection. You can also choose to allow only calls that are originated on any Connections under your account (internal). (default: disabled)
  user_name: string # The user name to be used as part of the credentials. Must be 4-32 characters long and alphanumeric values only (no spaces or special characters). (e.g. myusername123)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/credential_connections")
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "connection_name": $connection_name, "default_on_hold_comfort_noise_enabled": $default_on_hold_comfort_noise_enabled, "dtmf_type": $dtmf_type, "encode_contact_header_enabled": $encode_contact_header_enabled, "encrypted_media": $encrypted_media, "inbound": $inbound, "onnet_t38_passthrough_enabled": $onnet_t38_passthrough_enabled, "outbound": $outbound, "password": $password, "rtcp_settings": $rtcp_settings, "sip_uri_calling_preference": $sip_uri_calling_preference, "user_name": $user_name, "webhook_api_version": $webhook_api_version, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a credential connection
#
# DELETE /credential_connections/{id}
# operationId: deleteCredentialConnection
export def "credential-connections delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/credential_connections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a credential connection
#
# GET /credential_connections/{id}
# operationId: retrieveCredentialConnection
export def "credential-connections get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/credential_connections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a credential connection
#
# PATCH /credential_connections/{id}
# operationId: updateCredentialConnection
# --inbound shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, timeout_1xx_secs?: int, timeout_2xx_secs?: string}
# --outbound shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru"}
# --rtcp_settings shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
export def "credential-connections update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --connection-name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: false)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: G722, default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, timeout_1xx_secs?: int, timeout_2xx_secs?: string}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false)
  --outbound: record # e.g. {ani_override: always, call_parking_enabled: true, channel_limit: 10, generate_ringback_tone: true, instant_ringback_enabled: true, localization: US, outbound_voice_profile_id: 1293384261075731499, t38_reinvite_source: telnyx} — shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru"}
  --password: string # The password to be used as part of the credentials. Must be 8 to 128 characters long. (e.g. my123secure456password789)
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --sip-uri-calling-preference: string@sip-uri-calling-preference-completer # This feature enables inbound SIP URI calls to your Credential Auth Connection. If enabled for all (unrestricted) then anyone who calls the SIP URI <your-username>@telnyx.com will be connected to your Connection. You can also choose to allow only calls that are originated on any Connections under your account (internal). (default: disabled)
  --user-name: string # The user name to be used as part of the credentials. Must be 4-32 characters long and alphanumeric values only (no spaces or special characters). (e.g. myusername123)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/credential_connections/{id}"))
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "connection_name": $connection_name, "default_on_hold_comfort_noise_enabled": $default_on_hold_comfort_noise_enabled, "dtmf_type": $dtmf_type, "encode_contact_header_enabled": $encode_contact_header_enabled, "encrypted_media": $encrypted_media, "inbound": $inbound, "onnet_t38_passthrough_enabled": $onnet_t38_passthrough_enabled, "outbound": $outbound, "password": $password, "rtcp_settings": $rtcp_settings, "sip_uri_calling_preference": $sip_uri_calling_preference, "user_name": $user_name, "webhook_api_version": $webhook_api_version, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search detail records
#
# GET /detail_records
# operationId: DetailRecordsSearch
export def "detail-records list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-record-type: string # Filter by the given record type
  --filter-date-range: string # Filter by the given user-friendly date range
  --filter: record # Filter records
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Page size (format: int32, default: 20)
  --qp-sort: list<string> # Specifies the sort order for results
]: nothing -> record<data: list<record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[record_type]" $filter_record_type "scalar") (serialize-qp "filter[date_range]" $filter_date_range "scalar") (serialize-qp "filter" $filter "multi") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/detail_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[record_type]": $filter_record_type, "filter[date_range]": $filter_date_range, "filter": $filter, "page[number]": $page_number, "page[size]": $page_size, "sort": $qp_sort} | compact), body: null}
}

# List all document links
#
# GET /document_links
# operationId: listDocumentLinks
export def "document-links list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-document-id: string # Identifies the associated document to filter on. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --filter-linked-record-type: string # The `linked_record_type` of the document to filter on. (e.g. porting_order)
  --filter-linked-resource-id: string # The `linked_resource_id` of the document to filter on. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[document_id]" $filter_document_id "scalar") (serialize-qp "filter[linked_record_type]" $filter_linked_record_type "scalar") (serialize-qp "filter[linked_resource_id]" $filter_linked_resource_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/document_links" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[document_id]": $filter_document_id, "filter[linked_record_type]": $filter_linked_record_type, "filter[linked_resource_id]": $filter_linked_resource_id} | compact), body: null}
}

# List all documents
#
# GET /documents
# operationId: listDocuments
export def "documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Upload a document
#
# POST /documents
# operationId: createDocument
export def "documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # If the file is already hosted publicly, you can provide a URL and have the documents service fetch it for you. (e.g. https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf)
  --file: string # The Base64 encoded contents of the file you are uploading. (format: byte, e.g. [Base64 encoded content])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents")
  let req_body = {"url": $url, "file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a document
#
# DELETE /documents/{id}
# operationId: deleteDocument
export def "documents delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a document
#
# GET /documents/{id}
# operationId: retrieveDocument
export def "documents get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a document
#
# PATCH /documents/{id}
# operationId: updateDocument
export def "documents update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filename: string # The filename of the document. (e.g. test-document.pdf)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}"))
  let req_body = {"filename": $filename} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download a document
#
# GET /documents/{id}/download
# operationId: downloadDocServiceDocument
export def "documents-download download-doc-service" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all Fax Applications
#
# GET /fax_applications
# operationId: listFaxApplications
export def "fax-applications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-application-name-contains: string # If present, applications with application_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --qp-sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[application_name][contains]" $filter_application_name_contains "scalar") (serialize-qp "filter[outbound_voice_profile_id]" $filter_outbound_voice_profile_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fax_applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[application_name][contains]": $filter_application_name_contains, "filter[outbound_voice_profile_id]": $filter_outbound_voice_profile_id, "sort": $qp_sort} | compact), body: null}
}

# Creates a Fax Application
#
# POST /fax_applications
# operationId: CreateFaxApplication
# --inbound shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
# --outbound shape: {channel_limit?: int, outbound_voice_profile_id?: string}
export def "fax-applications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true, e.g. false)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  application_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  webhook_event_url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fax_applications")
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "application_name": $application_name, "inbound": $inbound, "outbound": $outbound, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a Fax Application
#
# DELETE /fax_applications/{id}
# operationId: DeleteFaxApplication
export def "fax-applications delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fax_applications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a Fax Application
#
# GET /fax_applications/{id}
# operationId: getFaxApplication
export def "fax-applications get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fax_applications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Fax Application
#
# PATCH /fax_applications/{id}
# operationId: UpdateFaxApplication
# --inbound shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
# --outbound shape: {channel_limit?: int, outbound_voice_profile_id?: string}
export def "fax-applications update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true, e.g. false)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  application_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  webhook_event_url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fax_applications/{id}"))
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "application_name": $application_name, "inbound": $inbound, "outbound": $outbound, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View a list of faxes
#
# GET /faxes
# operationId: ListFaxes
export def "faxes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-created-at-gte: string # ISO 8601 date time for filtering faxes created after or on that date (format: date-time, e.g. 2020-02-02T22:25:27.521992Z)
  --filter-created-at-gt: string # ISO 8601 date time for filtering faxes created after that date (format: date-time, e.g. 2020-02-02T22:25:27.521992Z)
  --filter-created-at-lte: string # ISO 8601 formatted date time for filtering faxes created on or before that date (format: date-time, e.g. 2020-02-02T22:25:27.521992Z)
  --filter-created-at-lt: string # ISO 8601 formatted date time for filtering faxes created before that date (format: date-time, e.g. 2020-02-02T22:25:27.521992Z)
  --filter-direction-eq: string # The direction, inbound or outbound, for filtering faxes sent from this account (e.g. inbound)
  --filter-from-eq: string # The phone number, in E.164 format for filtering faxes sent from this number (e.g. +13127367276)
  --page-size: int # Number of fax resourcxes for the single page returned (e.g. 2)
  --page-number: int # Number of the page to be retrieved (e.g. 2)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[created_at][gte]" $filter_created_at_gte "scalar") (serialize-qp "filter[created_at][gt]" $filter_created_at_gt "scalar") (serialize-qp "filter[created_at][lte]" $filter_created_at_lte "scalar") (serialize-qp "filter[created_at][lt]" $filter_created_at_lt "scalar") (serialize-qp "filter[direction][eq]" $filter_direction_eq "scalar") (serialize-qp "filter[from][eq]" $filter_from_eq "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[number]" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/faxes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[created_at][gte]": $filter_created_at_gte, "filter[created_at][gt]": $filter_created_at_gt, "filter[created_at][lte]": $filter_created_at_lte, "filter[created_at][lt]": $filter_created_at_lt, "filter[direction][eq]": $filter_direction_eq, "filter[from][eq]": $filter_from_eq, "page[size]": $page_size, "page[number]": $page_number} | compact), body: null}
}

# Send a fax
#
# POST /faxes
# operationId: SendFax
export def "faxes send-fax" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # The connection ID to send the fax with. (e.g. 234423)
  --body-from: string # The phone number, in E.164 format, the fax will be sent from. (e.g. +13125790015)
  --media-name: string # The media_name of a file to be used for the fax's media. The media_name must point to a file previously uploaded to api.telnyx.com/v2/media by the same user/organization. media_url and media_name can't be submitted together. (e.g. my_media_uploaded_to_media_storage_api)
  --media-url: string # The URL to the PDF used for the fax's media. media_url and media_name can't be submitted together. (e.g. https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf)
  --quality: string # The quality of the fax. Can be normal, high, very_high. (default: high, e.g. high)
  --store-media: oneof<nothing, bool> # Should fax media be stored on temporary URL. It does not support media_name, they can't be submitted together. (default: false)
  --body-to: string # The phone number, in E.164 format, the fax will be sent to or SIP URI. (e.g. +13127367276)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/faxes")
  let req_body = {"connection_id": $connection_id, "from": $body_from, "media_name": $media_name, "media_url": $media_url, "quality": $quality, "store_media": $store_media, "to": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a fax
#
# DELETE /faxes/{id}
# operationId: DeleteFax
export def "faxes delete-fax" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/faxes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a fax
#
# GET /faxes/{id}
# operationId: ViewFax
export def "faxes get-view-fax" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/faxes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Refresh a fax
#
# POST /faxes/{id}/actions/refresh
# operationId: RefreshFax
export def "faxes-actions-refresh refresh-fax" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/faxes/{id}/actions/refresh"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List FQDN connections
#
# GET /fqdn_connections
# operationId: listFqdnConnections
export def "fqdn-connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-name-contains: string # If present, connections with connection_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters.
  --qp-sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[connection_name][contains]" $filter_connection_name_contains "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fqdn_connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[connection_name][contains]": $filter_connection_name_contains, "sort": $qp_sort} | compact), body: null}
}

# Create an FQDN connection
#
# POST /fqdn_connections
# operationId: createFqdnConnection
# --inbound shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
# --rtcp_settings shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
export def "fqdn-connections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true (default: true)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  connection_name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: true)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: [G722], default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, sip_region: US, sip_subdomain: test, sip_subdomain_receive_settings: only_my_connections, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false)
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --transport-protocol: string@transport-protocol-completer # One of UDP, TLS, or TCP. Applies only to connections with IP authentication or FQDN authentication. (default: UDP)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fqdn_connections")
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "connection_name": $connection_name, "default_on_hold_comfort_noise_enabled": $default_on_hold_comfort_noise_enabled, "dtmf_type": $dtmf_type, "encode_contact_header_enabled": $encode_contact_header_enabled, "encrypted_media": $encrypted_media, "inbound": $inbound, "onnet_t38_passthrough_enabled": $onnet_t38_passthrough_enabled, "rtcp_settings": $rtcp_settings, "transport_protocol": $transport_protocol, "webhook_api_version": $webhook_api_version, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an FQDN connection
#
# DELETE /fqdn_connections/{id}
# operationId: deleteFqdnConnection
export def "fqdn-connections delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fqdn_connections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an FQDN connection
#
# GET /fqdn_connections/{id}
# operationId: retrieveFqdnConnection
export def "fqdn-connections get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fqdn_connections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an FQDN connection
#
# PATCH /fqdn_connections/{id}
# operationId: updateFqdnConnection
# --inbound shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
# --rtcp_settings shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
export def "fqdn-connections update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --connection-name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: true)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: [G722], default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, sip_region: US, sip_subdomain: test, sip_subdomain_receive_settings: only_my_connections, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer that the sender and receiver negotiate T38 directly when both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call according to each leg's settings. (default: false)
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --transport-protocol: string@transport-protocol-completer # One of UDP, TLS, or TCP. Applies only to connections with IP authentication or FQDN authentication. (default: UDP)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fqdn_connections/{id}"))
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "connection_name": $connection_name, "default_on_hold_comfort_noise_enabled": $default_on_hold_comfort_noise_enabled, "dtmf_type": $dtmf_type, "encode_contact_header_enabled": $encode_contact_header_enabled, "encrypted_media": $encrypted_media, "inbound": $inbound, "onnet_t38_passthrough_enabled": $onnet_t38_passthrough_enabled, "rtcp_settings": $rtcp_settings, "transport_protocol": $transport_protocol, "webhook_api_version": $webhook_api_version, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List FQDNs
#
# GET /fqdns
# operationId: listFqdns
export def "fqdns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-id: string # ID of the FQDN connection to which the FQDN belongs.
  --filter-fqdn: string # FQDN represented by the resource. (e.g. example.com)
  --filter-port: int # Port to use when connecting to the FQDN. (e.g. 5060)
  --filter-dns-record-type: string # DNS record type used by the FQDN. (e.g. a)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[connection_id]" $filter_connection_id "scalar") (serialize-qp "filter[fqdn]" $filter_fqdn "scalar") (serialize-qp "filter[port]" $filter_port "scalar") (serialize-qp "filter[dns_record_type]" $filter_dns_record_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fqdns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[connection_id]": $filter_connection_id, "filter[fqdn]": $filter_fqdn, "filter[port]": $filter_port, "filter[dns_record_type]": $filter_dns_record_type} | compact), body: null}
}

# Create an FQDN
#
# POST /fqdns
# operationId: createFqdn
export def "fqdns create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # ID of the FQDN connection to which this IP should be attached.
  dns_record_type: string # The DNS record type for the FQDN. For cases where a port is not set, the DNS record type must be 'srv'. For cases where a port is set, the DNS record type must be 'a'. If the DNS record type is 'a' and a port is not specified, 5060 will be used. (e.g. a)
  fqdn: string # FQDN represented by this resource. (e.g. example.com)
  --port: int # Port to use when connecting to this FQDN. (nullable, default: 5060, e.g. 5060)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/fqdns")
  let req_body = {"connection_id": $connection_id, "dns_record_type": $dns_record_type, "fqdn": $fqdn, "port": $port} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an FQDN
#
# DELETE /fqdns/{id}
# operationId: deleteFqdn
export def "fqdns delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fqdns/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an FQDN
#
# GET /fqdns/{id}
# operationId: retrieveFqdn
export def "fqdns get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fqdns/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an FQDN
#
# PATCH /fqdns/{id}
# operationId: updateFqdn
export def "fqdns update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # ID of the FQDN connection to which this IP should be attached.
  --dns-record-type: string # The DNS record type for the FQDN. For cases where a port is not set, the DNS record type must be 'srv'. For cases where a port is set, the DNS record type must be 'a'. If the DNS record type is 'a' and a port is not specified, 5060 will be used. (e.g. a)
  --fqdn: string # FQDN represented by this resource. (e.g. example.com)
  --port: int # Port to use when connecting to this FQDN. (nullable, default: 5060, e.g. 5060)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/fqdns/{id}"))
  let req_body = {"connection_id": $connection_id, "dns_record_type": $dns_record_type, "fqdn": $fqdn, "port": $port} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create an inventory coverage request
#
# GET /inventory_coverage
# operationId: createInventoryCoverageRequest
export def "inventory-coverage create-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-npa: int # e.g. 318
  --filter-nxx: int # e.g. 202
  --filter-administrative-area: string # e.g. LA
  --filter-number-type: string@filter-number-type-completer-2 # e.g. did
  --filter-phone-number-type: string@filter-phone-number-type-completer # e.g. local
  --filter-country-code: string@filter-country-code-completer # e.g. US
  --filter-count: oneof<nothing, bool> # e.g. true
  --filter-group-by: string@filter-group-by-completer # e.g. nxx
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[npa]" $filter_npa "scalar") (serialize-qp "filter[nxx]" $filter_nxx "scalar") (serialize-qp "filter[administrative_area]" $filter_administrative_area "scalar") (serialize-qp "filter[number_type]" $filter_number_type "scalar") (serialize-qp "filter[phone_number_type]" $filter_phone_number_type "scalar") (serialize-qp "filter[country_code]" $filter_country_code "scalar") (serialize-qp "filter[count]" $filter_count "scalar") (serialize-qp "filter[groupBy]" $filter_group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/inventory_coverage" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[npa]": $filter_npa, "filter[nxx]": $filter_nxx, "filter[administrative_area]": $filter_administrative_area, "filter[number_type]": $filter_number_type, "filter[phone_number_type]": $filter_phone_number_type, "filter[country_code]": $filter_country_code, "filter[count]": $filter_count, "filter[groupBy]": $filter_group_by} | compact), body: null}
}

# List Ip connections
#
# GET /ip_connections
# operationId: listIpConnections
export def "ip-connections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-name-contains: string # If present, connections with connection_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters.
  --filter-outbound-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --qp-sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[connection_name][contains]" $filter_connection_name_contains "scalar") (serialize-qp "filter[outbound.outbound_voice_profile_id]" $filter_outbound_outbound_voice_profile_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ip_connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[connection_name][contains]": $filter_connection_name_contains, "filter[outbound.outbound_voice_profile_id]": $filter_outbound_outbound_voice_profile_id, "sort": $qp_sort} | compact), body: null}
}

# Create an Ip connection
#
# POST /ip_connections
# operationId: createIpConnection
# --inbound shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
# --outbound shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, ip_authentication_method?: "tech-prefixp-charge-info"|"token", ip_authentication_token?: string, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru", tech_prefix?: string}
# --rtcp_settings shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
export def "ip-connections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true (e.g. true)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --connection-name: string # e.g. string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: true, e.g. true)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false, e.g. true)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: G722, default_routing_method: sequential, dnis_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, sip_region: US, sip_subdomain: test, sip_subdomain_receive_settings: only_my_connections, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_routing_method?: "sequential"|"round-robin", dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, sip_region?: "US"|"Europe"|"Australia", sip_subdomain?: string, ... (3 more fields)}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false, e.g. false)
  --outbound: record # e.g. {ani_override: string, ani_override_type: always, call_parking_enabled: true, channel_limit: 10, generate_ringback_tone: true, instant_ringback_enabled: true, ip_authentication_method: token, ip_authentication_token: string, localization: string, outbound_voice_profile_id: 1293384261075731499, t38_reinvite_source: telnyx, tech_prefix: string} — shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, ip_authentication_method?: "tech-prefixp-charge-info"|"token", ip_authentication_token?: string, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru", tech_prefix?: string}
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --transport-protocol: string@transport-protocol-completer # One of UDP, TLS, or TCP. Applies only to connections with IP authentication or FQDN authentication. (default: UDP, e.g. UDP)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ip_connections")
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "connection_name": $connection_name, "default_on_hold_comfort_noise_enabled": $default_on_hold_comfort_noise_enabled, "dtmf_type": $dtmf_type, "encode_contact_header_enabled": $encode_contact_header_enabled, "encrypted_media": $encrypted_media, "inbound": $inbound, "onnet_t38_passthrough_enabled": $onnet_t38_passthrough_enabled, "outbound": $outbound, "rtcp_settings": $rtcp_settings, "transport_protocol": $transport_protocol, "webhook_api_version": $webhook_api_version, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an Ip connection
#
# DELETE /ip_connections/{id}
# operationId: deleteIpConnection
export def "ip-connections delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ip_connections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an Ip connection
#
# GET /ip_connections/{id}
# operationId: retrieveIpConnection
export def "ip-connections get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ip_connections/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an Ip connection
#
# PATCH /ip_connections/{id}
# operationId: updateIpConnection
# --inbound shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_primary_ip_id?: string, default_routing_method?: "sequential"|"round-robin", default_secondary_ip_id?: string, default_tertiary_ip_id?: string, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, ... (5 more fields)}
# --outbound shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, ip_authentication_method?: "tech-prefixp-charge-info"|"token", ip_authentication_token?: string, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru", tech_prefix?: string}
# --rtcp_settings shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
export def "ip-connections update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Defaults to true
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --connection-name: string
  --default-on-hold-comfort-noise-enabled: oneof<nothing, bool> # When enabled, Telnyx will generate comfort noise when you place the call on hold. If disabled, you will need to generate comfort noise or on hold music to avoid RTP timeout. (default: true)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --encode-contact-header-enabled: oneof<nothing, bool> # Encode the SIP contact header sent by Telnyx to avoid issues for NAT or ALG scenarios. (default: false)
  --encrypted-media: string@encrypted-media-completer # Enable use of SRTP or ZRTP for encryption. Valid values are those listed or null. Cannot be set to non-null if the transport_portocol is TLS. (nullable, e.g. SRTP)
  --inbound: record # e.g. {ani_number_format: +E.164, channel_limit: 10, codecs: G722, default_primary_ip_id: 192.168.0.0, default_routing_method: sequential, default_secondary_ip_id: 192.168.0.0, default_tertiary_ip_id: 192.168.0.0, dns_number_format: +e164, generate_ringback_tone: true, isup_headers_enabled: true, prack_enabled: true, privacy_zone_enabled: true, sip_compact_headers_enabled: true, sip_region: US, sip_subdomain: test, sip_subdomain_receive_settings: only_my_connections, timeout_1xx_secs: 10, timeout_2xx_secs: 20} — shape: {ani_number_format?: "+E.164"|"E.164"|"+E.164-national"|"E.164-national", channel_limit?: int, codecs?: list<string>, default_primary_ip_id?: string, default_routing_method?: "sequential"|"round-robin", default_secondary_ip_id?: string, default_tertiary_ip_id?: string, dnis_number_format?: "+e164"|"e164"|"national"|"sip_username", generate_ringback_tone?: bool, isup_headers_enabled?: bool, prack_enabled?: bool, privacy_zone_enabled?: bool, sip_compact_headers_enabled?: bool, ... (5 more fields)}
  --onnet-t38-passthrough-enabled: oneof<nothing, bool> # Enable on-net T38 if you prefer the sender and receiver negotiating T38 directly if both are on the Telnyx network. If this is disabled, Telnyx will be able to use T38 on just one leg of the call depending on each leg's settings. (default: false)
  --outbound: record # e.g. {ani_override: string, ani_override_type: always, call_parking_enabled: true, channel_limit: 10, generate_ringback_tone: true, instant_ringback_enabled: true, ip_authentication_method: token, ip_authentication_token: string, localization: string, outbound_voice_profile_id: 1293384261075731499, t38_reinvite_source: telnyx, tech_prefix: string} — shape: {ani_override?: string, ani_override_type?: "always"|"normal"|"emergency", call_parking_enabled?: bool, channel_limit?: int, generate_ringback_tone?: bool, instant_ringback_enabled?: bool, ip_authentication_method?: "tech-prefixp-charge-info"|"token", ip_authentication_token?: string, localization?: string, outbound_voice_profile_id?: string, t38_reinvite_source?: "telnyx"|"customer"|"disabled"|"passthru"|"caller-passthru"|"callee-passthru", tech_prefix?: string}
  --rtcp-settings: record # e.g. {capture_enabled: true, port: rtcp-mux, report_frequency_secs: 10} — shape: {capture_enabled?: bool, port?: "rtcp-mux"|"rtp+1", report_frequency_secs?: int}
  --transport-protocol: string@transport-protocol-completer # One of UDP, TLS, or TCP. Applies only to connections with IP authentication or FQDN authentication. (default: UDP)
  --webhook-api-version: string@webhook-api-version-completer # Determines which webhook format will be used, Telnyx API v1 or v2. (default: 1, e.g. 1)
  --webhook-event-failover-url: string # The failover URL where webhooks related to this connection will be sent if sending to the primary URL fails. Must include a scheme, such as 'https'. (nullable, format: url, default: , e.g. https://failover.example.com)
  --webhook-event-url: string # The URL where webhooks related to this connection will be sent. Must include a scheme, such as 'https'. (format: url, e.g. https://example.com)
  --webhook-timeout-secs: int # Specifies how many seconds to wait before timing out a webhook. (nullable, e.g. 25)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ip_connections/{id}"))
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "connection_name": $connection_name, "default_on_hold_comfort_noise_enabled": $default_on_hold_comfort_noise_enabled, "dtmf_type": $dtmf_type, "encode_contact_header_enabled": $encode_contact_header_enabled, "encrypted_media": $encrypted_media, "inbound": $inbound, "onnet_t38_passthrough_enabled": $onnet_t38_passthrough_enabled, "outbound": $outbound, "rtcp_settings": $rtcp_settings, "transport_protocol": $transport_protocol, "webhook_api_version": $webhook_api_version, "webhook_event_failover_url": $webhook_event_failover_url, "webhook_event_url": $webhook_event_url, "webhook_timeout_secs": $webhook_timeout_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List Ips
#
# GET /ips
# operationId: listIps
export def "ips list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-connection-id: string # ID of the IP Connection to which this IP should be attached.
  --filter-ip-address: string # IP adddress represented by this resource. (e.g. 192.168.0.0)
  --filter-port: int # Port to use when connecting to this IP. (e.g. 5060)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[connection_id]" $filter_connection_id "scalar") (serialize-qp "filter[ip_address]" $filter_ip_address "scalar") (serialize-qp "filter[port]" $filter_port "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[connection_id]": $filter_connection_id, "filter[ip_address]": $filter_ip_address, "filter[port]": $filter_port} | compact), body: null}
}

# Create an Ip
#
# POST /ips
# operationId: createIp
export def "ips create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # ID of the IP Connection to which this IP should be attached.
  ip_address: string # IP adddress represented by this resource. (e.g. 192.168.0.0)
  --port: int # Port to use when connecting to this IP. (default: 5060, e.g. 5060)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ips")
  let req_body = {"connection_id": $connection_id, "ip_address": $ip_address, "port": $port} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an Ip
#
# DELETE /ips/{id}
# operationId: deleteIp
export def "ips delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ips/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an Ip
#
# GET /ips/{id}
# operationId: retrieveIp
export def "ips get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ips/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an Ip
#
# PATCH /ips/{id}
# operationId: updateIp
export def "ips update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # ID of the IP Connection to which this IP should be attached.
  ip_address: string # IP adddress represented by this resource. (e.g. 192.168.0.0)
  --port: int # Port to use when connecting to this IP. (default: 5060, e.g. 5060)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ips/{id}"))
  let req_body = {"connection_id": $connection_id, "ip_address": $ip_address, "port": $port} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a ledger billing group report
#
# POST /ledger_billing_group_reports
# operationId: createLedgerBillingGroupReport
export def "ledger-billing-group-reports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --month: int # Month of the ledger billing group report (e.g. 10)
  --year: int # Year of the ledger billing group report (e.g. 2019)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ledger_billing_group_reports")
  let req_body = {"month": $month, "year": $year} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a ledger billing group report
#
# GET /ledger_billing_group_reports/{id}
# operationId: retrieveLedgerBillingGroupReport
export def "ledger-billing-group-reports get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ledger_billing_group_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lists accounts managed by the current user.
#
# GET /managed_accounts
# operationId: listManagedAccounts
export def "managed-accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-email-contains: string # If present, email containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-email-eq: string # If present, only returns results with the email matching exactly the value given. (default: null)
  --qp-sort: string@sort-completer-3 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: email: sorts the result by the email field in ascending order. -email: sorts the result by the email field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. email)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[email][contains]" $filter_email_contains "scalar") (serialize-qp "filter[email][eq]" $filter_email_eq "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/managed_accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[email][contains]": $filter_email_contains, "filter[email][eq]": $filter_email_eq, "sort": $qp_sort} | compact), body: null}
}

# Create a new managed account.
#
# POST /managed_accounts
# operationId: createManagedAccount
export def "managed-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  business_name: string # The name of the business for which the new managed account is being created, that will be used as the managed accounts's organization's name. (e.g. Larry's Cat Food Inc)
  --email: string # The email address for the managed account. If not provided, the email address will be generated based on the email address of the manager account. (e.g. new_managed_account@customer.org)
  --password: string # Password for the managed account. If a password is not supplied, the account will not be able to be signed into directly. (A password reset may still be performed later to enable sign-in via password.) (e.g. 3jVjLq!tMuWKyWx4NN*CvhnB)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/managed_accounts")
  let req_body = {"business_name": $business_name, "email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a managed account
#
# GET /managed_accounts/{id}
# operationId: retrieveManagedAccount
export def "managed-accounts get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/managed_accounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Disables a managed account
#
# POST /managed_accounts/{id}/actions/disable
# operationId: disableManagedAccount
export def "managed-accounts-actions-disable disable" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/managed_accounts/{id}/actions/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Enables a managed account
#
# POST /managed_accounts/{id}/actions/enable
# operationId: enableManagedAccount
export def "managed-accounts-actions-enable enable" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/managed_accounts/{id}/actions/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List uploaded media
#
# GET /media
# operationId: listMedia
export def "media list" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/media")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload media
#
# POST /media
# operationId: createMedia
export def "media create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --media-name: string # The unique identifier of a file. (e.g. my_file)
  media_url: string # The URL where the media to be stored in Telnyx network is currently hosted. The maximum allowed size is 20 MB. (e.g. http://www.example.com/audio.mp3)
  --ttl-secs: int # The number of seconds after which the media resource will be deleted, defaults to 2 days. (e.g. 86400)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/media")
  let req_body = {"media_name": $media_name, "media_url": $media_url, "ttl_secs": $ttl_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes stored media
#
# DELETE /media/{media_name}
# operationId: deleteMedia
export def "media delete" [
  media_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_name | is-empty) { error make --unspanned { msg: "path parameter 'media_name' must be non-empty" } }
  let full_url = (build-url $base ({media_name: (encode-path-segment $media_name)} | format pattern "/media/{media_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve stored media
#
# GET /media/{media_name}
# operationId: getMedia
export def "media get" [
  media_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_name | is-empty) { error make --unspanned { msg: "path parameter 'media_name' must be non-empty" } }
  let full_url = (build-url $base ({media_name: (encode-path-segment $media_name)} | format pattern "/media/{media_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update stored media
#
# PUT /media/{media_name}
# operationId: updateMedia
export def "media update" [
  media_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --media-url: string # The URL where the media to be stored in Telnyx network is currently hosted. The maximum allowed size is 20 MB. (e.g. http://www.example.com/audio.mp3)
  --ttl-secs: int # The number of seconds after which the media resource will be deleted, defaults to 2 days. (e.g. 86400)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_name | is-empty) { error make --unspanned { msg: "path parameter 'media_name' must be non-empty" } }
  let full_url = (build-url $base ({media_name: (encode-path-segment $media_name)} | format pattern "/media/{media_name}"))
  let req_body = {"media_url": $media_url, "ttl_secs": $ttl_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download stored media
#
# GET /media/{media_name}/download
# operationId: downloadMedia
export def "media-download download" [
  media_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($media_name | is-empty) { error make --unspanned { msg: "path parameter 'media_name' must be non-empty" } }
  let full_url = (build-url $base ({media_name: (encode-path-segment $media_name)} | format pattern "/media/{media_name}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch messaging detail records.
#
# GET /message_detail_records
# operationId: getPaginatedMdrs
export def "message-detail-records get-paginated-mdrs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date (format: date-time, e.g. 2020-07-01T00:00:00-06:00)
  --end-date: string # End date (format: date-time, e.g. 2020-07-01T00:00:00-06:00)
  --id: string # e.g. e093fbe0-5bde-11eb-ae93-0242ac130002
  --direction: string@direction-completer
  --outbound-profile-id: string # e.g. 30ef55db-c4a2-4c4a-9804-a68077973d07
  --cld: string # e.g. +15551237654
  --cli: string # e.g. +15551237654
  --status: string@status-completer-1 # e.g. DELIVERED
  --message-type: string@message-type-completer # default: text
  --country-iso: string # e.g. US
  --qp-error: string # e.g. 40001
  --normalized-carrier: string # e.g. Verizon
  --tag: string # e.g. Tag1
  --mcc: string # e.g. 204
  --mnc: string # e.g. 01
  --product: string@product-completer # e.g. LONG_CODE
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
  --qp-sort: list<string> # default: created_at, e.g. created_at
]: nothing -> record<data: table<cld: string, cli: string, cost: string, created_at: string, currency: string, direction: string, id: string, message_type: string, parts: float, profile_name: string, rate: string, record_type: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "outbound_profile_id" $outbound_profile_id "scalar") (serialize-qp "cld" $cld "scalar") (serialize-qp "cli" $cli "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "message_type" $message_type "scalar") (serialize-qp "country_iso" $country_iso "scalar") (serialize-qp "error" $qp_error "scalar") (serialize-qp "normalized_carrier" $normalized_carrier "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "mcc" $mcc "scalar") (serialize-qp "mnc" $mnc "scalar") (serialize-qp "product" $product "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/message_detail_records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "id": $id, "direction": $direction, "outbound_profile_id": $outbound_profile_id, "cld": $cld, "cli": $cli, "status": $status, "message_type": $message_type, "country_iso": $country_iso, "error": $qp_error, "normalized_carrier": $normalized_carrier, "tag": $tag, "mcc": $mcc, "mnc": $mnc, "product": $product, "page[number]": $page_number, "page[size]": $page_size, "sort": $qp_sort} | compact), body: null}
}

# Fetch message body by id.
#
# GET /message_detail_records/{id}/message_body
# operationId: getMdrMessageBody
export def "message-detail-records-message-body get-mdr" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<message_body: string, record_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/message_detail_records/{id}/message_body"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send a message
#
# POST /messages
# operationId: createMessage
export def "messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-detect: oneof<nothing, bool> # Automatically detect if an SMS message is unusually long and exceeds a recommended limit of message parts. (default: false)
  --body-from: string # Sending address (+E.164 formatted phone number, alphanumeric sender ID, or short code). **Required if sending with a phone number, short code, or alphanumeric sender ID.** (format: address)
  --media-urls: list<string> # A list of media URLs. The total media size must be less than 1 MB. **Required for MMS**
  --messaging-profile-id: string # Unique identifier for a messaging profile. **Required if sending via number pool or with an alphanumeric sender ID.**
  --subject: string # Subject of multimedia message
  --text: string # Message body (i.e., content) as a non-empty string. **Required for SMS**
  --body-to: string # Receiving address (+E.164 formatted phone number or short code). (format: address, e.g. +E.164)
  --type: string@type-completer # The protocol for sending the message, either SMS or MMS.
  --use-profile-webhooks: oneof<nothing, bool> # If the profile this number is associated with has webhooks, use them for delivery notifications. If webhooks are also specified on the message itself, they will be attempted first, then those on the profile. (default: true)
  --webhook-failover-url: string # The failover URL where webhooks related to this message will be sent if sending to the primary URL fails. (format: url)
  --webhook-url: string # The URL where webhooks related to this message will be sent. (format: url)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages")
  let req_body = {"auto_detect": $auto_detect, "from": $body_from, "media_urls": $media_urls, "messaging_profile_id": $messaging_profile_id, "subject": $subject, "text": $text, "to": $body_to, "type": $type, "use_profile_webhooks": $use_profile_webhooks, "webhook_failover_url": $webhook_failover_url, "webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send a long code message
#
# POST /messages/long_code
# operationId: createLongCodeMessage
export def "messages-long-code create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-detect: oneof<nothing, bool> # Automatically detect if an SMS message is unusually long and exceeds a recommended limit of message parts. (default: false)
  --body-from: string # Phone number, in +E.164 format, used to send the message. (format: address)
  --media-urls: list<string> # A list of media URLs. The total media size must be less than 1 MB. **Required for MMS**
  --subject: string # Subject of multimedia message
  --text: string # Message body (i.e., content) as a non-empty string. **Required for SMS**
  --body-to: string # Receiving address (+E.164 formatted phone number or short code). (format: address, e.g. +E.164)
  --type: string@type-completer # The protocol for sending the message, either SMS or MMS.
  --use-profile-webhooks: oneof<nothing, bool> # If the profile this number is associated with has webhooks, use them for delivery notifications. If webhooks are also specified on the message itself, they will be attempted first, then those on the profile. (default: true)
  --webhook-failover-url: string # The failover URL where webhooks related to this message will be sent if sending to the primary URL fails. (format: url)
  --webhook-url: string # The URL where webhooks related to this message will be sent. (format: url)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/long_code")
  let req_body = {"auto_detect": $auto_detect, "from": $body_from, "media_urls": $media_urls, "subject": $subject, "text": $text, "to": $body_to, "type": $type, "use_profile_webhooks": $use_profile_webhooks, "webhook_failover_url": $webhook_failover_url, "webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send a message using number pool
#
# POST /messages/number_pool
# operationId: createNumberPoolMessage
export def "messages-number-pool create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-detect: oneof<nothing, bool> # Automatically detect if an SMS message is unusually long and exceeds a recommended limit of message parts. (default: false)
  --media-urls: list<string> # A list of media URLs. The total media size must be less than 1 MB. **Required for MMS**
  messaging_profile_id: string # Unique identifier for a messaging profile.
  --subject: string # Subject of multimedia message
  --text: string # Message body (i.e., content) as a non-empty string. **Required for SMS**
  --body-to: string # Receiving address (+E.164 formatted phone number or short code). (format: address, e.g. +E.164)
  --type: string@type-completer # The protocol for sending the message, either SMS or MMS.
  --use-profile-webhooks: oneof<nothing, bool> # If the profile this number is associated with has webhooks, use them for delivery notifications. If webhooks are also specified on the message itself, they will be attempted first, then those on the profile. (default: true)
  --webhook-failover-url: string # The failover URL where webhooks related to this message will be sent if sending to the primary URL fails. (format: url)
  --webhook-url: string # The URL where webhooks related to this message will be sent. (format: url)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/number_pool")
  let req_body = {"auto_detect": $auto_detect, "media_urls": $media_urls, "messaging_profile_id": $messaging_profile_id, "subject": $subject, "text": $text, "to": $body_to, "type": $type, "use_profile_webhooks": $use_profile_webhooks, "webhook_failover_url": $webhook_failover_url, "webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send a short code message
#
# POST /messages/short_code
# operationId: createShortCodeMessage
export def "messages-short-code create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-detect: oneof<nothing, bool> # Automatically detect if an SMS message is unusually long and exceeds a recommended limit of message parts. (default: false)
  --body-from: string # Phone number, in +E.164 format, used to send the message. (format: address)
  --media-urls: list<string> # A list of media URLs. The total media size must be less than 1 MB. **Required for MMS**
  --subject: string # Subject of multimedia message
  --text: string # Message body (i.e., content) as a non-empty string. **Required for SMS**
  --body-to: string # Receiving address (+E.164 formatted phone number or short code). (format: address, e.g. +E.164)
  --type: string@type-completer # The protocol for sending the message, either SMS or MMS.
  --use-profile-webhooks: oneof<nothing, bool> # If the profile this number is associated with has webhooks, use them for delivery notifications. If webhooks are also specified on the message itself, they will be attempted first, then those on the profile. (default: true)
  --webhook-failover-url: string # The failover URL where webhooks related to this message will be sent if sending to the primary URL fails. (format: url)
  --webhook-url: string # The URL where webhooks related to this message will be sent. (format: url)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messages/short_code")
  let req_body = {"auto_detect": $auto_detect, "from": $body_from, "media_urls": $media_urls, "subject": $subject, "text": $text, "to": $body_to, "type": $type, "use_profile_webhooks": $use_profile_webhooks, "webhook_failover_url": $webhook_failover_url, "webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a message
#
# GET /messages/{id}
# operationId: retrieveMessage
export def "messages get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List messaging hosted number orders
#
# GET /messaging_hosted_number_orders
# operationId: listMessagingHostedNumberOrder
export def "messaging-hosted-number-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messaging_hosted_number_orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a messaging hosted number order
#
# POST /messaging_hosted_number_orders
# operationId: createMessagingHostedNumberOrder
export def "messaging-hosted-number-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --messaging-profile-id: string # Automatically associate the number with this messaging profile ID when the order is complete.
  --phone-numbers: list<string> # Phone numbers to be used for hosted messaging.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messaging_hosted_number_orders")
  let req_body = {"messaging_profile_id": $messaging_profile_id, "phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a messaging hosted number order
#
# GET /messaging_hosted_number_orders/{id}
# operationId: retrieveMessagingHostedNumberOrder
export def "messaging-hosted-number-orders get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_hosted_number_orders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload file required for a messaging hosted number order
#
# POST /messaging_hosted_number_orders/{id}/actions/file_upload
# operationId: uploadFileMessagingHostedNumberOrder
export def "messaging-hosted-number-orders-actions-file-upload upload" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bill: string # Must be the last month's bill with proof of ownership of all of the numbers in the order in PDF format. (format: binary)
  --loa: string # Must be a signed LOA for the numbers in the order in PDF format. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_hosted_number_orders/{id}/actions/file_upload"))
  let req_body = {"bill": $bill, "loa": $loa} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["bill" "loa"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete a messaging hosted number
#
# DELETE /messaging_hosted_numbers/{id}
# operationId: deleteMessagingHostedNumber
export def "messaging-hosted-numbers delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_hosted_numbers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List messaging profile metrics
#
# GET /messaging_profile_metrics
# operationId: listMessagingProfileMetrics
export def "messaging-profile-metrics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --id: string # The id of the messaging profile(s) to retrieve (format: uuid)
  --time-frame: string@time-frame-completer # The timeframe for which you'd like to retrieve metrics. (default: 24h)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "time_frame" $time_frame "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messaging_profile_metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "id": $id, "time_frame": $time_frame} | compact), body: null}
}

# List messaging profiles
#
# GET /messaging_profiles
# operationId: listMessagingProfiles
export def "messaging-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messaging_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a messaging profile
#
# POST /messaging_profiles
# operationId: createMessagingProfile
# --number_pool_settings shape: {geomatch?: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender?: bool, toll_free_weight: float}
# --url_shortener_settings shape: {domain: string, prefix?: string, replace_blacklist_only?: bool, send_webhooks?: bool}
export def "messaging-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Specifies whether the messaging profile is enabled or not. (default: true)
  name: string # A user friendly name for the messaging profile.
  --number-pool-settings: record # Number Pool allows you to send messages from a pool of numbers of different types, assigning weights to each type. The pool consists of all the long code and toll free numbers assigned to the messaging profile. To disable this feature, set the object field to `null`. (nullable, e.g. {geomatch: false, long_code_weight: 1, skip_unhealthy: true, sticky_sender: false, toll_free_weight: 10}) — shape: {geomatch?: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender?: bool, toll_free_weight: float}
  --url-shortener-settings: record # The URL shortener feature allows automatic replacement of URLs that were generated using a public URL shortener service. Some examples include bit.do, bit.ly, goo.gl, ht.ly, is.gd, ow.ly, rebrand.ly, t.co, tiny.cc, and tinyurl.com. Such URLs are replaced with with links generated by Telnyx. The use of custom links can improve branding and message deliverability. To disable this feature, set the object field to `null`. (nullable, e.g. {domain: example.ex, prefix: , replace_blacklist_only: true, send_webhooks: false}) — shape: {domain: string, prefix?: string, replace_blacklist_only?: bool, send_webhooks?: bool}
  --webhook-api-version: string@webhook-api-version-completer-1 # Determines which webhook format will be used, Telnyx API v1, v2, or a legacy 2010-04-01 format. (default: 2)
  --webhook-failover-url: string # The failover URL where webhooks related to this messaging profile will be sent if sending to the primary URL fails. (nullable, format: url, default: )
  --webhook-url: string # The URL where webhooks related to this messaging profile will be sent. (nullable, format: url, default: )
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/messaging_profiles")
  let req_body = {"enabled": $enabled, "name": $name, "number_pool_settings": $number_pool_settings, "url_shortener_settings": $url_shortener_settings, "webhook_api_version": $webhook_api_version, "webhook_failover_url": $webhook_failover_url, "webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a messaging profile
#
# DELETE /messaging_profiles/{id}
# operationId: deleteMessagingProfile
export def "messaging-profiles delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_profiles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a messaging profile
#
# GET /messaging_profiles/{id}
# operationId: retrieveMessagingProfile
export def "messaging-profiles get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_profiles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a messaging profile
#
# PATCH /messaging_profiles/{id}
# operationId: updateMessagingProfile
# --number_pool_settings shape: {geomatch?: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender?: bool, toll_free_weight: float}
# --url_shortener_settings shape: {domain: string, prefix?: string, replace_blacklist_only?: bool, send_webhooks?: bool}
export def "messaging-profiles update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Specifies whether the messaging profile is enabled or not.
  --name: string # A user friendly name for the messaging profile.
  --number-pool-settings: record # Number Pool allows you to send messages from a pool of numbers of different types, assigning weights to each type. The pool consists of all the long code and toll free numbers assigned to the messaging profile. To disable this feature, set the object field to `null`. (nullable, e.g. {geomatch: false, long_code_weight: 1, skip_unhealthy: true, sticky_sender: false, toll_free_weight: 10}) — shape: {geomatch?: bool, long_code_weight: float, skip_unhealthy: bool, sticky_sender?: bool, toll_free_weight: float}
  --url-shortener-settings: record # The URL shortener feature allows automatic replacement of URLs that were generated using a public URL shortener service. Some examples include bit.do, bit.ly, goo.gl, ht.ly, is.gd, ow.ly, rebrand.ly, t.co, tiny.cc, and tinyurl.com. Such URLs are replaced with with links generated by Telnyx. The use of custom links can improve branding and message deliverability. To disable this feature, set the object field to `null`. (nullable, e.g. {domain: example.ex, prefix: , replace_blacklist_only: true, send_webhooks: false}) — shape: {domain: string, prefix?: string, replace_blacklist_only?: bool, send_webhooks?: bool}
  --v1-secret: string # Secret used to authenticate with v1 endpoints.
  --webhook-api-version: string@webhook-api-version-completer-1 # Determines which webhook format will be used, Telnyx API v1, v2, or a legacy 2010-04-01 format.
  --webhook-failover-url: string # The failover URL where webhooks related to this messaging profile will be sent if sending to the primary URL fails. (nullable, format: url)
  --webhook-url: string # The URL where webhooks related to this messaging profile will be sent. (nullable, format: url)
  --whitelisted-destinations: list<string> # Destinations to which the messaging profile is allowed to send. If set to `null`, all destinations will be allowed. Setting a value of `["*"]` has the equivalent effect. The elements in the list must be valid ISO 3166-1 alpha-2 country codes. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_profiles/{id}"))
  let req_body = {"enabled": $enabled, "name": $name, "number_pool_settings": $number_pool_settings, "url_shortener_settings": $url_shortener_settings, "v1_secret": $v1_secret, "webhook_api_version": $webhook_api_version, "webhook_failover_url": $webhook_failover_url, "webhook_url": $webhook_url, "whitelisted_destinations": $whitelisted_destinations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve messaging profile metrics
#
# GET /messaging_profiles/{id}/metrics
# operationId: retrieveMessagingProfileDetailedMetrics
export def "messaging-profiles-metrics get-detailed" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --time-frame: string@time-frame-completer # The timeframe for which you'd like to retrieve metrics. (default: 24h)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "time_frame" $time_frame "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_profiles/{id}/metrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"time_frame": $time_frame} | compact), body: null}
}

# List phone numbers associated with a messaging profile
#
# GET /messaging_profiles/{id}/phone_numbers
# operationId: listMessagingProfilePhoneNumbers
export def "messaging-profiles-phone-numbers list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_profiles/{id}/phone_numbers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# List short codes associated with a messaging profile
#
# GET /messaging_profiles/{id}/short_codes
# operationId: listMessagingProfileShortCodes
export def "messaging-profiles-short-codes list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messaging_profiles/{id}/short_codes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# List messaging URL domains
#
# GET /messaging_url_domains
# operationId: listMessagingUrlDomains
export def "messaging-url-domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/messaging_url_domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# List mobile operator networks
#
# GET /mobile_operator_networks
# operationId: MobileOperatorNetworksGet
export def "mobile-operator-networks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-name-starts-with: string # Filter by name starting with. (e.g. AT)
  --filter-name-contains: string # Filter by name containing match. (e.g. T&T)
  --filter-name-ends-with: string # Filter by name ending with. (e.g. T)
  --filter-country-code: string # Filter by exact country_code. (e.g. US)
  --filter-mcc: string # Filter by exact MCC. (e.g. 310)
  --filter-mnc: string # Filter by exact MNC. (e.g. 410)
  --filter-tadig: string # Filter by exact TADIG. (e.g. USACG)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[name][starts_with]" $filter_name_starts_with "scalar") (serialize-qp "filter[name][contains]" $filter_name_contains "scalar") (serialize-qp "filter[name][ends_with]" $filter_name_ends_with "scalar") (serialize-qp "filter[country_code]" $filter_country_code "scalar") (serialize-qp "filter[mcc]" $filter_mcc "scalar") (serialize-qp "filter[mnc]" $filter_mnc "scalar") (serialize-qp "filter[tadig]" $filter_tadig "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/mobile_operator_networks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[name][starts_with]": $filter_name_starts_with, "filter[name][contains]": $filter_name_contains, "filter[name][ends_with]": $filter_name_ends_with, "filter[country_code]": $filter_country_code, "filter[mcc]": $filter_mcc, "filter[mnc]": $filter_mnc, "filter[tadig]": $filter_tadig} | compact), body: null}
}

# List notification channels
#
# GET /notification_channels
# operationId: listNotificationChannels
export def "notification-channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-channel-type-id-eq: string@filter-channel-type-id-eq-completer # Filter by the id of a channel type (e.g. webhook)
]: nothing -> record<data: table<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[channel_type_id][eq]" $filter_channel_type_id_eq "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notification_channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[channel_type_id][eq]": $filter_channel_type_id_eq} | compact), body: null}
}

# Create a notification channel
#
# POST /notification_channels
# operationId: createNotificationChannels
export def "notification-channels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-destination: string # The destination associated with the channel type. (e.g. +13125550000)
  --channel-type-id: string@channel-type-id-completer # A Channel Type ID
  --notification-profile-id: string # A UUID reference to the associated Notification Profile. (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
]: any -> record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notification_channels")
  let req_body = {"channel_destination": $channel_destination, "channel_type_id": $channel_type_id, "notification_profile_id": $notification_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a notification channel
#
# DELETE /notification_channels/{id}
# operationId: deleteNotificationChannel
export def "notification-channels delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notification_channels/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a notification channel
#
# GET /notification_channels/{id}
# operationId: retrieveNotificationChannel
export def "notification-channels get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notification_channels/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a notification channel
#
# PATCH /notification_channels/{id}
# operationId: updateNotificationChannel
export def "notification-channels update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-destination: string # The destination associated with the channel type. (e.g. +13125550000)
  --channel-type-id: string@channel-type-id-completer # A Channel Type ID
  --notification-profile-id: string # A UUID reference to the associated Notification Profile. (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
]: any -> record<data: record<channel_destination: string, channel_type_id: string, created_at: string, id: string, notification_profile_id: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notification_channels/{id}"))
  let req_body = {"channel_destination": $channel_destination, "channel_type_id": $channel_type_id, "notification_profile_id": $notification_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all Notifications Events Conditions
#
# GET /notification_event_conditions
# operationId: findNotificationsEventsConditions
export def "notification-event-conditions find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-associated-record-type-eq: string@filter-associated-record-type-eq-completer # Filter by the associated record type (e.g. phone_number)
]: nothing -> record<data: table<allow_multiple_channels: bool, associated_record_type: string, asynchronous: bool, created_at: string, description: string, enabled: bool, id: string, name: string, notification_event_id: string, parameters: list, supported_channels: list, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[associated_record_type][eq]" $filter_associated_record_type_eq "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notification_event_conditions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[associated_record_type][eq]": $filter_associated_record_type_eq} | compact), body: null}
}

# List all Notifications Events
#
# GET /notification_events
# operationId: findNotificationsEvents
export def "notification-events find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> record<data: table<created_at: string, enabled: bool, id: string, name: string, notification_category: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notification_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# List all Notifications Profiles
#
# GET /notification_profiles
# operationId: findNotificationsProfiles
export def "notification-profiles find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> record<data: table<created_at: string, id: string, name: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notification_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a notification profile
#
# POST /notification_profiles
# operationId: createNotificationProfile
export def "notification-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A human readable name.
]: any -> record<data: record<created_at: string, id: string, name: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notification_profiles")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a notification profile
#
# DELETE /notification_profiles/{id}
# operationId: deleteNotificationProfile
export def "notification-profiles delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created_at: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notification_profiles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a notification profile
#
# GET /notification_profiles/{id}
# operationId: retrieveNotificationProfile
export def "notification-profiles get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created_at: string, id: string, name: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notification_profiles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a notification profile
#
# PATCH /notification_profiles/{id}
# operationId: updateNotificationProfile
export def "notification-profiles update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # A human readable name.
]: any -> record<data: record<created_at: string, id: string, name: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notification_profiles/{id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List notification settings
#
# GET /notification_settings
# operationId: listNotificationSettings
export def "notification-settings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-notification-profile-id-eq: string # Filter by the id of a notification profile (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --filter-notification-channel-eq: string # Filter by the id of a notification channel (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --filter-notification-event-condition-id-eq: string # Filter by the id of a notification channel (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --filter-associated-record-type-eq: string@filter-associated-record-type-eq-completer # Filter by the associated record type (e.g. phone_number)
  --filter-status-eq: string@filter-status-eq-completer # The status of a notification setting (e.g. enable-received)
]: nothing -> record<data: table<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[notification_profile_id][eq]" $filter_notification_profile_id_eq "scalar") (serialize-qp "filter[notification_channel][eq]" $filter_notification_channel_eq "scalar") (serialize-qp "filter[notification_event_condition_id][eq]" $filter_notification_event_condition_id_eq "scalar") (serialize-qp "filter[associated_record_type][eq]" $filter_associated_record_type_eq "scalar") (serialize-qp "filter[status][eq]" $filter_status_eq "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/notification_settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[notification_profile_id][eq]": $filter_notification_profile_id_eq, "filter[notification_channel][eq]": $filter_notification_channel_eq, "filter[notification_event_condition_id][eq]": $filter_notification_event_condition_id_eq, "filter[associated_record_type][eq]": $filter_associated_record_type_eq, "filter[status][eq]": $filter_status_eq} | compact), body: null}
}

# Add a Notification Setting
#
# POST /notification_settings
# operationId: createNotificationSetting
# --parameters item shape: {name?: string, value?: string}
export def "notification-settings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notification-channel-id: string # A UUID reference to the associated Notification Channel. (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --notification-event-condition-id: string # A UUID reference to the associated Notification Event Condition. (e.g. 70c7c5cb-dce2-4124-accb-870d39dbe852)
  --notification-profile-id: string # A UUID reference to the associated Notification Profile. (e.g. 12455643-3cf1-4683-ad23-1cd32f7d5e0a)
  --parameters: list # item shape: {name?: string, value?: string}
]: any -> record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notification_settings")
  let req_body = {"notification_channel_id": $notification_channel_id, "notification_event_condition_id": $notification_event_condition_id, "notification_profile_id": $notification_profile_id, "parameters": $parameters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a notification setting
#
# DELETE /notification_settings/{id}
# operationId: deleteNotificationSetting
export def "notification-settings delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notification_settings/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a notification setting
#
# GET /notification_settings/{id}
# operationId: retrieveNotificationSetting
export def "notification-settings get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<associated_record_type: string, associated_record_type_value: string, created_at: string, id: string, notification_channel_id: string, notification_event_condition_id: string, notification_profile_id: string, parameters: list<record>, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/notification_settings/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List number block orders
#
# GET /number_block_orders
# operationId: listNumberBlockOrders
export def "number-block-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-status: string # Filter number block orders by status. (e.g. pending)
  --filter-created-at-gt: string # Filter number block orders later than this value. (e.g. 2018-01-01T00:00:00.000000Z)
  --filter-created-at-lt: string # Filter number block orders earlier than this value. (e.g. 2018-01-01T00:00:00.000000Z)
  --filter-phone-numbers-starting-number: string # Filter number block orders having these phone numbers. (e.g. +19705555000)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "filter[created_at][gt]" $filter_created_at_gt "scalar") (serialize-qp "filter[created_at][lt]" $filter_created_at_lt "scalar") (serialize-qp "filter[phone_numbers.starting_number]" $filter_phone_numbers_starting_number "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/number_block_orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[status]": $filter_status, "filter[created_at][gt]": $filter_created_at_gt, "filter[created_at][lt]": $filter_created_at_lt, "filter[phone_numbers.starting_number]": $filter_phone_numbers_starting_number, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a number block order
#
# POST /number_block_orders
# operationId: createNumberBlockOrder
export def "number-block-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # Identifies the connection associated with this phone number. (e.g. 346789098765567)
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --messaging-profile-id: string # Identifies the messaging profile associated with the phone number. (e.g. abc85f64-5717-4562-b3fc-2c9600)
  range: int # The phone number range included in the block. (e.g. 10)
  starting_number: string # Starting phone number block (format: e164_phone_number, e.g. +19705555000)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/number_block_orders")
  let req_body = {"connection_id": $connection_id, "customer_reference": $customer_reference, "messaging_profile_id": $messaging_profile_id, "range": $range, "starting_number": $starting_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a number block order
#
# GET /number_block_orders/{number_block_order_id}
# operationId: retrieveNumberBlockOrder
export def "number-block-orders get" [
  number_block_order_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_block_order_id | is-empty) { error make --unspanned { msg: "path parameter 'number_block_order_id' must be non-empty" } }
  let full_url = (build-url $base ({number_block_order_id: (encode-path-segment $number_block_order_id)} | format pattern "/number_block_orders/{number_block_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Lookup phone number data
#
# GET /number_lookup/{phone_number}
# operationId: NumberLookup
export def "number-lookup get" [
  phone_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer-1 # Specifies the type of number lookup to be performed
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number | is-empty) { error make --unspanned { msg: "path parameter 'phone_number' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number)} | format pattern "/number_lookup/{phone_number}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type} | compact), body: null}
}

# List number order documents
#
# GET /number_order_documents
# operationId: listNumberOrderDocuments
export def "number-order-documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-requirement-id: string # Filter number order documents by `requirement_id`.
  --filter-created-at-gt: string # Filter number order documents after this datetime.
  --filter-created-at-lt: string # Filter number order documents from before this datetime.
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[requirement_id]" $filter_requirement_id "scalar") (serialize-qp "filter[created_at][gt]" $filter_created_at_gt "scalar") (serialize-qp "filter[created_at][lt]" $filter_created_at_lt "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/number_order_documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[requirement_id]": $filter_requirement_id, "filter[created_at][gt]": $filter_created_at_gt, "filter[created_at][lt]": $filter_created_at_lt, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a number order document
#
# POST /number_order_documents
# operationId: createNumberOrderDocument
export def "number-order-documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --file-id: string # The id of the file to associate as a number order document. (e.g. 1e3c5822-0362-4702-8e46-5a129f0d3976)
  --requirements-id: string # Unique id for a requirement. (e.g. 36aaf27d-986b-493c-bd1b-de16af2e4292)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/number_order_documents")
  let req_body = {"customer_reference": $customer_reference, "file_id": $file_id, "requirements_id": $requirements_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a number order document
#
# GET /number_order_documents/{number_order_document_id}
# operationId: retrieveNumberOrderDocument
export def "number-order-documents get" [
  number_order_document_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_order_document_id | is-empty) { error make --unspanned { msg: "path parameter 'number_order_document_id' must be non-empty" } }
  let full_url = (build-url $base ({number_order_document_id: (encode-path-segment $number_order_document_id)} | format pattern "/number_order_documents/{number_order_document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a number order document
#
# PATCH /number_order_documents/{number_order_document_id}
# operationId: updateNumberOrderDocument
export def "number-order-documents update" [
  number_order_document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --file-id: string # The id of the file to associate as a number order document. (e.g. 1e3c5822-0362-4702-8e46-5a129f0d3976)
  --requirements-id: string # Unique id for a requirement. (e.g. 36aaf27d-986b-493c-bd1b-de16af2e4292)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_order_document_id | is-empty) { error make --unspanned { msg: "path parameter 'number_order_document_id' must be non-empty" } }
  let full_url = (build-url $base ({number_order_document_id: (encode-path-segment $number_order_document_id)} | format pattern "/number_order_documents/{number_order_document_id}"))
  let req_body = {"customer_reference": $customer_reference, "file_id": $file_id, "requirements_id": $requirements_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a list of phone numbers associated to orders
#
# GET /number_order_phone_numbers
# operationId: retrieveNumberOrderPhoneNumbers
export def "number-order-phone-numbers list" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/number_order_phone_numbers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a number order phone number.
#
# GET /number_order_phone_numbers/{number_order_phone_number_id}
# operationId: retrieveNumberOrderPhoneNumber
export def "number-order-phone-numbers get" [
  number_order_phone_number_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_order_phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'number_order_phone_number_id' must be non-empty" } }
  let full_url = (build-url $base ({number_order_phone_number_id: (encode-path-segment $number_order_phone_number_id)} | format pattern "/number_order_phone_numbers/{number_order_phone_number_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a number order phone number.
#
# PATCH /number_order_phone_numbers/{number_order_phone_number_id}
# operationId: updateNumberOrderPhoneNumber
# --regulatory_requirements item shape: {field_value?: string, requirement_id?: string}
export def "number-order-phone-numbers update" [
  number_order_phone_number_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --regulatory-requirements: list # item shape: {field_value?: string, requirement_id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_order_phone_number_id | is-empty) { error make --unspanned { msg: "path parameter 'number_order_phone_number_id' must be non-empty" } }
  let full_url = (build-url $base ({number_order_phone_number_id: (encode-path-segment $number_order_phone_number_id)} | format pattern "/number_order_phone_numbers/{number_order_phone_number_id}"))
  let req_body = {"regulatory_requirements": $regulatory_requirements} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List number orders
#
# GET /number_orders
# operationId: listNumberOrders
export def "number-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-status: string # Filter number orders by status.
  --filter-created-at-gt: string # Filter number orders later than this value.
  --filter-created-at-lt: string # Filter number orders earlier than this value.
  --filter-phone-numbers-count: string # Filter number order with this amount of numbers
  --filter-customer-reference: string # Filter number orders via the customer reference set.
  --filter-requirements-met: oneof<nothing, bool> # Filter number orders by requirements met.
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "filter[created_at][gt]" $filter_created_at_gt "scalar") (serialize-qp "filter[created_at][lt]" $filter_created_at_lt "scalar") (serialize-qp "filter[phone_numbers_count]" $filter_phone_numbers_count "scalar") (serialize-qp "filter[customer_reference]" $filter_customer_reference "scalar") (serialize-qp "filter[requirements_met]" $filter_requirements_met "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/number_orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[status]": $filter_status, "filter[created_at][gt]": $filter_created_at_gt, "filter[created_at][lt]": $filter_created_at_lt, "filter[phone_numbers_count]": $filter_phone_numbers_count, "filter[customer_reference]": $filter_customer_reference, "filter[requirements_met]": $filter_requirements_met, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a number order
#
# POST /number_orders
# operationId: createNumberOrder
# --phone_numbers item shape: {phone_number?: string, regulatory_requirements?: list}
export def "number-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # Identifies the billing group associated with the phone number. (e.g. abc85f64-5717-4562-b3fc-2c9600)
  --connection-id: string # Identifies the connection associated with this phone number. (e.g. 346789098765567)
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --messaging-profile-id: string # Identifies the messaging profile associated with the phone number. (e.g. abc85f64-5717-4562-b3fc-2c9600)
  --phone-numbers: list # item shape: {phone_number?: string, regulatory_requirements?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/number_orders")
  let req_body = {"billing_group_id": $billing_group_id, "connection_id": $connection_id, "customer_reference": $customer_reference, "messaging_profile_id": $messaging_profile_id, "phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a number order
#
# GET /number_orders/{number_order_id}
# operationId: retrieveNumberOrder
export def "number-orders get" [
  number_order_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_order_id | is-empty) { error make --unspanned { msg: "path parameter 'number_order_id' must be non-empty" } }
  let full_url = (build-url $base ({number_order_id: (encode-path-segment $number_order_id)} | format pattern "/number_orders/{number_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a number order
#
# PATCH /number_orders/{number_order_id}
# operationId: updateNumberOrder
# --phone_numbers item shape: {phone_number?: string, regulatory_requirements?: list}
export def "number-orders update" [
  number_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --phone-numbers: list # item shape: {phone_number?: string, regulatory_requirements?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_order_id | is-empty) { error make --unspanned { msg: "path parameter 'number_order_id' must be non-empty" } }
  let full_url = (build-url $base ({number_order_id: (encode-path-segment $number_order_id)} | format pattern "/number_orders/{number_order_id}"))
  let req_body = {"customer_reference": $customer_reference, "phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List number reservations
#
# GET /number_reservations
# operationId: listNumberReservations
export def "number-reservations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-status: string # Filter number reservations by status.
  --filter-created-at-gt: string # Filter number reservations later than this value.
  --filter-created-at-lt: string # Filter number reservations earlier than this value.
  --filter-phone-numbers-phone-number: string # Filter number reservations having these phone numbers.
  --filter-customer-reference: string # Filter number reservations via the customer reference set.
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "filter[created_at][gt]" $filter_created_at_gt "scalar") (serialize-qp "filter[created_at][lt]" $filter_created_at_lt "scalar") (serialize-qp "filter[phone_numbers.phone_number]" $filter_phone_numbers_phone_number "scalar") (serialize-qp "filter[customer_reference]" $filter_customer_reference "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/number_reservations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[status]": $filter_status, "filter[created_at][gt]": $filter_created_at_gt, "filter[created_at][lt]": $filter_created_at_lt, "filter[phone_numbers.phone_number]": $filter_phone_numbers_phone_number, "filter[customer_reference]": $filter_customer_reference, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a number reservation
#
# POST /number_reservations
# operationId: createNumberReservation
# --phone_numbers item shape: {phone_number?: string}
export def "number-reservations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --phone-numbers: list # item shape: {phone_number?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/number_reservations")
  let req_body = {"customer_reference": $customer_reference, "phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a number reservation
#
# GET /number_reservations/{number_reservation_id}
# operationId: retrieveNumberReservation
export def "number-reservations get" [
  number_reservation_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'number_reservation_id' must be non-empty" } }
  let full_url = (build-url $base ({number_reservation_id: (encode-path-segment $number_reservation_id)} | format pattern "/number_reservations/{number_reservation_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Extend a number reservation
#
# POST /number_reservations/{number_reservation_id}/actions/extend
# operationId: extendNumberReservationExpiryTime
export def "number-reservations-actions-extend create-expiry-time" [
  number_reservation_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($number_reservation_id | is-empty) { error make --unspanned { msg: "path parameter 'number_reservation_id' must be non-empty" } }
  let full_url = (build-url $base ({number_reservation_id: (encode-path-segment $number_reservation_id)} | format pattern "/number_reservations/{number_reservation_id}/actions/extend"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List OTA updates
#
# GET /ota_updates
# operationId: OTAUpdatesList
export def "ota-updates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-status: string@filter-status-completer-1 # Filter by a specific status of the resource's lifecycle. (e.g. in-progress)
  --filter-sim-card-id: string # The SIM card identification UUID.
  --filter-type: string@filter-type-completer-1 # Filter by type. (e.g. sim_card_network_preferences)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "filter[sim_card_id]" $filter_sim_card_id "scalar") (serialize-qp "filter[type]" $filter_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ota_updates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[status]": $filter_status, "filter[sim_card_id]": $filter_sim_card_id, "filter[type]": $filter_type} | compact), body: null}
}

# Get OTA update
#
# GET /ota_updates/{id}
# operationId: OTAUpdateGET
export def "ota-updates get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/ota_updates/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all outbound voice profiles
#
# GET /outbound_voice_profiles
# operationId: listOutboundVoiceProfiles
export def "outbound-voice-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-name-contains: string # Optional filter on outbound voice profile name. (e.g. office-profile)
  --qp-sort: string@sort-completer-4 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: name: sorts the result by the name field in ascending order. -name: sorts the result by the name field in descending order. (default: -created_at, e.g. name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[name][contains]" $filter_name_contains "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/outbound_voice_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[name][contains]": $filter_name_contains, "sort": $qp_sort} | compact), body: null}
}

# Create an outbound voice profile
#
# POST /outbound_voice_profiles
# operationId: createOutboundVoiceProfile
# --call_recording shape: {call_recording_caller_phone_numbers?: list<string>, call_recording_channels?: "single"|"dual", call_recording_format?: "wav"|"mp3", call_recording_type?: "all"|"none"|"by_caller_phone_number"}
export def "outbound-voice-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # The ID of the billing group associated with the outbound proflile. Defaults to null (for no group assigned). (nullable, format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --call-recording: record # e.g. {call_recording_caller_phone_numbers: [+19705555098], call_recording_channels: dual, call_recording_format: mp3, call_recording_type: by_caller_phone_number} — shape: {call_recording_caller_phone_numbers?: list<string>, call_recording_channels?: "single"|"dual", call_recording_format?: "wav"|"mp3", call_recording_type?: "all"|"none"|"by_caller_phone_number"}
  --concurrent-call-limit: int # Must be no more than your global concurrent call limit. Null means no limit. (nullable, e.g. 10)
  --daily-spend-limit: string # The maximum amount of usage charges, in USD, you want Telnyx to allow on this outbound voice profile in a day before disallowing new calls. (e.g. 100.00)
  --daily-spend-limit-enabled: oneof<nothing, bool> # Specifies whether to enforce the daily_spend_limit on this outbound voice profile. (default: false, e.g. true)
  --enabled: oneof<nothing, bool> # Specifies whether the outbound voice profile can be used. Disabled profiles will result in outbound calls being blocked for the associated Connections. (default: true, e.g. true)
  --max-destination-rate: float # Maximum rate (price per minute) for a Destination to be allowed when making outbound calls.
  name: string # A user-supplied name to help with organization. (e.g. office)
  --service-plan: string@service-plan-completer # Indicates the coverage of the termination regions. International and Global are the same but International may only be used for high volume/short duration Outbound Voice Profiles. (default: global, e.g. global)
  --tags: list<string> # e.g. [office-profile]
  --traffic-type: string@traffic-type-completer # Specifies the type of traffic allowed in this profile. (default: conversational, e.g. conversational)
  --usage-payment-method: string@usage-payment-method-completer # Setting for how costs for outbound profile are calculated. (default: rate-deck, e.g. tariff)
  --whitelisted-destinations: list<string> # The list of destinations you want to be able to call using this outbound voice profile formatted in alpha2. (default: [US, CA], e.g. [US, BR, AU])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/outbound_voice_profiles")
  let req_body = {"billing_group_id": $billing_group_id, "call_recording": $call_recording, "concurrent_call_limit": $concurrent_call_limit, "daily_spend_limit": $daily_spend_limit, "daily_spend_limit_enabled": $daily_spend_limit_enabled, "enabled": $enabled, "max_destination_rate": $max_destination_rate, "name": $name, "service_plan": $service_plan, "tags": $tags, "traffic_type": $traffic_type, "usage_payment_method": $usage_payment_method, "whitelisted_destinations": $whitelisted_destinations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an outbound voice profile
#
# DELETE /outbound_voice_profiles/{id}
# operationId: deleteOutboundVoiceProfile
export def "outbound-voice-profiles delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/outbound_voice_profiles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an outbound voice profile
#
# GET /outbound_voice_profiles/{id}
# operationId: retrieveOutboundVoiceProfile
export def "outbound-voice-profiles get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/outbound_voice_profiles/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Updates an existing outbound voice profile.
#
# PATCH /outbound_voice_profiles/{id}
# operationId: updateOutboundVoiceProfile
# --call_recording shape: {call_recording_caller_phone_numbers?: list<string>, call_recording_channels?: "single"|"dual", call_recording_format?: "wav"|"mp3", call_recording_type?: "all"|"none"|"by_caller_phone_number"}
export def "outbound-voice-profiles update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # The ID of the billing group associated with the outbound proflile. Defaults to null (for no group assigned). (nullable, format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --call-recording: record # e.g. {call_recording_caller_phone_numbers: [+19705555098], call_recording_channels: dual, call_recording_format: mp3, call_recording_type: by_caller_phone_number} — shape: {call_recording_caller_phone_numbers?: list<string>, call_recording_channels?: "single"|"dual", call_recording_format?: "wav"|"mp3", call_recording_type?: "all"|"none"|"by_caller_phone_number"}
  --concurrent-call-limit: int # Must be no more than your global concurrent call limit. Null means no limit. (nullable, e.g. 10)
  --daily-spend-limit: string # The maximum amount of usage charges, in USD, you want Telnyx to allow on this outbound voice profile in a day before disallowing new calls. (e.g. 100.00)
  --daily-spend-limit-enabled: oneof<nothing, bool> # Specifies whether to enforce the daily_spend_limit on this outbound voice profile. (default: false, e.g. true)
  --enabled: oneof<nothing, bool> # Specifies whether the outbound voice profile can be used. Disabled profiles will result in outbound calls being blocked for the associated Connections. (default: true, e.g. true)
  --max-destination-rate: float # Maximum rate (price per minute) for a Destination to be allowed when making outbound calls.
  name: string # A user-supplied name to help with organization. (e.g. office)
  --service-plan: string@service-plan-completer # Indicates the coverage of the termination regions. International and Global are the same but International may only be used for high volume/short duration Outbound Voice Profiles. (default: global, e.g. global)
  --tags: list<string> # e.g. [office-profile]
  --traffic-type: string@traffic-type-completer # Specifies the type of traffic allowed in this profile. (default: conversational, e.g. conversational)
  --usage-payment-method: string@usage-payment-method-completer # Setting for how costs for outbound profile are calculated. (default: rate-deck, e.g. tariff)
  --whitelisted-destinations: list<string> # The list of destinations you want to be able to call using this outbound voice profile formatted in alpha2. (default: [US, CA], e.g. [US, BR, AU])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/outbound_voice_profiles/{id}"))
  let req_body = {"billing_group_id": $billing_group_id, "call_recording": $call_recording, "concurrent_call_limit": $concurrent_call_limit, "daily_spend_limit": $daily_spend_limit, "daily_spend_limit_enabled": $daily_spend_limit_enabled, "enabled": $enabled, "max_destination_rate": $max_destination_rate, "name": $name, "service_plan": $service_plan, "tags": $tags, "traffic_type": $traffic_type, "usage_payment_method": $usage_payment_method, "whitelisted_destinations": $whitelisted_destinations} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the phone number blocks jobs
#
# GET /phone_number_blocks/jobs
# operationId: listPhoneNumberBlocksJobs
export def "phone-number-blocks-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-type: string@filter-type-completer-2 # Filter the phone number blocks jobs by type. (e.g. delete_phone_number_block)
  --filter-status: string@filter-status-completer-2 # Filter the phone number blocks jobs by status. (e.g. in_progress)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --qp-sort: string@sort-completer-5 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[type]" $filter_type "scalar") (serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_number_blocks/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[type]": $filter_type, "filter[status]": $filter_status, "page[number]": $page_number, "page[size]": $page_size, "sort": $qp_sort} | compact), body: null}
}

# Deletes all numbers associated with a phone number block
#
# POST /phone_number_blocks/jobs/delete_phone_number_block
# operationId: createPhoneNumberBlocksJobDeletePhoneNumberBlock
export def "phone-number-blocks-jobs-delete-phone-number-block create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number_block_id: string
]: any -> record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_number_blocks/jobs/delete_phone_number_block")
  let req_body = {"phone_number_block_id": $phone_number_block_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves a phone number blocks job
#
# GET /phone_number_blocks/jobs/{id}
# operationId: retrievePhoneNumberBlocksJob
export def "phone-number-blocks-jobs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_number_blocks/jobs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List phone numbers
#
# GET /phone_numbers
# operationId: listPhoneNumbers
export def "phone-numbers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-tag: string # Filter by phone number tags.
  --filter-phone-number: string # Filter by phone number. Requires at least three digits. Non-numerical characters will result in no values being returned.
  --filter-status: string@filter-status-completer-3 # Filter by phone number status. (e.g. active)
  --filter-voice-connection-name-contains: string # Filter contains connection name. Requires at least three characters. (e.g. test)
  --filter-voice-connection-name-starts-with: string # Filter starts with connection name. Requires at least three characters. (e.g. test)
  --filter-voice-connection-name-ends-with: string # Filter ends with connection name. Requires at least three characters. (e.g. test)
  --filter-voice-connection-name-eq: string # Filter by connection name. (e.g. test)
  --filter-usage-payment-method: string@filter-usage-payment-method-completer # Filter by usage_payment_method. (e.g. channel)
  --filter-billing-group-id: string # Filter by the billing_group_id associated with phone numbers. To filter to only phone numbers that have no billing group associated them, set the value of this filter to the string 'null'. (e.g. 62e4bf2e-c278-4282-b524-488d9c9c43b2)
  --filter-emergency-address-id: string # Filter by the emergency_address_id associated with phone numbers. To filter only phone numbers that have no emergency address associated with them, set the value of this filter to the string 'null'. (format: int64, e.g. 9102160989215728032)
  --filter-customer-reference: string # Filter numbers via the customer_reference set.
  --qp-sort: string@sort-completer-6 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[tag]" $filter_tag "scalar") (serialize-qp "filter[phone_number]" $filter_phone_number "scalar") (serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "filter[voice.connection_name][contains]" $filter_voice_connection_name_contains "scalar") (serialize-qp "filter[voice.connection_name][starts_with]" $filter_voice_connection_name_starts_with "scalar") (serialize-qp "filter[voice.connection_name][ends_with]" $filter_voice_connection_name_ends_with "scalar") (serialize-qp "filter[voice.connection_name][eq]" $filter_voice_connection_name_eq "scalar") (serialize-qp "filter[usage_payment_method]" $filter_usage_payment_method "scalar") (serialize-qp "filter[billing_group_id]" $filter_billing_group_id "scalar") (serialize-qp "filter[emergency_address_id]" $filter_emergency_address_id "scalar") (serialize-qp "filter[customer_reference]" $filter_customer_reference "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[tag]": $filter_tag, "filter[phone_number]": $filter_phone_number, "filter[status]": $filter_status, "filter[voice.connection_name][contains]": $filter_voice_connection_name_contains, "filter[voice.connection_name][starts_with]": $filter_voice_connection_name_starts_with, "filter[voice.connection_name][ends_with]": $filter_voice_connection_name_ends_with, "filter[voice.connection_name][eq]": $filter_voice_connection_name_eq, "filter[usage_payment_method]": $filter_usage_payment_method, "filter[billing_group_id]": $filter_billing_group_id, "filter[emergency_address_id]": $filter_emergency_address_id, "filter[customer_reference]": $filter_customer_reference, "sort": $qp_sort} | compact), body: null}
}

# List CSV downloads
#
# GET /phone_numbers/csv_downloads
# operationId: listCsvDownloads
export def "phone-numbers-csv-downloads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_numbers/csv_downloads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a CSV download
#
# POST /phone_numbers/csv_downloads
# operationId: createCsvDownload
export def "phone-numbers-csv-downloads create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_numbers/csv_downloads")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a CSV download
#
# GET /phone_numbers/csv_downloads/{id}
# operationId: retrieveCsvDownload
export def "phone-numbers-csv-downloads get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/csv_downloads/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve your inbound channels
#
# GET /phone_numbers/inbound_channels
# operationId: listOutboundChannels
export def "phone-numbers-inbound-channels list-outbound" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<channels: int, record_type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_numbers/inbound_channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update inbound channels
#
# PATCH /phone_numbers/inbound_channels
# operationId: updateOutboundChannels
export def "phone-numbers-inbound-channels update-outbound" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channels: int # The new number of concurrent channels for the account (e.g. 7)
]: any -> record<data: record<channels: int, record_type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_numbers/inbound_channels")
  let req_body = {"channels": $channels} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Lists the phone numbers jobs
#
# GET /phone_numbers/jobs
# operationId: listPhoneNumbersJobs
export def "phone-numbers-jobs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-type: string@filter-type-completer-3 # Filter the phone number jobs by type. (e.g. update_emergency_settings)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --qp-sort: string@sort-completer-5 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[type]" $filter_type "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_numbers/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[type]": $filter_type, "page[number]": $page_number, "page[size]": $page_size, "sort": $qp_sort} | compact), body: null}
}

# Delete a batch of numbers
#
# POST /phone_numbers/jobs/delete_phone_numbers
# operationId: createPhoneNumbersJobDeletePhoneNumbers
export def "phone-numbers-jobs-delete-phone-numbers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_numbers: list<string>
]: any -> record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_numbers/jobs/delete_phone_numbers")
  let req_body = {"phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update the emergency settings from a batch of numbers
#
# POST /phone_numbers/jobs/update_emergency_settings
# operationId: createPhoneNumbersJobUpdateEmergencySettings
export def "phone-numbers-jobs-update-emergency-settings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emergency_address_id: string # Identifies the address to be used with emergency services. (format: int64)
  --emergency-enabled: oneof<nothing, bool> # Indicates whether to enable emergency services on this number.
  phone_numbers: list<string>
]: any -> record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_numbers/jobs/update_emergency_settings")
  let req_body = {"emergency_address_id": $emergency_address_id, "emergency_enabled": $emergency_enabled, "phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update a batch of numbers
#
# POST /phone_numbers/jobs/update_phone_numbers
# operationId: createPhoneNumbersJobUpdatePhoneNumber
export def "phone-numbers-jobs-update-phone-numbers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # Identifies the billing group associated with the phone number.
  --connection-id: string # Identifies the connection associated with the phone number.
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --external-pin: string # If someone attempts to port your phone number away from Telnyx and your phone number has an external PIN set, we will attempt to verify that you provided the correct external PIN to the winning carrier. Note that not all carriers cooperate with this security mechanism.
  phone_numbers: list<string> # Array of phone number ids and/or phone numbers in E164 format to update
  --tags: list<string> # A list of user-assigned tags to help organize phone numbers.
]: any -> record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/phone_numbers/jobs/update_phone_numbers")
  let req_body = {"billing_group_id": $billing_group_id, "connection_id": $connection_id, "customer_reference": $customer_reference, "external_pin": $external_pin, "phone_numbers": $phone_numbers, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a phone numbers job
#
# GET /phone_numbers/jobs/{id}
# operationId: retrievePhoneNumbersJob
export def "phone-numbers-jobs get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created_at: string, etc: string, failed_operations: list<record>, id: string, pending_operations: list<record>, record_type: string, status: string, successful_operations: list<record>, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/jobs/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List phone numbers with messaging settings
#
# GET /phone_numbers/messaging
# operationId: listPhoneNumbersWithMessagingSettings
export def "phone-numbers-messaging list-with-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_numbers/messaging" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# List phone numbers with voice settings
#
# GET /phone_numbers/voice
# operationId: listPhoneNumbersWithVoiceSettings
export def "phone-numbers-voice list-with-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-phone-number: string # Filter by phone number. Requires at least three digits. Non-numerical characters will result in no values being returned.
  --filter-connection-name-contains: string # Filter contains connection name. Requires at least three characters. (e.g. test)
  --filter-customer-reference: string # Filter numbers via the customer_reference set.
  --filter-usage-payment-method: string@filter-usage-payment-method-completer # Filter by usage_payment_method. (e.g. channel)
  --qp-sort: string@sort-completer-6 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[phone_number]" $filter_phone_number "scalar") (serialize-qp "filter[connection_name][contains]" $filter_connection_name_contains "scalar") (serialize-qp "filter[customer_reference]" $filter_customer_reference "scalar") (serialize-qp "filter[usage_payment_method]" $filter_usage_payment_method "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/phone_numbers/voice" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[phone_number]": $filter_phone_number, "filter[connection_name][contains]": $filter_connection_name_contains, "filter[customer_reference]": $filter_customer_reference, "filter[usage_payment_method]": $filter_usage_payment_method, "sort": $qp_sort} | compact), body: null}
}

# Delete a phone number
#
# DELETE /phone_numbers/{id}
# operationId: deletePhoneNumber
export def "phone-numbers delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a phone number
#
# GET /phone_numbers/{id}
# operationId: retrievePhoneNumber
export def "phone-numbers get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a phone number
#
# PATCH /phone_numbers/{id}
# operationId: updatePhoneNumber
export def "phone-numbers update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing-group-id: string # Identifies the billing group associated with the phone number.
  --connection-id: string # Identifies the connection associated with the phone number.
  --customer-reference: string # A customer reference string for customer look ups. (e.g. MY REF 001)
  --external-pin: string # If someone attempts to port your phone number away from Telnyx and your phone number has an external PIN set, we will attempt to verify that you provided the correct external PIN to the winning carrier. Note that not all carriers cooperate with this security mechanism.
  --number-level-routing: string@number-level-routing-completer # Specifies whether the number can have overrides to the routing settings on itself (enabled) or if it uses the associated connection for all routing settings (disabled). Defaults to enabled but will be changed to disabled in the future. There are performance advantages to using disabled and setting all routing information at the connection level. (default: enabled)
  --tags: list<string> # A list of user-assigned tags to help organize phone numbers.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/{id}"))
  let req_body = {"billing_group_id": $billing_group_id, "connection_id": $connection_id, "customer_reference": $customer_reference, "external_pin": $external_pin, "number_level_routing": $number_level_routing, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Enable emergency for a phone number
#
# POST /phone_numbers/{id}/actions/enable_emergency
# operationId: enableEmergencyPhoneNumber
export def "phone-numbers-actions-enable-emergency enable" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  emergency_address_id: string # Identifies the address to be used with emergency services. (format: int64)
  --emergency-enabled: oneof<nothing, bool> # Indicates whether to enable emergency services on this number.
]: any -> record<data: record<call_forwarding: record<call_forwarding_enabled: bool, forwarding_type: string, forwards_to: string>, call_recording: record<inbound_call_recording_channels: string, inbound_call_recording_enabled: bool, inbound_call_recording_format: string>, cnam_listing: record<cnam_listing_details: string, cnam_listing_enabled: bool>, connection_id: string, customer_reference: string, emergency: record<emergency_address_id: string, emergency_enabled: bool, emergency_status: string>, id: string, media_features: record<accept_any_rtp_packets_enabled: bool, media_handling_mode: string, rtp_auto_adjust_enabled: bool, t38_fax_gateway_enabled: bool>, phone_number: string, record_type: string, tech_prefix_enabled: bool, translated_number: string, usage_payment_method: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/{id}/actions/enable_emergency"))
  let req_body = {"emergency_address_id": $emergency_address_id, "emergency_enabled": $emergency_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a phone number with messaging settings
#
# GET /phone_numbers/{id}/messaging
# operationId: retrievePhoneNumberWithMessagingSettings
export def "phone-numbers-messaging get-with-settings" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/{id}/messaging"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a phone number with messaging settings
#
# PATCH /phone_numbers/{id}/messaging
# operationId: updatePhoneNumberWithMessagingSettings
export def "phone-numbers-messaging update-with-settings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --messaging-product: string # The requested messaging product the number should be on (e.g. P2P)
  --messaging-profile-id: string # Unique identifier for a messaging profile.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/{id}/messaging"))
  let req_body = {"messaging_product": $messaging_product, "messaging_profile_id": $messaging_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a phone number with voice settings
#
# GET /phone_numbers/{id}/voice
# operationId: retrievePhoneNumberWithVoiceSettings
export def "phone-numbers-voice get-with-settings" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/{id}/voice"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a phone number with voice settings
#
# PATCH /phone_numbers/{id}/voice
# operationId: updatePhoneNumberWithVoiceSettings
# --call_forwarding shape: {call_forwarding_enabled?: bool, forwarding_type?: "always"|"on_failure", forwards_to?: string}
# --call_recording shape: {inbound_call_recording_channels?: "single"|"dual", inbound_call_recording_enabled?: bool, inbound_call_recording_format?: "wav"|"mp3"}
# --cnam_listing shape: {cnam_listing_details?: string, cnam_listing_enabled?: bool}
# --media_features shape: {accept_any_rtp_packets_enabled?: bool, media_handling_mode?: "default"|"proxy", rtp_auto_adjust_enabled?: bool, t38_fax_gateway_enabled?: bool}
export def "phone-numbers-voice update-with-settings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-forwarding: record # The call forwarding settings for a phone number. (e.g. {call_forwarding_enabled: true, forwarding_type: always, forwards_to: +13035559123}) — shape: {call_forwarding_enabled?: bool, forwarding_type?: "always"|"on_failure", forwards_to?: string}
  --call-recording: record # The call recording settings for a phone number. (e.g. {inbound_call_recording_channels: single, inbound_call_recording_enabled: true, inbound_call_recording_format: wav}) — shape: {inbound_call_recording_channels?: "single"|"dual", inbound_call_recording_enabled?: bool, inbound_call_recording_format?: "wav"|"mp3"}
  --cnam-listing: record # The CNAM listing settings for a phone number. (e.g. {cnam_listing_details: example, cnam_listing_enabled: true}) — shape: {cnam_listing_details?: string, cnam_listing_enabled?: bool}
  --media-features: record # The media features settings for a phone number. (e.g. {accept_any_rtp_packets_enabled: true, media_handling_mode: default, rtp_auto_adjust_enabled: true, t38_fax_gateway_enabled: true}) — shape: {accept_any_rtp_packets_enabled?: bool, media_handling_mode?: "default"|"proxy", rtp_auto_adjust_enabled?: bool, t38_fax_gateway_enabled?: bool}
  --tech-prefix-enabled: oneof<nothing, bool> # Controls whether a tech prefix is enabled for this phone number. (default: false)
  --translated-number: string # This field allows you to rewrite the destination number of an inbound call before the call is routed to you. The value of this field may be any alphanumeric value, and the value will replace the number originally dialed.
  --usage-payment-method: string@usage-payment-method-completer-1 # Controls whether a number is billed per minute or uses your concurrent channels. (default: pay-per-minute)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/phone_numbers/{id}/voice"))
  let req_body = {"call_forwarding": $call_forwarding, "call_recording": $call_recording, "cnam_listing": $cnam_listing, "media_features": $media_features, "tech_prefix_enabled": $tech_prefix_enabled, "translated_number": $translated_number, "usage_payment_method": $usage_payment_method} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Run a portability check
#
# POST /portability_checks
# operationId: postPortabilityCheck
export def "portability-checks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --phone-numbers: list<string> # The list of +E.164 formatted phone numbers to check for portability (e.g. [+13035550000, +13035550001, +13035550002])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/portability_checks")
  let req_body = {"phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all porting orders
#
# GET /porting_orders
# operationId: listPortingOrders
export def "porting-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --include-phone-numbers: oneof<nothing, bool> # Include the first 50 phone number objects in the results (default: true)
  --filter-status: record # Filter results by status
  --filter-customer-reference: string # Filter results by user reference (e.g. 123abc)
  --filter-phone-numbers-country-code: string # Filter results by country ISO 3166-1 alpha-2 code (e.g. US)
  --filter-phone-numbers-carrier-name: string # Filter results by old service provider (e.g. Telnyx)
  --filter-misc-type: string@filter-misc-type-completer # Filter results by porting order type (e.g. full)
  --filter-end-user-admin-entity-name: string # Filter results by person or company name (e.g. Porter McPortersen)
  --filter-end-user-admin-auth-person-name: string # Filter results by authorized person (e.g. Admin McPortersen)
  --filter-activation-settings-fast-port-eligible: oneof<nothing, bool> # Filter results by fast port eligible (e.g. false)
  --filter-activation-settings-foc-datetime-requested-gt: string # Filter results by foc date later than this value (e.g. 2021-03-25T10:00:00.000Z)
  --filter-activation-settings-foc-datetime-requested-lt: string # Filter results by foc date earlier than this value (e.g. 2021-03-25T10:00:00.000Z)
  --qp-sort: string@sort-completer-7 # Specifies the sort order for results. If not given, results are sorted by created_at in descending order. (e.g. created_at)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "include_phone_numbers" $include_phone_numbers "scalar") (serialize-qp "filter[status]" $filter_status "multi") (serialize-qp "filter[customer_reference]" $filter_customer_reference "scalar") (serialize-qp "filter[phone_numbers][country_code]" $filter_phone_numbers_country_code "scalar") (serialize-qp "filter[phone_numbers][carrier_name]" $filter_phone_numbers_carrier_name "scalar") (serialize-qp "filter[misc][type]" $filter_misc_type "scalar") (serialize-qp "filter[end_user][admin][entity_name]" $filter_end_user_admin_entity_name "scalar") (serialize-qp "filter[end_user][admin][auth_person_name]" $filter_end_user_admin_auth_person_name "scalar") (serialize-qp "filter[activation_settings][fast_port_eligible]" $filter_activation_settings_fast_port_eligible "scalar") (serialize-qp "filter[activation_settings][foc_datetime_requested][gt]" $filter_activation_settings_foc_datetime_requested_gt "scalar") (serialize-qp "filter[activation_settings][foc_datetime_requested][lt]" $filter_activation_settings_foc_datetime_requested_lt "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/porting_orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "include_phone_numbers": $include_phone_numbers, "filter[status]": $filter_status, "filter[customer_reference]": $filter_customer_reference, "filter[phone_numbers][country_code]": $filter_phone_numbers_country_code, "filter[phone_numbers][carrier_name]": $filter_phone_numbers_carrier_name, "filter[misc][type]": $filter_misc_type, "filter[end_user][admin][entity_name]": $filter_end_user_admin_entity_name, "filter[end_user][admin][auth_person_name]": $filter_end_user_admin_auth_person_name, "filter[activation_settings][fast_port_eligible]": $filter_activation_settings_fast_port_eligible, "filter[activation_settings][foc_datetime_requested][gt]": $filter_activation_settings_foc_datetime_requested_gt, "filter[activation_settings][foc_datetime_requested][lt]": $filter_activation_settings_foc_datetime_requested_lt, "sort": $qp_sort} | compact), body: null}
}

# Create a porting order
#
# POST /porting_orders
# operationId: createPortingOrder
export def "porting-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_numbers: list<string> # The list of +E.164 formatted phone numbers (e.g. [+13035550000, +13035550001, +13035550002])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/porting_orders")
  let req_body = {"phone_numbers": $phone_numbers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all exception types
#
# GET /porting_orders/exception_types
# operationId: listPortingOrdersExceptionTypes
export def "porting-orders-exception-types list" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/porting_orders/exception_types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Request cancellation
#
# DELETE /porting_orders/{id}
# operationId: deletePortingOrder
export def "porting-orders delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a porting order
#
# GET /porting_orders/{id}
# operationId: getPortingOrder
export def "porting-orders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-phone-numbers: oneof<nothing, bool> # Include the first 50 phone number objects in the results (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_phone_numbers" $include_phone_numbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_phone_numbers": $include_phone_numbers} | compact), body: null}
}

# Edit a porting order
#
# PATCH /porting_orders/{id}
# operationId: updatePortingOrder
# --activation_settings shape: {foc_datetime_requested?: string}
# --end_user shape: {admin?: record, location?: record}
# --misc shape: {new_billing_phone_number?: string, remaining_numbers_action?: "keep"|"disconnect", type?: "full"|"partial"}
# --phone_number_configuration shape: {connection_id?: string, emergency_address_id?: string, messaging_profile_id?: string, tags?: list<string>}
# --requirements item shape: {field_value: string, requirement_type_id: string}
# --user_feedback shape: {user_comment?: string, user_rating?: int}
export def "porting-orders update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --activation-settings: record # shape: {foc_datetime_requested?: string}
  --customer-reference: string
  --end-user: record # shape: {admin?: record, location?: record}
  --misc: record # shape: {new_billing_phone_number?: string, remaining_numbers_action?: "keep"|"disconnect", type?: "full"|"partial"}
  --phone-number-configuration: record # shape: {connection_id?: string, emergency_address_id?: string, messaging_profile_id?: string, tags?: list<string>}
  --requirements: list # List of requirements for porting numbers. — item shape: {field_value: string, requirement_type_id: string}
  --user-feedback: record # shape: {user_comment?: string, user_rating?: int}
  --webhook-url: string # format: uri
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}"))
  let req_body = {"activation_settings": $activation_settings, "customer_reference": $customer_reference, "end_user": $end_user, "misc": $misc, "phone_number_configuration": $phone_number_configuration, "requirements": $requirements, "user_feedback": $user_feedback, "webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Activates every number on a porting order.
#
# POST /porting_orders/{id}/actions/activate
# operationId: activatePortingOrder
export def "porting-orders-actions-activate create" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}/actions/activate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel this porting order
#
# POST /porting_orders/{id}/actions/cancel
# operationId: cancelPortingOrder
export def "porting-orders-actions-cancel cancel" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}/actions/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Confirms the porting order is ready to be actioned.
#
# POST /porting_orders/{id}/actions/confirm
# operationId: confirmPortingOrder
export def "porting-orders-actions-confirm confirm" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}/actions/confirm"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all porting activation jobs
#
# GET /porting_orders/{id}/activation_jobs
# operationId: listPortingOrdersActivationJobs
export def "porting-orders-activation-jobs list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}/activation_jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Retrieve a porting activation job
#
# GET /porting_orders/{id}/activation_jobs/{activationJobId}
# operationId: getPortingOrdersActivationJob
export def "porting-orders-activation-jobs get" [
  id: string
  activation_job_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($activation_job_id | is-empty) { error make --unspanned { msg: "path parameter 'activationJobId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), activation_job_id: (encode-path-segment $activation_job_id)} | format pattern "/porting_orders/{id}/activation_jobs/{activation_job_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all comments of a porting order
#
# GET /porting_orders/{id}/comments
# operationId: listPortingOrdersComments
export def "porting-orders-comments list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a comment for a porting order
#
# POST /porting_orders/{id}/comments
# operationId: createPortingOrderComment
export def "porting-orders-comments create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # e.g. Please, let me know when the port completes
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}/comments"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download a porting order loa template
#
# GET /porting_orders/{id}/loa_template
# operationId: getPortingOrderLOATemplate
export def "porting-orders-loa-template get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/porting_orders/{id}/loa_template"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all porting phone numbers
#
# GET /porting_phone_numbers
export def "porting-phone-numbers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-porting-order-id: string # Filter results by porting order id (format: uuid)
  --filter-phone-number: string # Filter results by phone number
  --filter-activation-status: string@filter-activation-status-completer # Filter results by activation status (e.g. Active)
  --filter-portability-status: string@filter-portability-status-completer # Filter results by portability status (e.g. confirmed)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[porting_order_id]" $filter_porting_order_id "scalar") (serialize-qp "filter[phone_number]" $filter_phone_number "scalar") (serialize-qp "filter[activation_status]" $filter_activation_status "scalar") (serialize-qp "filter[portability_status]" $filter_portability_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/porting_phone_numbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[porting_order_id]": $filter_porting_order_id, "filter[phone_number]": $filter_phone_number, "filter[activation_status]": $filter_activation_status, "filter[portability_status]": $filter_portability_status} | compact), body: null}
}

# Retrieve a list of portout requests
#
# GET /portouts
# operationId: listPortoutRequest
export def "portouts list-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-carrier-name: string # Filter by new carrier name.
  --filter-spid: string # Filter by new carrier spid.
  --filter-status: string@filter-status-completer-4 # Filter by portout status.
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[carrier_name]" $filter_carrier_name "scalar") (serialize-qp "filter[spid]" $filter_spid "scalar") (serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/portouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[carrier_name]": $filter_carrier_name, "filter[spid]": $filter_spid, "filter[status]": $filter_status, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Retrieve a portout request
#
# GET /portouts/{id}
# operationId: findPortoutRequest
export def "portouts find-request" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/portouts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all comments for a portout request
#
# GET /portouts/{id}/comments
# operationId: findPortoutComments
export def "portouts-comments find" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/portouts/{id}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a comment on a portout request
#
# POST /portouts/{id}/comments
# operationId: postPortRequestComment
export def "portouts-comments create-port-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: string # Comment to post on this portout request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/portouts/{id}/comments"))
  let req_body = {"body": $body} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Status
#
# PATCH /portouts/{id}/{status}
# operationId: updatePortoutRequest
export def "portouts update-request" [
  id: string
  status: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($status | is-empty) { error make --unspanned { msg: "path parameter 'status' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), status: (encode-path-segment $status)} | format pattern "/portouts/{id}/{status}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all Private Wireless Gateways
#
# GET /private_wireless_gateways
# operationId: getPrivateWirelessGateways
export def "private-wireless-gateways list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-name: string # The name of the Private Wireless Gateway. (e.g. my private gateway)
  --filter-ip-range: string # The IP address range of the Private Wireless Gateway. (e.g. 192.168.0.0/24)
  --filter-region-code: string # The name of the region where the Private Wireless Gateway is deployed. (e.g. ashburn-va)
  --filter-created-at: string # Private Wireless Gateway resource creation date. (e.g. 2018-02-02T22:25:27.521Z)
  --filter-updated-at: string # When the Private Wireless Gateway was last updated. (e.g. 2018-02-02T22:25:27.521Z)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[ip_range]" $filter_ip_range "scalar") (serialize-qp "filter[region_code]" $filter_region_code "scalar") (serialize-qp "filter[created_at]" $filter_created_at "scalar") (serialize-qp "filter[updated_at]" $filter_updated_at "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/private_wireless_gateways" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[name]": $filter_name, "filter[ip_range]": $filter_ip_range, "filter[region_code]": $filter_region_code, "filter[created_at]": $filter_created_at, "filter[updated_at]": $filter_updated_at} | compact), body: null}
}

# Create a Private Wireless Gateway
#
# POST /private_wireless_gateways
# operationId: createPrivateWirelessGateway
export def "private-wireless-gateways create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The private wireless gateway name. (e.g. My private wireless gateway)
  network_id: string # The identification of the related network resource. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/private_wireless_gateways")
  let req_body = {"name": $name, "network_id": $network_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Private Wireless Gateway
#
# DELETE /private_wireless_gateways/{id}
# operationId: deletePrivateWirelessGateway
export def "private-wireless-gateways delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/private_wireless_gateways/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a Private Wireless Gateway
#
# GET /private_wireless_gateways/{id}
# operationId: getPrivateWirelessGateway
export def "private-wireless-gateways get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/private_wireless_gateways/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a call queue
#
# GET /queues/{queue_name}
# operationId: retrieveCallQueue
export def "queues get-call" [
  queue_name: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'queue_name' must be non-empty" } }
  let full_url = (build-url $base ({queue_name: (encode-path-segment $queue_name)} | format pattern "/queues/{queue_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve calls from a queue
#
# GET /queues/{queue_name}/calls
# operationId: listQueueCalls
export def "queues-calls list" [
  queue_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'queue_name' must be non-empty" } }
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({queue_name: (encode-path-segment $queue_name)} | format pattern "/queues/{queue_name}/calls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Retrieve a call from a queue
#
# GET /queues/{queue_name}/calls/{call_control_id}
# operationId: retrieveCallFromQueue
export def "queues-calls get" [
  queue_name: string
  call_control_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($queue_name | is-empty) { error make --unspanned { msg: "path parameter 'queue_name' must be non-empty" } }
  if ($call_control_id | is-empty) { error make --unspanned { msg: "path parameter 'call_control_id' must be non-empty" } }
  let full_url = (build-url $base ({queue_name: (encode-path-segment $queue_name), call_control_id: (encode-path-segment $call_control_id)} | format pattern "/queues/{queue_name}/calls/{call_control_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List recordings
#
# GET /recordings
# operationId: listRecordings
export def "recordings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-conference-id: string # Return only recordings associated with a given conference (e.g. 428c31b6-7af4-4bcb-b7f5-5013ef9657c1)
  --filter-created-at-gte: string # Return only recordings created later than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --filter-created-at-lte: string # Return only recordings created earlier than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[conference_id]" $filter_conference_id "scalar") (serialize-qp "filter[created_at][gte]" $filter_created_at_gte "scalar") (serialize-qp "filter[created_at][lte]" $filter_created_at_lte "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recordings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[conference_id]": $filter_conference_id, "filter[created_at][gte]": $filter_created_at_gte, "filter[created_at][lte]": $filter_created_at_lte, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Retrieve a recording
#
# GET /recordings/{id}
# operationId: retrieveRecording
export def "recordings get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/recordings/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch all previous requests for messaging detail reports. Messaging detail reports are reports for pulling all messaging records.
#
# GET /reports/batch_mdr_reports
# operationId: getCdrRequests
export def "reports-batch-mdr-reports get-cdr-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
]: nothing -> record<data: table<connections: list, created_at: string, directions: list, end_date: string, filters: list, id: string, profiles: string, record_type: string, record_types: list, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/batch_mdr_reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Submit a request for new messaging detail report. Messaging detail report pulls all raw messaging data according to defined filters.
#
# POST /reports/batch_mdr_reports
# operationId: submitMdrRequest
# --filters item shape: {billing_group?: string, cld?: string, cld_filter?: "contains"|"starts_with"|"ends_with", cli?: string, cli_filter?: "contains"|"starts_with"|"ends_with", filter_type?: "and"|"or", tags_list?: string}
export def "reports-batch-mdr-reports submit-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connections: list<int>
  --directions: list<string>
  end_date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --filters: list # item shape: {billing_group?: string, cld?: string, cld_filter?: "contains"|"starts_with"|"ends_with", cli?: string, cli_filter?: "contains"|"starts_with"|"ends_with", filter_type?: "and"|"or", tags_list?: string}
  --include-message-body: oneof<nothing, bool> # e.g. true
  --profiles: string # e.g. My profile
  --record-types: list<string>
  --report-name: string
  start_date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
]: any -> record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/batch_mdr_reports")
  let req_body = {"connections": $connections, "directions": $directions, "end_date": $end_date, "filters": $filters, "include_message_body": $include_message_body, "profiles": $profiles, "record_types": $record_types, "report_name": $report_name, "start_date": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete generated messaging detail report by id
#
# DELETE /reports/batch_mdr_reports/{id}
# operationId: deleteMdrRequest
export def "reports-batch-mdr-reports delete-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reports/batch_mdr_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch single messaging detail report by id.
#
# GET /reports/batch_mdr_reports/{id}
# operationId: getMdrRequest
export def "reports-batch-mdr-reports get-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<connections: list<int>, created_at: string, directions: list<string>, end_date: string, filters: list<record>, id: string, profiles: string, record_type: string, record_types: list<string>, report_name: string, report_url: string, start_date: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reports/batch_mdr_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate and fetch voice usage report synchronously. This endpoint will both generate and fetch the voice report over a specified time period. No polling is necessary but the response may take up to a couple of minutes.
#
# GET /reports/cdr_usage_reports/sync
# operationId: getUsageReportSync
export def "reports-cdr-usage-reports-sync get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --end-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --aggregation-type: string@aggregation-type-completer # e.g. no_aggregation
  --product-breakdown: string@product-breakdown-completer # e.g. no_breakdown
  --connections: list<float> # e.g. 1234567890123
]: nothing -> record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_time: string, id: string, product_breakdown: string, record_type: string, report_url: string, result: record, start_time: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "aggregation_type" $aggregation_type "scalar") (serialize-qp "product_breakdown" $product_breakdown "scalar") (serialize-qp "connections" $connections "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/cdr_usage_reports/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "aggregation_type": $aggregation_type, "product_breakdown": $product_breakdown, "connections": $connections} | compact), body: null}
}

# Fetch all messaging usage reports. Usage reports are aggregated messaging data for specified time period and breakdown
#
# GET /reports/mdr_usage_reports
# operationId: getUsageReports
export def "reports-mdr-usage-reports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
]: nothing -> record<data: table<aggregation_type: string, connections: list, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list, start_date: string, status: string, updated_at: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/mdr_usage_reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Submit request for new new messaging usage report. This endpoint will pull and aggregate messaging data in specified time period.
#
# POST /reports/mdr_usage_reports
# operationId: submitUsageReport
export def "reports-mdr-usage-reports submit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: any
]: any -> record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/mdr_usage_reports")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "*/*" $req_body {query: {}, body: $req_body}
}

# Generate and fetch messaging usage report synchronously. This endpoint will both generate and fetch the messaging report over a specified time period. No polling is necessary but the response may take up to a couple of minutes.
#
# GET /reports/mdr_usage_reports/sync
# operationId: getUsageReportSync_1
export def "reports-mdr-usage-reports-sync get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --end-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --aggregation-type: string@aggregation-type-completer-1 # e.g. profile
  --profiles: list<string> # e.g. My profile
]: nothing -> record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "aggregation_type" $aggregation_type "scalar") (serialize-qp "profiles" $profiles "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/mdr_usage_reports/sync" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "aggregation_type": $aggregation_type, "profiles": $profiles} | compact), body: null}
}

# Delete messaging usage report by id
#
# DELETE /reports/mdr_usage_reports/{id}
# operationId: deleteUsageReport
export def "reports-mdr-usage-reports delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reports/mdr_usage_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch a single messaging usage report by id
#
# GET /reports/mdr_usage_reports/{id}
# operationId: getUsageReport
export def "reports-mdr-usage-reports get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<aggregation_type: string, connections: list<int>, created_at: string, end_date: string, id: string, profiles: string, record_type: string, report_url: string, result: list<record>, start_date: string, status: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/reports/mdr_usage_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch all Mdr records
#
# GET /reports/mdrs
export def "reports-mdrs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Pagination start date
  --end-date: string # Pagination end date
  --id: string # e.g. e093fbe0-5bde-11eb-ae93-0242ac130002
  --direction: string@direction-completer # e.g. INBOUND
  --profile: string # e.g. My profile
  --cld: string # e.g. +15551237654
  --cli: string # e.g. +15551237654
  --status: string@status-completer-1 # e.g. DELIVERED
  --message-type: string@message-type-completer-1 # e.g. SMS
]: nothing -> record<data: table<cld: string, cli: string, cost: string, created_at: string, currency: string, direction: string, id: string, message_type: string, parts: float, profile_name: string, rate: string, record_type: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "direction" $direction "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "cld" $cld "scalar") (serialize-qp "cli" $cli "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "message_type" $message_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/mdrs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "id": $id, "direction": $direction, "profile": $profile, "cld": $cld, "cli": $cli, "status": $status, "message_type": $message_type} | compact), body: null}
}

# Fetch all Wdr records
#
# GET /reports/wdrs
# operationId: getPaginatedWdrs
export def "reports-wdrs get-paginated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date (e.g. 2021-05-01T00:00:00Z)
  --end-date: string # End date (e.g. 2021-06-01T00:00:00Z)
  --id: string # e.g. e093fbe0-5bde-11eb-ae93-0242ac130002
  --mcc: string # e.g. 204
  --mnc: string # e.g. 01
  --imsi: string # e.g. 123456
  --sim-group-name: string # e.g. sim name
  --sim-group-id: string # e.g. f05a189f-7c46-4531-ac56-1460dc465a42
  --sim-card-id: string # e.g. 877f80a6-e5b2-4687-9a04-88076265720f
  --phone-number: string # e.g. +12345678910
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
  --qp-sort: list<string> # default: created_at, e.g. created_at
]: nothing -> record<data: table<cost: record, created_at: string, downlink_data: record, duration_seconds: float, id: string, imsi: string, mcc: string, mnc: string, phone_number: string, rate: record, record_type: string, sim_card_id: string, sim_group_id: string, sim_group_name: string, uplink_data: record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "mcc" $mcc "scalar") (serialize-qp "mnc" $mnc "scalar") (serialize-qp "imsi" $imsi "scalar") (serialize-qp "sim_group_name" $sim_group_name "scalar") (serialize-qp "sim_group_id" $sim_group_id "scalar") (serialize-qp "sim_card_id" $sim_card_id "scalar") (serialize-qp "phone_number" $phone_number "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "sort" $qp_sort "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/reports/wdrs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date, "id": $id, "mcc": $mcc, "mnc": $mnc, "imsi": $imsi, "sim_group_name": $sim_group_name, "sim_group_id": $sim_group_id, "sim_card_id": $sim_card_id, "phone_number": $phone_number, "page[number]": $page_number, "page[size]": $page_size, "sort": $qp_sort} | compact), body: null}
}

# List all requirement types
#
# GET /requirement_types
# operationId: docReqsListRequirementTypes
export def "requirement-types list-doc-reqs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name-contains: string # Filters requirement types to those whose name contains a certain string. (e.g. utility bill)
  --qp-sort: string@sort-completer-8 # Specifies the sort order for results. If you want to sort by a field in ascending order, include it as a sort parameter. If you want to sort in descending order, prepend a `-` in front of the field name. (e.g. country_code)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name][contains]" $filter_name_contains "scalar") (serialize-qp "sort[]" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/requirement_types" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[name][contains]": $filter_name_contains, "sort[]": $qp_sort} | compact), body: null}
}

# Retrieve a requirement types
#
# GET /requirement_types/{id}
# operationId: docReqsRetrieveRequirementType
export def "requirement-types get-doc-reqs" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/requirement_types/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all requirements
#
# GET /requirements
# operationId: listRequirements
export def "requirements list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-country-code: string # Filters results to those applying to a 2-character (ISO 3166-1 alpha-2) country code (e.g. US)
  --filter-phone-number-type: string@filter-phone-number-type-completer-1 # Filters results to those applying to a specific `phone_number_type` (e.g. local)
  --filter-action: string@filter-action-completer # Filters requirements to those applying to a specific action. (e.g. porting)
  --qp-sort: string@sort-completer-9 # Specifies the sort order for results. If you want to sort by a field in ascending order, include it as a sort parameter. If you want to sort in descending order, prepend a `-` in front of the field name. (e.g. country_code)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[country_code]" $filter_country_code "scalar") (serialize-qp "filter[phone_number_type]" $filter_phone_number_type "scalar") (serialize-qp "filter[action]" $filter_action "scalar") (serialize-qp "sort[]" $qp_sort "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/requirements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[country_code]": $filter_country_code, "filter[phone_number_type]": $filter_phone_number_type, "filter[action]": $filter_action, "sort[]": $qp_sort, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Retrieve a document requirement
#
# GET /requirements/{id}
# operationId: docReqsRetrieveDocumentRequirements
export def "requirements get-doc-reqs-document" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/requirements/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a list of room participants.
#
# GET /room_participants
# operationId: ListRoomParticipants
export def "room-participants list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-joined-at-eq: string # ISO 8601 date for filtering room participants that joined on that date. (format: date, e.g. 2021-04-25)
  --filter-date-joined-at-gte: string # ISO 8601 date for filtering room participants that joined after that date. (format: date, e.g. 2021-04-25)
  --filter-date-joined-at-lte: string # ISO 8601 date for filtering room participants that joined before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering room participants updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering room participants updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering room participants updated before that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-eq: string # ISO 8601 date for filtering room participants that left on that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-gte: string # ISO 8601 date for filtering room participants that left after that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-lte: string # ISO 8601 date for filtering room participants that left before that date. (format: date, e.g. 2021-04-25)
  --filter-context: string # Filter room participants based on the context. (e.g. Alice)
  --filter-session-id: string # Session_id for filtering room participants. (e.g. 0ccc7b54-4df3-4bca-a65a-3da1ecc777f0)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[date_joined_at][eq]" $filter_date_joined_at_eq "scalar") (serialize-qp "filter[date_joined_at][gte]" $filter_date_joined_at_gte "scalar") (serialize-qp "filter[date_joined_at][lte]" $filter_date_joined_at_lte "scalar") (serialize-qp "filter[date_updated_at][eq]" $filter_date_updated_at_eq "scalar") (serialize-qp "filter[date_updated_at][gte]" $filter_date_updated_at_gte "scalar") (serialize-qp "filter[date_updated_at][lte]" $filter_date_updated_at_lte "scalar") (serialize-qp "filter[date_left_at][eq]" $filter_date_left_at_eq "scalar") (serialize-qp "filter[date_left_at][gte]" $filter_date_left_at_gte "scalar") (serialize-qp "filter[date_left_at][lte]" $filter_date_left_at_lte "scalar") (serialize-qp "filter[context]" $filter_context "scalar") (serialize-qp "filter[session_id]" $filter_session_id "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[number]" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/room_participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[date_joined_at][eq]": $filter_date_joined_at_eq, "filter[date_joined_at][gte]": $filter_date_joined_at_gte, "filter[date_joined_at][lte]": $filter_date_joined_at_lte, "filter[date_updated_at][eq]": $filter_date_updated_at_eq, "filter[date_updated_at][gte]": $filter_date_updated_at_gte, "filter[date_updated_at][lte]": $filter_date_updated_at_lte, "filter[date_left_at][eq]": $filter_date_left_at_eq, "filter[date_left_at][gte]": $filter_date_left_at_gte, "filter[date_left_at][lte]": $filter_date_left_at_lte, "filter[context]": $filter_context, "filter[session_id]": $filter_session_id, "page[size]": $page_size, "page[number]": $page_number} | compact), body: null}
}

# View a room participant.
#
# GET /room_participants/{room_participant_id}
# operationId: ViewRoomParticipant
export def "room-participants get-view" [
  room_participant_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_participant_id | is-empty) { error make --unspanned { msg: "path parameter 'room_participant_id' must be non-empty" } }
  let full_url = (build-url $base ({room_participant_id: (encode-path-segment $room_participant_id)} | format pattern "/room_participants/{room_participant_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a list of room sessions.
#
# GET /room_sessions
# operationId: ListRoomSessions
export def "room-sessions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-created-at-eq: string # ISO 8601 date for filtering room sessions created on that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-gte: string # ISO 8601 date for filtering room sessions created after that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-lte: string # ISO 8601 date for filtering room sessions created before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering room sessions updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering room sessions updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering room sessions updated before that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-eq: string # ISO 8601 date for filtering room sessions ended on that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-gte: string # ISO 8601 date for filtering room sessions ended after that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-lte: string # ISO 8601 date for filtering room sessions ended before that date. (format: date, e.g. 2021-04-25)
  --filter-room-id: string # Room_id for filtering room sessions. (e.g. 0ccc7b54-4df3-4bca-a65a-3da1ecc777f0)
  --filter-active: oneof<nothing, bool> # Filter active or inactive room sessions. (e.g. true)
  --include-participants: oneof<nothing, bool> # To decide if room participants should be included in the response. (e.g. true)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[date_created_at][eq]" $filter_date_created_at_eq "scalar") (serialize-qp "filter[date_created_at][gte]" $filter_date_created_at_gte "scalar") (serialize-qp "filter[date_created_at][lte]" $filter_date_created_at_lte "scalar") (serialize-qp "filter[date_updated_at][eq]" $filter_date_updated_at_eq "scalar") (serialize-qp "filter[date_updated_at][gte]" $filter_date_updated_at_gte "scalar") (serialize-qp "filter[date_updated_at][lte]" $filter_date_updated_at_lte "scalar") (serialize-qp "filter[date_ended_at][eq]" $filter_date_ended_at_eq "scalar") (serialize-qp "filter[date_ended_at][gte]" $filter_date_ended_at_gte "scalar") (serialize-qp "filter[date_ended_at][lte]" $filter_date_ended_at_lte "scalar") (serialize-qp "filter[room_id]" $filter_room_id "scalar") (serialize-qp "filter[active]" $filter_active "scalar") (serialize-qp "include_participants" $include_participants "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[number]" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/room_sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[date_created_at][eq]": $filter_date_created_at_eq, "filter[date_created_at][gte]": $filter_date_created_at_gte, "filter[date_created_at][lte]": $filter_date_created_at_lte, "filter[date_updated_at][eq]": $filter_date_updated_at_eq, "filter[date_updated_at][gte]": $filter_date_updated_at_gte, "filter[date_updated_at][lte]": $filter_date_updated_at_lte, "filter[date_ended_at][eq]": $filter_date_ended_at_eq, "filter[date_ended_at][gte]": $filter_date_ended_at_gte, "filter[date_ended_at][lte]": $filter_date_ended_at_lte, "filter[room_id]": $filter_room_id, "filter[active]": $filter_active, "include_participants": $include_participants, "page[size]": $page_size, "page[number]": $page_number} | compact), body: null}
}

# View a room session.
#
# GET /room_sessions/{room_session_id}
# operationId: ViewRoomSession
export def "room-sessions get-view" [
  room_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-participants: oneof<nothing, bool> # To decide if room participants should be included in the response. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_session_id | is-empty) { error make --unspanned { msg: "path parameter 'room_session_id' must be non-empty" } }
  let qp = [(serialize-qp "include_participants" $include_participants "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_session_id: (encode-path-segment $room_session_id)} | format pattern "/room_sessions/{room_session_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_participants": $include_participants} | compact), body: null}
}

# View a list of room participants.
#
# GET /room_sessions/{room_session_id}/participants
# operationId: NestedListRoomParticipants
export def "room-sessions-participants list-nested" [
  room_session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-joined-at-eq: string # ISO 8601 date for filtering room participants that joined on that date. (format: date, e.g. 2021-04-25)
  --filter-date-joined-at-gte: string # ISO 8601 date for filtering room participants that joined after that date. (format: date, e.g. 2021-04-25)
  --filter-date-joined-at-lte: string # ISO 8601 date for filtering room participants that joined before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering room participants updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering room participants updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering room participants updated before that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-eq: string # ISO 8601 date for filtering room participants that left on that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-gte: string # ISO 8601 date for filtering room participants that left after that date. (format: date, e.g. 2021-04-25)
  --filter-date-left-at-lte: string # ISO 8601 date for filtering room participants that left before that date. (format: date, e.g. 2021-04-25)
  --filter-context: string # Filter room participants based on the context. (e.g. Alice)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_session_id | is-empty) { error make --unspanned { msg: "path parameter 'room_session_id' must be non-empty" } }
  let qp = [(serialize-qp "filter[date_joined_at][eq]" $filter_date_joined_at_eq "scalar") (serialize-qp "filter[date_joined_at][gte]" $filter_date_joined_at_gte "scalar") (serialize-qp "filter[date_joined_at][lte]" $filter_date_joined_at_lte "scalar") (serialize-qp "filter[date_updated_at][eq]" $filter_date_updated_at_eq "scalar") (serialize-qp "filter[date_updated_at][gte]" $filter_date_updated_at_gte "scalar") (serialize-qp "filter[date_updated_at][lte]" $filter_date_updated_at_lte "scalar") (serialize-qp "filter[date_left_at][eq]" $filter_date_left_at_eq "scalar") (serialize-qp "filter[date_left_at][gte]" $filter_date_left_at_gte "scalar") (serialize-qp "filter[date_left_at][lte]" $filter_date_left_at_lte "scalar") (serialize-qp "filter[context]" $filter_context "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[number]" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_session_id: (encode-path-segment $room_session_id)} | format pattern "/room_sessions/{room_session_id}/participants") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[date_joined_at][eq]": $filter_date_joined_at_eq, "filter[date_joined_at][gte]": $filter_date_joined_at_gte, "filter[date_joined_at][lte]": $filter_date_joined_at_lte, "filter[date_updated_at][eq]": $filter_date_updated_at_eq, "filter[date_updated_at][gte]": $filter_date_updated_at_gte, "filter[date_updated_at][lte]": $filter_date_updated_at_lte, "filter[date_left_at][eq]": $filter_date_left_at_eq, "filter[date_left_at][gte]": $filter_date_left_at_gte, "filter[date_left_at][lte]": $filter_date_left_at_lte, "filter[context]": $filter_context, "page[size]": $page_size, "page[number]": $page_number} | compact), body: null}
}

# View a list of rooms.
#
# GET /rooms
# operationId: ListRooms
export def "rooms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-created-at-eq: string # ISO 8601 date for filtering rooms created on that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-gte: string # ISO 8601 date for filtering rooms created after that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-lte: string # ISO 8601 date for filtering rooms created before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering rooms updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering rooms updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering rooms updated before that date. (format: date, e.g. 2021-04-25)
  --filter-unique-name: string # Unique_name for filtering rooms. (e.g. my_video_room)
  --include-sessions: oneof<nothing, bool> # To decide if room sessions should be included in the response. (e.g. true)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[date_created_at][eq]" $filter_date_created_at_eq "scalar") (serialize-qp "filter[date_created_at][gte]" $filter_date_created_at_gte "scalar") (serialize-qp "filter[date_created_at][lte]" $filter_date_created_at_lte "scalar") (serialize-qp "filter[date_updated_at][eq]" $filter_date_updated_at_eq "scalar") (serialize-qp "filter[date_updated_at][gte]" $filter_date_updated_at_gte "scalar") (serialize-qp "filter[date_updated_at][lte]" $filter_date_updated_at_lte "scalar") (serialize-qp "filter[unique_name]" $filter_unique_name "scalar") (serialize-qp "include_sessions" $include_sessions "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[number]" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rooms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[date_created_at][eq]": $filter_date_created_at_eq, "filter[date_created_at][gte]": $filter_date_created_at_gte, "filter[date_created_at][lte]": $filter_date_created_at_lte, "filter[date_updated_at][eq]": $filter_date_updated_at_eq, "filter[date_updated_at][gte]": $filter_date_updated_at_gte, "filter[date_updated_at][lte]": $filter_date_updated_at_lte, "filter[unique_name]": $filter_unique_name, "include_sessions": $include_sessions, "page[size]": $page_size, "page[number]": $page_number} | compact), body: null}
}

# Create a room.
#
# POST /rooms
# operationId: CreateRoom
export def "rooms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-participants: int # The maximum amount of participants allowed in a room. If new participants try to join after that limit is reached, their request will be rejected. (default: 10, e.g. 10)
  --unique-name: string # The unique (within the Telnyx account scope) name of the room. (e.g. My room)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rooms")
  let req_body = {"max_participants": $max_participants, "unique_name": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a room.
#
# DELETE /rooms/{room_id}
# operationId: DeleteRoom
export def "rooms delete" [
  room_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'room_id' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a room.
#
# GET /rooms/{room_id}
# operationId: ViewRoom
export def "rooms get-view" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-sessions: oneof<nothing, bool> # To decide if room sessions should be included in the response. (e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'room_id' must be non-empty" } }
  let qp = [(serialize-qp "include_sessions" $include_sessions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_sessions": $include_sessions} | compact), body: null}
}

# Create Client Token to join a room.
#
# POST /rooms/{room_id}/actions/generate_join_client_token
# operationId: CreateRoomClientToken
export def "rooms-actions-generate-join-client-token create" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --refresh-token-ttl-secs: int # The time to live in seconds of the Refresh Token, after that time the Refresh Token is invalid and can't be used to refresh Client Token. (default: 3600, e.g. 3600)
  --token-ttl-secs: int # The time to live in seconds of the Client Token, after that time the Client Token is invalid and can't be used to join a Room. (default: 600, e.g. 600)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'room_id' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}/actions/generate_join_client_token"))
  let req_body = {"refresh_token_ttl_secs": $refresh_token_ttl_secs, "token_ttl_secs": $token_ttl_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Refresh Client Token to join a room.
#
# POST /rooms/{room_id}/actions/refresh_client_token
# operationId: RefreshRoomClientToken
export def "rooms-actions-refresh-client-token refresh" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  refresh_token: string # format: jwt, e.g. eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ0ZWxueXhfdGVsZXBob255IiwiZXhwIjoxNTkwMDEwMTQzLCJpYXQiOjE1ODc1OTA5NDMsImlzcyI6InRlbG55eF90ZWxlcGhvbnkiLCJqdGkiOiJiOGM3NDgzNy1kODllLTRhNjUtOWNmMi0zNGM3YTZmYTYwYzgiLCJuYmYiOjE1ODc1OTA5NDIsInN1YiI6IjVjN2FjN2QwLWRiNjUtNGYxMS05OGUxLWVlYzBkMWQ1YzZhZSIsInRlbF90b2tlbiI6InJqX1pra1pVT1pNeFpPZk9tTHBFVUIzc2lVN3U2UmpaRmVNOXMtZ2JfeENSNTZXRktGQUppTXlGMlQ2Q0JSbWxoX1N5MGlfbGZ5VDlBSThzRWlmOE1USUlzenl6U2xfYURuRzQ4YU81MHlhSEd1UlNZYlViU1ltOVdJaVEwZz09IiwidHlwIjoiYWNjZXNzIn0.gNEwzTow5MLLPLQENytca7pUN79PmPj6FyqZWW06ZeEmesxYpwKh0xRtA0TzLh6CDYIRHrI8seofOO0YFGDhpQ
  --token-ttl-secs: int # The time to live in seconds of the Client Token, after that time the Client Token is invalid and can't be used to join a Room. (default: 600, e.g. 600)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'room_id' must be non-empty" } }
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}/actions/refresh_client_token"))
  let req_body = {"refresh_token": $refresh_token, "token_ttl_secs": $token_ttl_secs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View a list of room sessions.
#
# GET /rooms/{room_id}/sessions
# operationId: NestedListRoomSessions
export def "rooms-sessions list-nested" [
  room_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-date-created-at-eq: string # ISO 8601 date for filtering room sessions created on that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-gte: string # ISO 8601 date for filtering room sessions created after that date. (format: date, e.g. 2021-04-25)
  --filter-date-created-at-lte: string # ISO 8601 date for filtering room sessions created before that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-eq: string # ISO 8601 date for filtering room sessions updated on that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-gte: string # ISO 8601 date for filtering room sessions updated after that date. (format: date, e.g. 2021-04-25)
  --filter-date-updated-at-lte: string # ISO 8601 date for filtering room sessions updated before that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-eq: string # ISO 8601 date for filtering room sessions ended on that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-gte: string # ISO 8601 date for filtering room sessions ended after that date. (format: date, e.g. 2021-04-25)
  --filter-date-ended-at-lte: string # ISO 8601 date for filtering room sessions ended before that date. (format: date, e.g. 2021-04-25)
  --filter-active: oneof<nothing, bool> # Filter active or inactive room sessions. (e.g. true)
  --include-participants: oneof<nothing, bool> # To decide if room participants should be included in the response. (e.g. true)
  --page-size: int # The size of the page. (default: 20)
  --page-number: int # The page number to load. (default: 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($room_id | is-empty) { error make --unspanned { msg: "path parameter 'room_id' must be non-empty" } }
  let qp = [(serialize-qp "filter[date_created_at][eq]" $filter_date_created_at_eq "scalar") (serialize-qp "filter[date_created_at][gte]" $filter_date_created_at_gte "scalar") (serialize-qp "filter[date_created_at][lte]" $filter_date_created_at_lte "scalar") (serialize-qp "filter[date_updated_at][eq]" $filter_date_updated_at_eq "scalar") (serialize-qp "filter[date_updated_at][gte]" $filter_date_updated_at_gte "scalar") (serialize-qp "filter[date_updated_at][lte]" $filter_date_updated_at_lte "scalar") (serialize-qp "filter[date_ended_at][eq]" $filter_date_ended_at_eq "scalar") (serialize-qp "filter[date_ended_at][gte]" $filter_date_ended_at_gte "scalar") (serialize-qp "filter[date_ended_at][lte]" $filter_date_ended_at_lte "scalar") (serialize-qp "filter[active]" $filter_active "scalar") (serialize-qp "include_participants" $include_participants "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[number]" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: (encode-path-segment $room_id)} | format pattern "/rooms/{room_id}/sessions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[date_created_at][eq]": $filter_date_created_at_eq, "filter[date_created_at][gte]": $filter_date_created_at_gte, "filter[date_created_at][lte]": $filter_date_created_at_lte, "filter[date_updated_at][eq]": $filter_date_updated_at_eq, "filter[date_updated_at][gte]": $filter_date_updated_at_gte, "filter[date_updated_at][lte]": $filter_date_updated_at_lte, "filter[date_ended_at][eq]": $filter_date_ended_at_eq, "filter[date_ended_at][gte]": $filter_date_ended_at_gte, "filter[date_ended_at][lte]": $filter_date_ended_at_lte, "filter[active]": $filter_active, "include_participants": $include_participants, "page[size]": $page_size, "page[number]": $page_number} | compact), body: null}
}

# List short codes
#
# GET /short_codes
# operationId: listShortCodes
export def "short-codes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-messaging-profile-id: string # Filter by Messaging Profile ID. Use the string `null` for phone numbers without assigned profiles. A synonym for the `/messaging_profiles/{id}/short_codes` endpoint when querying about an extant profile.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[messaging_profile_id]" $filter_messaging_profile_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/short_codes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[messaging_profile_id]": $filter_messaging_profile_id} | compact), body: null}
}

# Retrieve a short code
#
# GET /short_codes/{id}
# operationId: retrieveShortCode
export def "short-codes get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/short_codes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update short code
#
# PATCH /short_codes/{id}
# operationId: updateShortCode
export def "short-codes update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  messaging_profile_id: string # Unique identifier for a messaging profile.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/short_codes/{id}"))
  let req_body = {"messaging_profile_id": $messaging_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List SIM card group actions
#
# GET /sim_card_group_actions
# operationId: SimCardGroupActionsGet
export def "sim-card-group-actions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-sim-card-group-id: string # A valid SIM card group ID. (format: uuid, e.g. 47a1c2b0-cc7b-4ab1-bb98-b33fb0fc61b9)
  --filter-status: string@filter-status-completer-1 # Filter by a specific status of the resource's lifecycle. (e.g. in-progress)
  --filter-type: string@filter-type-completer-4 # Filter by action type. (e.g. set_private_wireless_gateway)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[sim_card_group_id]" $filter_sim_card_group_id "scalar") (serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "filter[type]" $filter_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sim_card_group_actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[sim_card_group_id]": $filter_sim_card_group_id, "filter[status]": $filter_status, "filter[type]": $filter_type} | compact), body: null}
}

# Get SIM card group action details
#
# GET /sim_card_group_actions/{id}
# operationId: SimCardGroupActionGet
export def "sim-card-group-actions get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_card_group_actions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all SIM card groups
#
# GET /sim_card_groups
# operationId: SimCardGroupsGetAll
export def "sim-card-groups get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-name: string # A valid SIM card group name. (format: uuid, e.g. My Test Group)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[name]" $filter_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sim_card_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[name]": $filter_name} | compact), body: null}
}

# Create a SIM card group
#
# POST /sim_card_groups
# operationId: SimCardGroupsPost
export def "sim-card-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-limit: int # Upper limit on the amount of data the SIM cards, within the group, can use. (e.g. 2048)
  name: string # A user friendly name for the SIM card group. (e.g. My Test Group)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sim_card_groups")
  let req_body = {"data_limit": $data_limit, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a SIM card group
#
# DELETE /sim_card_groups/{id}
# operationId: SimCardGroupDelete
export def "sim-card-groups delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_card_groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get SIM card group
#
# GET /sim_card_groups/{id}
# operationId: SimCardGroupsGet
export def "sim-card-groups get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_card_groups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a SIM card group
#
# PATCH /sim_card_groups/{id}
# operationId: SimCardGroupUpdate
export def "sim-card-groups update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --data-limit: int # Upper limit on the amount of data the SIM cards, within the group, can use. (e.g. 2048)
  --name: string # A user friendly name for the SIM card group. (e.g. My Test Group)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_card_groups/{id}"))
  let req_body = {"data_limit": $data_limit, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Request Private Wireless Gateway removal from SIM card group
#
# POST /sim_card_groups/{id}/actions/remove_private_wireless_gateway
# operationId: RemoveSIMCardGroupPrivateWirelessGateway
export def "sim-card-groups-actions-remove-private-wireless-gateway delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_card_groups/{id}/actions/remove_private_wireless_gateway"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Request Private Wireless Gateway assignment for SIM card group
#
# POST /sim_card_groups/{id}/actions/set_private_wireless_gateway
# operationId: SetSIMCardGroupPrivateWirelessGateway
export def "sim-card-groups-actions-set-private-wireless-gateway update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  private_wireless_gateway_id: string # The identification of the related Private Wireless Gateway resource. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_card_groups/{id}/actions/set_private_wireless_gateway"))
  let req_body = {"private_wireless_gateway_id": $private_wireless_gateway_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Preview SIM card orders
#
# POST /sim_card_order_preview
# operationId: SimCardOrdersPreview
export def "sim-card-order-preview create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_id: string # Uniquely identifies the address for the order. (format: int64, e.g. 1293384261075731499)
  quantity: int # The amount of SIM cards that the user would like to purchase in the SIM card order. (e.g. 21)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sim_card_order_preview")
  let req_body = {"address_id": $address_id, "quantity": $quantity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all SIM card orders
#
# GET /sim_card_orders
# operationId: SimCardOrdersGet
export def "sim-card-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-created-at: string # Filter by ISO 8601 formatted date-time string matching resource creation date-time. (format: datetime, e.g. 2018-02-02T22:25:27.521Z)
  --filter-updated-at: string # Filter by ISO 8601 formatted date-time string matching resource last update date-time. (format: datetime, e.g. 2018-02-02T22:25:27.521Z)
  --filter-quantity: int # Filter orders by how many SIM cards were ordered. (e.g. 21)
  --filter-cost-amount: string # The total monetary amount of the order. (e.g. 2.53)
  --filter-cost-currency: string # Filter by ISO 4217 currency string. (e.g. USD)
  --filter-address-id: string # Uniquely identifies the address for the order. (format: int64, e.g. 1293384261075731499)
  --filter-address-street-address: string # Returns entries with matching name of the street where the address is located. (e.g. 311 W Superior St)
  --filter-address-extended-address: string # Returns entries with matching name of the supplemental field for address information. (e.g. Suite 504)
  --filter-address-locality: string # Filter by the name of the city where the address is located. (e.g. Chicago)
  --filter-address-administrative-area: string # Filter by state or province where the address is located. (e.g. IL)
  --filter-address-country-code: string # Filter by the mobile operator two-character (ISO 3166-1 alpha-2) origin country code. (e.g. US)
  --filter-address-postal-code: string # Filter by postal code for the address. (e.g. 60654)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[created_at]" $filter_created_at "scalar") (serialize-qp "filter[updated_at]" $filter_updated_at "scalar") (serialize-qp "filter[quantity]" $filter_quantity "scalar") (serialize-qp "filter[cost.amount]" $filter_cost_amount "scalar") (serialize-qp "filter[cost.currency]" $filter_cost_currency "scalar") (serialize-qp "filter[address.id]" $filter_address_id "scalar") (serialize-qp "filter[address.street_address]" $filter_address_street_address "scalar") (serialize-qp "filter[address.extended_address]" $filter_address_extended_address "scalar") (serialize-qp "filter[address.locality]" $filter_address_locality "scalar") (serialize-qp "filter[address.administrative_area]" $filter_address_administrative_area "scalar") (serialize-qp "filter[address.country_code]" $filter_address_country_code "scalar") (serialize-qp "filter[address.postal_code]" $filter_address_postal_code "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sim_card_orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[created_at]": $filter_created_at, "filter[updated_at]": $filter_updated_at, "filter[quantity]": $filter_quantity, "filter[cost.amount]": $filter_cost_amount, "filter[cost.currency]": $filter_cost_currency, "filter[address.id]": $filter_address_id, "filter[address.street_address]": $filter_address_street_address, "filter[address.extended_address]": $filter_address_extended_address, "filter[address.locality]": $filter_address_locality, "filter[address.administrative_area]": $filter_address_administrative_area, "filter[address.country_code]": $filter_address_country_code, "filter[address.postal_code]": $filter_address_postal_code, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a SIM card order
#
# POST /sim_card_orders
# operationId: SimCardOrdersPost
export def "sim-card-orders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address_id: string # Uniquely identifies the address for the order. (format: int64, e.g. 1293384261075731499)
  quantity: int # The amount of SIM cards to order. (e.g. 23)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sim_card_orders")
  let req_body = {"address_id": $address_id, "quantity": $quantity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a single SIM card order
#
# GET /sim_card_orders/{id}
# operationId: SimCardOrderGet
export def "sim-card-orders get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_card_orders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get all SIM cards
#
# GET /sim_cards
# operationId: SimCardsGet
export def "sim-cards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --include-sim-card-group: oneof<nothing, bool> # It includes the associated SIM card group object in the response when present. (default: false, e.g. true)
  --filter-sim-card-group-id: string # A valid SIM card group ID. (format: uuid, e.g. 47a1c2b0-cc7b-4ab1-bb98-b33fb0fc61b9)
  --filter-tags: list<string> # A list of SIM card tags to filter on. If the SIM card contains all of the given tags they will be found. For example, if the SIM cards have the following tags: ['customers', 'staff', 'test'] ['test'] ['customers'] Searching for ['customers', 'test'] returns only the first because it's the only one with both tags. Searching for test returns the first two SIMs, because both of them have such tag. Searching for customers returns the first and last SIMs. (e.g. [personal, customers, active-customers])
  --filter-iccid: string # A search string to partially match for the SIM card's ICCID. (e.g. 89310410106543789301)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "include_sim_card_group" $include_sim_card_group "scalar") (serialize-qp "filter[sim_card_group_id]" $filter_sim_card_group_id "scalar") (serialize-qp "filter[tags]" $filter_tags "multi") (serialize-qp "filter[iccid]" $filter_iccid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sim_cards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "include_sim_card_group": $include_sim_card_group, "filter[sim_card_group_id]": $filter_sim_card_group_id, "filter[tags]": $filter_tags, "filter[iccid]": $filter_iccid} | compact), body: null}
}

# Validate SIM cards registration codes
#
# POST /sim_cards/actions/validate_registration_codes
# operationId: postValidateRegistrationCodes
export def "sim-cards-actions-validate-registration-codes create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --registration-codes: list<string>
]: any -> record<data: table<invalid_detail: string, record_type: string, registration_code: string, valid: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sim_cards/actions/validate_registration_codes")
  let req_body = {"registration_codes": $registration_codes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a SIM card
#
# DELETE /sim_cards/{id}
# operationId: SimCardDelete
export def "sim-cards delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_cards/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get SIM card
#
# GET /sim_cards/{id}
# operationId: SimCardGet
export def "sim-cards get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-sim-card-group: oneof<nothing, bool> # It includes the associated SIM card group object in the response when present. (default: false, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "include_sim_card_group" $include_sim_card_group "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_cards/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_sim_card_group": $include_sim_card_group} | compact), body: null}
}

# Update a SIM card
#
# PATCH /sim_cards/{id}
# operationId: SimCardUpdate
export def "sim-cards update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sim-card-group-id: string # The group SIMCardGroup identification. This attribute can be null when it's present in an associated resource. (format: uuid, e.g. 6a09cdc3-8948-47f0-aa62-74ac943d6c58)
  --tags: list<string> # Searchable tags associated with the SIM card (e.g. [personal, customers, active-customers])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_cards/{id}"))
  let req_body = {"sim_card_group_id": $sim_card_group_id, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Request a SIM card disable
#
# POST /sim_cards/{id}/actions/disable
# operationId: SimCardDisable
export def "sim-cards-actions-disable disable" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_cards/{id}/actions/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Request a SIM card enable
#
# POST /sim_cards/{id}/actions/enable
# operationId: SimCardEnable
export def "sim-cards-actions-enable enable" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_cards/{id}/actions/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Request setting a SIM card to standby
#
# POST /sim_cards/{id}/actions/set_standby
# operationId: SimCardSetStandby
export def "sim-cards-actions-set-standby update" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sim_cards/{id}/actions/set_standby"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# DELETE network preferences
#
# DELETE /sim_cards/{sim_card_id}/network_preferences
# operationId: SIMCardNetworkPreferencesDelete
export def "sim-cards-network-preferences delete" [
  sim_card_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sim_card_id | is-empty) { error make --unspanned { msg: "path parameter 'sim_card_id' must be non-empty" } }
  let full_url = (build-url $base ({sim_card_id: (encode-path-segment $sim_card_id)} | format pattern "/sim_cards/{sim_card_id}/network_preferences"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get network preferences
#
# GET /sim_cards/{sim_card_id}/network_preferences
# operationId: SIMCardNetworkPreferencesGet
export def "sim-cards-network-preferences get" [
  sim_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-ota-updates: oneof<nothing, bool> # It includes the associated OTA update objects in the response when present. (default: false, e.g. true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sim_card_id | is-empty) { error make --unspanned { msg: "path parameter 'sim_card_id' must be non-empty" } }
  let qp = [(serialize-qp "include_ota_updates" $include_ota_updates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sim_card_id: (encode-path-segment $sim_card_id)} | format pattern "/sim_cards/{sim_card_id}/network_preferences") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include_ota_updates": $include_ota_updates} | compact), body: null}
}

# Set network preferences
#
# PUT /sim_cards/{sim_card_id}/network_preferences
# operationId: SIMCardNetworkPreferencesPut
# --mobile_operator_networks_preferences item shape: {mobile_operator_network_id?: string, priority?: int}
export def "sim-cards-network-preferences update" [
  sim_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mobile-operator-networks-preferences: list # A list of mobile operator networks and the priority that should be applied when the SIM is connecting to the network. — item shape: {mobile_operator_network_id?: string, priority?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sim_card_id | is-empty) { error make --unspanned { msg: "path parameter 'sim_card_id' must be non-empty" } }
  let full_url = (build-url $base ({sim_card_id: (encode-path-segment $sim_card_id)} | format pattern "/sim_cards/{sim_card_id}/network_preferences"))
  let req_body = {"mobile_operator_networks_preferences": $mobile_operator_networks_preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete SIM card public IP
#
# DELETE /sim_cards/{sim_card_id}/public_ip
# operationId: SIMCardPublicIPDelete
export def "sim-cards-public-ip delete" [
  sim_card_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sim_card_id | is-empty) { error make --unspanned { msg: "path parameter 'sim_card_id' must be non-empty" } }
  let full_url = (build-url $base ({sim_card_id: (encode-path-segment $sim_card_id)} | format pattern "/sim_cards/{sim_card_id}/public_ip"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get SIM card public IP definition
#
# GET /sim_cards/{sim_card_id}/public_ip
# operationId: SIMCardPublicIPGet
export def "sim-cards-public-ip get" [
  sim_card_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sim_card_id | is-empty) { error make --unspanned { msg: "path parameter 'sim_card_id' must be non-empty" } }
  let full_url = (build-url $base ({sim_card_id: (encode-path-segment $sim_card_id)} | format pattern "/sim_cards/{sim_card_id}/public_ip"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set SIM card public IP
#
# POST /sim_cards/{sim_card_id}/public_ip
# operationId: SIMCardPublicIPPost
export def "sim-cards-public-ip create" [
  sim_card_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sim_card_id | is-empty) { error make --unspanned { msg: "path parameter 'sim_card_id' must be non-empty" } }
  let full_url = (build-url $base ({sim_card_id: (encode-path-segment $sim_card_id)} | format pattern "/sim_cards/{sim_card_id}/public_ip"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List wireless connectivity logs
#
# GET /sim_cards/{sim_card_id}/wireless_connectivity_logs
# operationId: WirelessConnectivityLogsGet
export def "sim-cards-wireless-connectivity-logs get" [
  sim_card_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sim_card_id | is-empty) { error make --unspanned { msg: "path parameter 'sim_card_id' must be non-empty" } }
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sim_card_id: (encode-path-segment $sim_card_id)} | format pattern "/sim_cards/{sim_card_id}/wireless_connectivity_logs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# List sub number orders
#
# GET /sub_number_orders
# operationId: listSubNumberOrders
export def "sub-number-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-user-id: string # User ID of the user who owns the sub number order (format: uuid, e.g. d70873cd-7c98-401a-81b6-b1ae08246995)
  --filter-order-request-id: string # ID of the number order the sub number order belongs to (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c293)
  --filter-country-code: string # ISO alpha-2 country code. (e.g. US)
  --filter-phone-number-type: string # Phone Number Type (e.g. local)
  --filter-phone-numbers-count: int # Amount of numbers in the sub number order (e.g. 1)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[user_id]" $filter_user_id "scalar") (serialize-qp "filter[order_request_id]" $filter_order_request_id "scalar") (serialize-qp "filter[country_code]" $filter_country_code "scalar") (serialize-qp "filter[phone_number_type]" $filter_phone_number_type "scalar") (serialize-qp "filter[phone_numbers_count]" $filter_phone_numbers_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sub_number_orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[user_id]": $filter_user_id, "filter[order_request_id]": $filter_order_request_id, "filter[country_code]": $filter_country_code, "filter[phone_number_type]": $filter_phone_number_type, "filter[phone_numbers_count]": $filter_phone_numbers_count} | compact), body: null}
}

# Retrieve a sub number order
#
# GET /sub_number_orders/{sub_number_order_id}
# operationId: retrieveSubNumberOrder
export def "sub-number-orders get" [
  sub_number_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-include-phone-numbers: oneof<nothing, bool> # Include the first 50 phone number objects in the results (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sub_number_order_id | is-empty) { error make --unspanned { msg: "path parameter 'sub_number_order_id' must be non-empty" } }
  let qp = [(serialize-qp "filter[include_phone_numbers]" $filter_include_phone_numbers "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({sub_number_order_id: (encode-path-segment $sub_number_order_id)} | format pattern "/sub_number_orders/{sub_number_order_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[include_phone_numbers]": $filter_include_phone_numbers} | compact), body: null}
}

# Update a sub number order
#
# PATCH /sub_number_orders/{sub_number_order_id}
# operationId: updateSubNumberOrder
# --regulatory_requirements item shape: {field_value?: string, requirement_id?: string}
export def "sub-number-orders update" [
  sub_number_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --regulatory-requirements: list # item shape: {field_value?: string, requirement_id?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($sub_number_order_id | is-empty) { error make --unspanned { msg: "path parameter 'sub_number_order_id' must be non-empty" } }
  let full_url = (build-url $base ({sub_number_order_id: (encode-path-segment $sub_number_order_id)} | format pattern "/sub_number_orders/{sub_number_order_id}"))
  let req_body = {"regulatory_requirements": $regulatory_requirements} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all credentials
#
# GET /telephony_credentials
# operationId: findTelephonyCredentials
export def "telephony-credentials find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-tag: string # Filter by tag
  --filter-name: string # Filter by name
  --filter-status: string # Filter by status
  --filter-resource-id: string # Filter by resource_id
  --filter-sip-username: string # Filter by sip_username
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[tag]" $filter_tag "scalar") (serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "filter[status]" $filter_status "scalar") (serialize-qp "filter[resource_id]" $filter_resource_id "scalar") (serialize-qp "filter[sip_username]" $filter_sip_username "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telephony_credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[tag]": $filter_tag, "filter[name]": $filter_name, "filter[status]": $filter_status, "filter[resource_id]": $filter_resource_id, "filter[sip_username]": $filter_sip_username} | compact), body: null}
}

# Create a credential
#
# POST /telephony_credentials
# operationId: CreateTelephonyCredential
export def "telephony-credentials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  connection_id: string # Identifies the Credential Connection this credential is associated with. (e.g. 1234567890)
  --expires-at: string # ISO-8601 formatted date indicating when the credential will expire. (e.g. 2018-02-02T22:25:27.521Z)
  --name: string
  --tag: string # Tags a credential to filter for bulk operations. A single tag can hold at maximum 1000 credentials. (e.g. some_tag)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/telephony_credentials")
  let req_body = {"connection_id": $connection_id, "expires_at": $expires_at, "name": $name, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List all tags
#
# GET /telephony_credentials/tags
# operationId: listTags
export def "telephony-credentials-tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/telephony_credentials/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Delete a credential
#
# DELETE /telephony_credentials/{id}
# operationId: DeleteTelephonyCredential
export def "telephony-credentials delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/telephony_credentials/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a credential
#
# GET /telephony_credentials/{id}
# operationId: getTelephonyCredential
export def "telephony-credentials get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/telephony_credentials/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a credential
#
# PATCH /telephony_credentials/{id}
# operationId: UpdateTelephonyCredential
export def "telephony-credentials update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --connection-id: string # Identifies the Credential Connection this credential is associated with. (e.g. 987654321)
  --expires-at: string # ISO-8601 formatted date indicating when the credential will expire. (e.g. 2018-02-02T22:25:27.521Z)
  --name: string
  --tag: string # Tags a credential to filter for bulk operations. A single tag can hold at maximum 1000 credentials. (e.g. some_tag)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/telephony_credentials/{id}"))
  let req_body = {"connection_id": $connection_id, "expires_at": $expires_at, "name": $name, "tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Perform activate or deactivate action on provided Credential
#
# POST /telephony_credentials/{id}/actions/{action}
# operationId: telephonyCredentialAction
export def "telephony-credentials-actions create" [
  id: string
  action: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($action | is-empty) { error make --unspanned { msg: "path parameter 'action' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), action: (encode-path-segment $action)} | format pattern "/telephony_credentials/{id}/actions/{action}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create an Access Token.
#
# POST /telephony_credentials/{id}/token
# operationId: CreateTelephonyCredentialToken
export def "telephony-credentials-token create" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/telephony_credentials/{id}/token"))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all TeXML Applications
#
# GET /texml_applications
# operationId: findTexmlApplications
export def "texml-applications find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
  --filter-friendly-name-contains: string # If present, applications with friendly_name containing the given value will be returned. Matching is not case-sensitive. Requires at least three characters. (default: null)
  --filter-outbound-voice-profile-id: string # Identifies the associated outbound voice profile. (format: int64, e.g. 1293384261075731499)
  --qp-sort: string@sort-completer-2 # Specifies the sort order for results. By default sorting direction is ascending. To have the results sorted in descending order add the - prefix. That is: connection_name: sorts the result by the connection_name field in ascending order. -connection_name: sorts the result by the connection_name field in descending order. If not given, results are sorted by created_at in descending order. (default: created_at, e.g. connection_name)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "filter[friendly_name][contains]" $filter_friendly_name_contains "scalar") (serialize-qp "filter[outbound_voice_profile_id]" $filter_outbound_voice_profile_id "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/texml_applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size, "filter[friendly_name][contains]": $filter_friendly_name_contains, "filter[outbound_voice_profile_id]": $filter_outbound_voice_profile_id, "sort": $qp_sort} | compact), body: null}
}

# Creates a TeXML Application
#
# POST /texml_applications
# operationId: CreateTexmlApplication
# --inbound shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
# --outbound shape: {channel_limit?: int, outbound_voice_profile_id?: string}
export def "texml-applications create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true, e.g. false)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --first-command-timeout: oneof<nothing, bool> # Specifies whether calls to phone numbers associated with this connection should hangup after timing out. (default: false, e.g. true)
  --first-command-timeout-secs: int # Specifies how many seconds to wait before timing out a dial command. (default: 30, e.g. 10)
  friendly_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --status-callback: string # URL for Telnyx to send requests to containing information about call progress events. (format: url, e.g. https://example.com)
  --status-callback-method: string@status-callback-method-completer # HTTP request method Telnyx should use when requesting the status_callback URL. (default: post, e.g. get)
  --voice-fallback-url: string # URL to which Telnyx will deliver your XML Translator webhooks if we get an error response from your voice_url. (format: url, e.g. https://fallback.example.com)
  --voice-method: string@voice-method-completer # HTTP request method Telnyx will use to interact with your XML Translator webhooks. Either 'get' or 'post'. (default: post, e.g. get)
  voice_url: string # URL to which Telnyx will deliver your XML Translator webhooks. (format: url, e.g. https://example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/texml_applications")
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "dtmf_type": $dtmf_type, "first_command_timeout": $first_command_timeout, "first_command_timeout_secs": $first_command_timeout_secs, "friendly_name": $friendly_name, "inbound": $inbound, "outbound": $outbound, "status_callback": $status_callback, "status_callback_method": $status_callback_method, "voice_fallback_url": $voice_fallback_url, "voice_method": $voice_method, "voice_url": $voice_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deletes a TeXML Application
#
# DELETE /texml_applications/{id}
# operationId: DeleteTexmlApplication
export def "texml-applications delete" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texml_applications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a TeXML Application
#
# GET /texml_applications/{id}
# operationId: getTexmlApplication
export def "texml-applications get" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texml_applications/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a TeXML Application
#
# PATCH /texml_applications/{id}
# operationId: UpdateTexmlApplication
# --inbound shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
# --outbound shape: {channel_limit?: int, outbound_voice_profile_id?: string}
export def "texml-applications update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool> # Specifies whether the connection can be used. (default: true, e.g. false)
  --anchorsite-override: string@anchorsite-override-completer-1 # `Latency` directs Telnyx to route media through the site with the lowest round-trip time to the user's connection. Telnyx calculates this time using ICMP ping messages. This can be disabled by specifying a site to handle all media. (default: Latency, e.g. Amsterdam, Netherlands)
  --dtmf-type: string@dtmf-type-completer # Sets the type of DTMF digits sent from Telnyx to this Connection. Note that DTMF digits sent to Telnyx will be accepted in all formats. (default: RFC 2833, e.g. Inband)
  --first-command-timeout: oneof<nothing, bool> # Specifies whether calls to phone numbers associated with this connection should hangup after timing out. (default: false, e.g. true)
  --first-command-timeout-secs: int # Specifies how many seconds to wait before timing out a dial command. (default: 30, e.g. 10)
  friendly_name: string # A user-assigned name to help manage the application. (e.g. call-router)
  --inbound: record # shape: {channel_limit?: int, sip_subdomain?: string, sip_subdomain_receive_settings?: "only_my_connections"|"from_anyone"}
  --outbound: record # shape: {channel_limit?: int, outbound_voice_profile_id?: string}
  --status-callback: string # URL for Telnyx to send requests to containing information about call progress events. (format: url, e.g. https://example.com)
  --status-callback-method: string@status-callback-method-completer # HTTP request method Telnyx should use when requesting the status_callback URL. (default: post, e.g. get)
  --voice-fallback-url: string # URL to which Telnyx will deliver your XML Translator webhooks if we get an error response from your voice_url. (format: url, e.g. https://fallback.example.com)
  --voice-method: string@voice-method-completer # HTTP request method Telnyx will use to interact with your XML Translator webhooks. Either 'get' or 'post'. (default: post, e.g. get)
  voice_url: string # URL to which Telnyx will deliver your XML Translator webhooks. (format: url, e.g. https://example.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/texml_applications/{id}"))
  let req_body = {"active": $active, "anchorsite_override": $anchorsite_override, "dtmf_type": $dtmf_type, "first_command_timeout": $first_command_timeout, "first_command_timeout_secs": $first_command_timeout_secs, "friendly_name": $friendly_name, "inbound": $inbound, "outbound": $outbound, "status_callback": $status_callback, "status_callback_method": $status_callback_method, "voice_fallback_url": $voice_fallback_url, "voice_method": $voice_method, "voice_url": $voice_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List verifications by phone number
#
# GET /verifications/by_phone_number/{phone_number}
# operationId: listVerifications
export def "verifications-by-phone-number list" [
  phone_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number | is-empty) { error make --unspanned { msg: "path parameter 'phone_number' must be non-empty" } }
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number)} | format pattern "/verifications/by_phone_number/{phone_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Submit a verification code
#
# POST /verifications/by_phone_number/{phone_number}/actions/verify
# operationId: verifyVerificationCode
export def "verifications-by-phone-number-actions-verify verify-code" [
  phone_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # This is the code the user submits for verification. (e.g. 17686)
]: any -> record<data: record<phone_number: string, response_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($phone_number | is-empty) { error make --unspanned { msg: "path parameter 'phone_number' must be non-empty" } }
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number)} | format pattern "/verifications/by_phone_number/{phone_number}/actions/verify"))
  let req_body = {"code": $code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Trigger a Call verification
#
# POST /verifications/call
# operationId: createVerificationCall
export def "verifications-call create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call-timeout-secs: int # Must be less than the profile's default_verification_timeout_secs or timeout_secs, whichever is lesser. (e.g. 30)
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verifications/call")
  let req_body = {"call_timeout_secs": $call_timeout_secs, "phone_number": $phone_number, "timeout_secs": $timeout_secs, "verify_profile_id": $verify_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Trigger a Flash call verification
#
# POST /verifications/flashcall
# operationId: createVerificationFlashcall
export def "verifications-flashcall create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verifications/flashcall")
  let req_body = {"phone_number": $phone_number, "timeout_secs": $timeout_secs, "verify_profile_id": $verify_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Trigger a PSD2 verification
#
# POST /verifications/psd2
# operationId: createVerificationPSD2
export def "verifications-psd2 create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: string # e.g. 99.99
  currency: string@currency-completer # The supported currencies. (e.g. USD)
  payee: string # e.g. Acme Corp Inc. LTD
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verifications/psd2")
  let req_body = {"amount": $amount, "currency": $currency, "payee": $payee, "phone_number": $phone_number, "timeout_secs": $timeout_secs, "verify_profile_id": $verify_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Trigger a SMS verification
#
# POST /verifications/sms
# operationId: createVerificationSMS
export def "verifications-sms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verifications/sms")
  let req_body = {"phone_number": $phone_number, "timeout_secs": $timeout_secs, "verify_profile_id": $verify_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Trigger a Whatsapp verification
#
# POST /verifications/whatsapp
# operationId: createVerificationWhatsapp
export def "verifications-whatsapp create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # +E164 formatted phone number. (e.g. +13035551234)
  --timeout-secs: int # The number of seconds the verification code is valid for. (e.g. 300)
  verify_profile_id: string # The identifier of the associated Verify profile. (format: uuid, e.g. 12ade33a-21c0-473b-b055-b3c836e1c292)
]: any -> record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verifications/whatsapp")
  let req_body = {"phone_number": $phone_number, "timeout_secs": $timeout_secs, "verify_profile_id": $verify_profile_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieve a verification
#
# GET /verifications/{verification_id}
# operationId: retrieveVerification
export def "verifications get" [
  verification_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<call_timeout_secs: int, created_at: string, id: string, phone_number: string, record_type: string, status: string, timeout_secs: int, updated_at: string, verification_type: string, verify_profile_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($verification_id | is-empty) { error make --unspanned { msg: "path parameter 'verification_id' must be non-empty" } }
  let full_url = (build-url $base ({verification_id: (encode-path-segment $verification_id)} | format pattern "/verifications/{verification_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List all Verify profiles
#
# GET /verify_profiles
# operationId: listVerifyProfiles
export def "verify-profiles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-name: string
  --page-size: int # default: 25
  --page-number: int # default: 1
]: nothing -> record<data: table<call: record, created_at: string, flashcall: record, id: string, language: string, name: string, psd2: record, record_type: string, sms: record, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[name]" $filter_name "scalar") (serialize-qp "page[size]" $page_size "scalar") (serialize-qp "page[number]" $page_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verify_profiles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[name]": $filter_name, "page[size]": $page_size, "page[number]": $page_number} | compact), body: null}
}

# Create a Verify profile
#
# POST /verify_profiles
# operationId: createVerifyProfile
# --call shape: {default_call_timeout_secs?: int, default_verification_timeout_secs?: int, speech_template?: string}
# --flashcall shape: {default_verification_timeout_secs?: int}
# --psd2 shape: {default_verification_timeout_secs?: int}
# --sms shape: {default_verification_timeout_secs?: int, messaging_enabled?: bool, messaging_template?: string, rcs_enabled?: bool, vsms_enabled?: bool}
# --whatsapp shape: {app_name?: string, default_verification_timeout_secs?: int}
export def "verify-profiles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call: record # shape: {default_call_timeout_secs?: int, default_verification_timeout_secs?: int, speech_template?: string}
  --flashcall: record # shape: {default_verification_timeout_secs?: int}
  --language: string # e.g. en-US
  name: string # e.g. Test Profile
  --psd2: record # shape: {default_verification_timeout_secs?: int}
  --sms: record # shape: {default_verification_timeout_secs?: int, messaging_enabled?: bool, messaging_template?: string, rcs_enabled?: bool, vsms_enabled?: bool}
  --webhook-failover-url: string # e.g. http://example.com/webhook/failover
  --webhook-url: string # e.g. http://example.com/webhook
  --whatsapp: record # shape: {app_name?: string, default_verification_timeout_secs?: int}
]: any -> record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verify_profiles")
  let req_body = {"call": $call, "flashcall": $flashcall, "language": $language, "name": $name, "psd2": $psd2, "sms": $sms, "webhook_failover_url": $webhook_failover_url, "webhook_url": $webhook_url, "whatsapp": $whatsapp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Verify profile
#
# DELETE /verify_profiles/{verify_profile_id}
# operationId: deleteVerifyProfile
export def "verify-profiles delete" [
  verify_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($verify_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'verify_profile_id' must be non-empty" } }
  let full_url = (build-url $base ({verify_profile_id: (encode-path-segment $verify_profile_id)} | format pattern "/verify_profiles/{verify_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve a Verify profile
#
# GET /verify_profiles/{verify_profile_id}
# operationId: retrieveVerifyProfile
export def "verify-profiles get" [
  verify_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($verify_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'verify_profile_id' must be non-empty" } }
  let full_url = (build-url $base ({verify_profile_id: (encode-path-segment $verify_profile_id)} | format pattern "/verify_profiles/{verify_profile_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a Verify profile
#
# PATCH /verify_profiles/{verify_profile_id}
# operationId: updateVerifyProfile
# --call shape: {default_call_timeout_secs?: int, default_verification_timeout_secs?: int, speech_template?: string}
# --flashcall shape: {default_verification_timeout_secs?: int}
# --psd2 shape: {default_verification_timeout_secs?: int}
# --sms shape: {default_verification_timeout_secs?: int, messaging_enabled?: bool, messaging_template?: string, rcs_enabled?: bool, vsms_enabled?: bool}
# --whatsapp shape: {app_name?: string, default_verification_timeout_secs?: int}
export def "verify-profiles update" [
  verify_profile_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --call: record # shape: {default_call_timeout_secs?: int, default_verification_timeout_secs?: int, speech_template?: string}
  --flashcall: record # shape: {default_verification_timeout_secs?: int}
  --language: string # e.g. en-US
  --name: string # e.g. Test Profile
  --psd2: record # shape: {default_verification_timeout_secs?: int}
  --sms: record # shape: {default_verification_timeout_secs?: int, messaging_enabled?: bool, messaging_template?: string, rcs_enabled?: bool, vsms_enabled?: bool}
  --webhook-failover-url: string # e.g. http://example.com/webhook/failover
  --webhook-url: string # e.g. http://example.com/webhook
  --whatsapp: record # shape: {app_name?: string, default_verification_timeout_secs?: int}
]: any -> record<data: record<call: record<default_call_timeout_secs: int, default_verification_timeout_secs: int, speech_template: string>, created_at: string, flashcall: record<default_verification_timeout_secs: int>, id: string, language: string, name: string, psd2: record<default_verification_timeout_secs: int>, record_type: string, sms: record<default_verification_timeout_secs: int, messaging_enabled: bool, messaging_template: string, rcs_enabled: bool, vsms_enabled: bool>, updated_at: string, webhook_failover_url: string, webhook_url: string, whatsapp: record<app_name: string, default_verification_timeout_secs: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($verify_profile_id | is-empty) { error make --unspanned { msg: "path parameter 'verify_profile_id' must be non-empty" } }
  let full_url = (build-url $base ({verify_profile_id: (encode-path-segment $verify_profile_id)} | format pattern "/verify_profiles/{verify_profile_id}"))
  let req_body = {"call": $call, "flashcall": $flashcall, "language": $language, "name": $name, "psd2": $psd2, "sms": $sms, "webhook_failover_url": $webhook_failover_url, "webhook_url": $webhook_url, "whatsapp": $whatsapp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List webhook deliveries
#
# GET /webhook_deliveries
# operationId: getWebhookDeliveries
export def "webhook-deliveries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-status-eq: string@filter-status-eq-completer-1 # Return only webhook_deliveries matching the given `status` (e.g. delivered)
  --filter-webhook-contains: string # Return only webhook deliveries whose `webhook` component contains the given text (e.g. call.initiated)
  --filter-attempts-contains: string # Return only webhook_deliveries whose `attempts` component contains the given text (e.g. https://fallback.example.com/webhooks)
  --filter-started-at-gte: string # Return only webhook_deliveries whose delivery started later than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --filter-started-at-lte: string # Return only webhook_deliveries whose delivery started earlier than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --filter-finished-at-gte: string # Return only webhook_deliveries whose delivery finished later than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --filter-finished-at-lte: string # Return only webhook_deliveries whose delivery finished earlier than or at given ISO 8601 datetime (e.g. 2019-03-29T11:10:00Z)
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter[status][eq]" $filter_status_eq "scalar") (serialize-qp "filter[webhook][contains]" $filter_webhook_contains "scalar") (serialize-qp "filter[attempts][contains]" $filter_attempts_contains "scalar") (serialize-qp "filter[started_at][gte]" $filter_started_at_gte "scalar") (serialize-qp "filter[started_at][lte]" $filter_started_at_lte "scalar") (serialize-qp "filter[finished_at][gte]" $filter_finished_at_gte "scalar") (serialize-qp "filter[finished_at][lte]" $filter_finished_at_lte "scalar") (serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhook_deliveries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filter[status][eq]": $filter_status_eq, "filter[webhook][contains]": $filter_webhook_contains, "filter[attempts][contains]": $filter_attempts_contains, "filter[started_at][gte]": $filter_started_at_gte, "filter[started_at][lte]": $filter_started_at_lte, "filter[finished_at][gte]": $filter_finished_at_gte, "filter[finished_at][lte]": $filter_finished_at_lte, "page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Find webhook_delivery details by ID
#
# GET /webhook_deliveries/{id}
# operationId: getWebhookDelivery
export def "webhook-deliveries get-delivery" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<attempts: list<record>, finished_at: string, id: string, record_type: string, started_at: string, status: string, user_id: string, webhook: record<event_type: string, id: string, occurred_at: string, payload: record, record_type: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/webhook_deliveries/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check Contact
#
# POST /whatsapp_contacts
# operationId: checkContact
export def "whatsapp-contacts check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --blocking: string@blocking-completer # Blocking determines whether the request should wait for the processing to complete (synchronous) or not (asynchronous). (default: no_wait)
  contacts: list<string> # Array of contact phone numbers. The numbers can be in any standard telephone number format.
  whatsapp_user_id: string # The sender's WhatsApp ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whatsapp_contacts")
  let req_body = {"blocking": $blocking, "contacts": $contacts, "whatsapp_user_id": $whatsapp_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Fetch all previous requests for WhatsApp detail reports. WhatsApp detail reports are reports for pulling all WhatsApp records.
#
# GET /whatsapp_detail_record_reports
# operationId: getRequests
export def "whatsapp-detail-record-reports get-requests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Page number (format: int32, default: 1)
  --page-size: int # Size of the page (format: int32, default: 20)
]: nothing -> record<data: table<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>, meta: record<page_number: int, page_size: int, total_pages: int, total_results: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whatsapp_detail_record_reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Submit a request for new WhatsApp detail report. WhatsApp detail report pulls all raw WhatsApp data according to defined filters.
#
# POST /whatsapp_detail_record_reports
# operationId: submitRequest
export def "whatsapp-detail-record-reports submit-request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  end_date: string # format: date-time, e.g. 2021-05-01T00:00:00-06:00
  start_date: string # format: date-time, e.g. 2021-05-01T00:00:00-06:00
]: any -> record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whatsapp_detail_record_reports")
  let req_body = {"end_date": $end_date, "start_date": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete generated WhatsApp detail report by id
#
# DELETE /whatsapp_detail_record_reports/{id}
# operationId: deleteRequest
export def "whatsapp-detail-record-reports delete-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/whatsapp_detail_record_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Fetch single whatsapp detail report by id.
#
# GET /whatsapp_detail_record_reports/{id}
# operationId: getRequest
export def "whatsapp-detail-record-reports get-request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<created_at: string, download_link: string, end_date: string, id: string, record_type: string, start_date: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/whatsapp_detail_record_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload Media
#
# POST /whatsapp_media
# operationId: uploadMedia
export def "whatsapp-media upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  media_content_type: string # The content-type of the uplaoded media.
  upload_file: string # The media to store with WhatsApp. (format: binary)
  whatsapp_user_id: string # The user's WhatsApp ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whatsapp_media")
  let req_body = {"media_content_type": $media_content_type, "upload_file": $upload_file, "whatsapp_user_id": $whatsapp_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["upload_file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete Media
#
# DELETE /whatsapp_media/{whatsapp_user_id}/{media_id}
export def "whatsapp-media delete" [
  whatsapp_user_id: string
  media_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($whatsapp_user_id | is-empty) { error make --unspanned { msg: "path parameter 'whatsapp_user_id' must be non-empty" } }
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media_id' must be non-empty" } }
  let full_url = (build-url $base ({whatsapp_user_id: (encode-path-segment $whatsapp_user_id), media_id: (encode-path-segment $media_id)} | format pattern "/whatsapp_media/{whatsapp_user_id}/{media_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download Media
#
# GET /whatsapp_media/{whatsapp_user_id}/{media_id}
export def "whatsapp-media get" [
  whatsapp_user_id: string
  media_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($whatsapp_user_id | is-empty) { error make --unspanned { msg: "path parameter 'whatsapp_user_id' must be non-empty" } }
  if ($media_id | is-empty) { error make --unspanned { msg: "path parameter 'media_id' must be non-empty" } }
  let full_url = (build-url $base ({whatsapp_user_id: (encode-path-segment $whatsapp_user_id), media_id: (encode-path-segment $media_id)} | format pattern "/whatsapp_media/{whatsapp_user_id}/{media_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send Message
#
# POST /whatsapp_messages
# operationId: sendMessage
# --audio shape: {id?: string, link?: string}
# --contacts item shape: {addresses?: list, birthday?: string, emails?: list, ims?: list<string>, name?: record, org?: record, phones?: list, urls?: list}
# --document shape: {caption?: string, filename?: string, id?: string, link?: string}
# --hsm shape: {element_name: string, language: record, localizable_params: list, namespace: string}
# --image shape: {caption?: string, id?: string, link?: string}
# --location shape: {address: string, latitude: string, longitude: string, name: string}
# --template shape: {components?: list, language: record, name: string, namespace: string}
# --text shape: {body: string}
# --video shape: {caption?: string, id?: string, link?: string}
export def "whatsapp-messages send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio: record # The media object containing audio details. (e.g. {id: f043afd0-f0ae-4b9c-ab3d-696fb4c8cd68}) — shape: {id?: string, link?: string}
  --contacts: list # item shape: {addresses?: list, birthday?: string, emails?: list, ims?: list<string>, name?: record, org?: record, phones?: list, urls?: list}
  --document: record # The media object containing a document reference (e.g. {caption: Very important document, filename: example.pdf, id: f043afd0-f0ae-4b9c-ab3d-696fb4c8cd68}) — shape: {caption?: string, filename?: string, id?: string, link?: string}
  --hsm: record # The containing element for the message content — Indicates that the message is highly structured. Parameters contained within provide the structure. (e.g. {element_name: hello_world, language: {code: en, policy: deterministic}, localizable_params: [{default: 1234}], namespace: business_a_namespace}) — shape: {element_name: string, language: record, localizable_params: list, namespace: string}
  --image: record # The media object containing an image (e.g. {caption: My cool media!, id: f043afd0-f0ae-4b9c-ab3d-696fb4c8cd68}) — shape: {caption?: string, id?: string, link?: string}
  --location: record # e.g. {address: <Location's Address>, latitude: <Latitude>, longitude: <Longitude>, name: <Location Name>} — shape: {address: string, latitude: string, longitude: string, name: string}
  --preview-url: oneof<nothing, bool> # Specifying preview_url in the request is optional when not including a URL in your message. To include a URL preview, set preview_url to true in the message body and make sure the URL begins with http:// or https://.
  --template: record # shape: {components?: list, language: record, name: string, namespace: string}
  --text: record # e.g. {body: <Message Text>} — shape: {body: string}
  --body-to: string # The WhatsApp ID (phone number) returned from contacts endpoint.
  --type: string@type-completer-2 # type of the message (default: text)
  --video: record # The media object containing a video (e.g. {caption: My cool media!, id: f043afd0-f0ae-4b9c-ab3d-696fb4c8cd68}) — shape: {caption?: string, id?: string, link?: string}
  whatsapp_user_id: string # The sender's WhatsApp ID.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/whatsapp_messages")
  let req_body = {"audio": $audio, "contacts": $contacts, "document": $document, "hsm": $hsm, "image": $image, "location": $location, "preview_url": $preview_url, "template": $template, "text": $text, "to": $body_to, "type": $type, "video": $video, "whatsapp_user_id": $whatsapp_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Mark Message As Read
#
# PATCH /whatsapp_messages/{message_id}
# operationId: markMessageAsRead
export def "whatsapp-messages get-mark-as" [
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string # default: read
  whatsapp_user_id: string # The user's WhatsApp ID. (e.g. 15125551212)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($message_id | is-empty) { error make --unspanned { msg: "path parameter 'message_id' must be non-empty" } }
  let full_url = (build-url $base ({message_id: (encode-path-segment $message_id)} | format pattern "/whatsapp_messages/{message_id}"))
  let req_body = {"status": $status, "whatsapp_user_id": $whatsapp_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate and fetch WhatsApp usage aggregations synchronously. This endpoint will both generate and fetch the WhatsApp aggregations over a specified time period.
#
# GET /whatsapp_usage_aggregations
# operationId: getUsageAggregationsSync
export def "whatsapp-usage-aggregations get-sync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
  --end-date: string # format: date-time, e.g. 2020-07-01T00:00:00-06:00
]: nothing -> record<data: table<cost: record, count: string, direction: string, message_type: string, recipient_country_code: string, record_type: string, status: string, telnyx_fee: record, whatsapp_fee: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/whatsapp_usage_aggregations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start_date": $start_date, "end_date": $end_date} | compact), body: null}
}

# Get User
#
# GET /whatsapp_users/{whatsapp_user_id}
# operationId: getUser
export def "whatsapp-users get" [
  whatsapp_user_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($whatsapp_user_id | is-empty) { error make --unspanned { msg: "path parameter 'whatsapp_user_id' must be non-empty" } }
  let full_url = (build-url $base ({whatsapp_user_id: (encode-path-segment $whatsapp_user_id)} | format pattern "/whatsapp_users/{whatsapp_user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update WhatsApp User
#
# PATCH /whatsapp_users/{whatsapp_user_id}
# operationId: updateWhatsAppWebhook
export def "whatsapp-users update-whats-app-webhook" [
  whatsapp_user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  webhook_url: string # The desired URL to set for your WhatsApp webhook endpoint. (e.g. https://mywebhook.com/example/endpoint)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($whatsapp_user_id | is-empty) { error make --unspanned { msg: "path parameter 'whatsapp_user_id' must be non-empty" } }
  let full_url = (build-url $base ({whatsapp_user_id: (encode-path-segment $whatsapp_user_id)} | format pattern "/whatsapp_users/{whatsapp_user_id}"))
  let req_body = {"webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all Wireless Detail Records (WDRs) Reports
#
# GET /wireless/detail_records_reports
# operationId: getWdrReports
export def "wireless-detail-records-reports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number to load. (default: 1)
  --page-size: int # The size of the page. (default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[number]" $page_number "scalar") (serialize-qp "page[size]" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wireless/detail_records_reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page[number]": $page_number, "page[size]": $page_size} | compact), body: null}
}

# Create a Wireless Detail Records (WDRs) Report
#
# POST /wireless/detail_records_reports
# operationId: createWdrReport
export def "wireless-detail-records-reports create-wdr" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-time: string # ISO 8601 formatted date-time indicating the end time. (e.g. 2018-02-02T22:25:27.521Z)
  --start-time: string # ISO 8601 formatted date-time indicating the start time. (e.g. 2018-02-02T22:25:27.521Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/wireless/detail_records_reports")
  let req_body = {"end_time": $end_time, "start_time": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a Wireless Detail Record (WDR) Report
#
# DELETE /wireless/detail_records_reports/{id}
# operationId: deleteWdrReport
export def "wireless-detail-records-reports delete-wdr" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/wireless/detail_records_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a Wireless Detail Record (WDR) Report
#
# GET /wireless/detail_records_reports/{id}
# operationId: getWdrReport
export def "wireless-detail-records-reports get-wdr" [
  id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/wireless/detail_records_reports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
