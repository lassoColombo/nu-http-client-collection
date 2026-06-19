# Auto-generated client for Numbers API v1.0.20
# Source: https://api.apis.guru/v2/specs/nexmo.com/numbers/1.0.20/openapi.json
# Auth: --token flag or $env.NUMBERS_API_TOKEN

const BASE_URL = "https://rest.nexmo.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NUMBERS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
    "query-api_secret" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_secret")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://rest.nexmo.com"] }
def auth-scheme-completer [] { ["query-api_key" "query-api_secret"] }

# Completers for enum parameters
def search-pattern-completer [] { ["0" "1" "2"] }
def accept-completer [] { ["application/json" "text/xml"] }
def type-completer [] { ["landline" "landline-toll-free" "mobile-lvn"] }
def features-completer [] { ["MMS" "SMS" "SMS,MMS" "SMS,MMS,VOICE" "SMS,VOICE" "VOICE" "VOICE,MMS"] }
def messages-callback-type-completer [] { ["app"] }
def voice-callback-type-completer [] { ["app" "sip" "tel"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-numbers get-owned" } } | get name | first)
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

# List the numbers you own
#
# GET /account/numbers
# operationId: getOwnedNumbers
export def "account-numbers get-owned" [
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
  --application-id: string # The Application that you want to return the numbers for. (e.g. aaaaaaaa-bbbb-cccc-dddd-0123456789ab)
  --has-application: oneof<nothing, bool> # Set this optional field to `true` to restrict your results to numbers associated with an Application (any Application). Set to `false` to find all numbers not associated with any Application. Omit the field to avoid filtering on whether or not the number is assigned to an Application. (e.g. false)
  --country: string # e.g. GB
  --pattern: string # The number pattern you want to search for. Use in conjunction with `search_pattern`. (e.g. 12345)
  --search-pattern: int@search-pattern-completer # The strategy you want to use for matching: * `0` - Search for numbers that start with `pattern` (Note: all numbers are in E.164 format, so the starting pattern includes the country code, such as 1 for USA) * `1` - Search for numbers that contain `pattern` * `2` - Search for numbers that end with `pattern` (default: 0, e.g. 1)
  --size: int # Page size (default: 10, e.g. 10)
  --index: int # Page index (default: 1, e.g. 1)
]: nothing -> record<count: int, numbers: table<country: string, features: list, messagesCallbackType: string, messagesCallbackValue: string, moHttpUrl: string, msisdn: string, type: string, voiceCallbackType: string, voiceCallbackValue: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "application_id" $application_id "scalar") (serialize-qp "has_application" $has_application "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "pattern" $pattern "scalar") (serialize-qp "search_pattern" $search_pattern "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "index" $index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/numbers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"application_id": $application_id, "has_application": $has_application, "country": $country, "pattern": $pattern, "search_pattern": $search_pattern, "size": $size, "index": $index} | compact), body: null}
}

# Buy a number
#
# POST /number/buy
# operationId: buyANumber
export def "number-buy create" [
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
  country: string # The two character country code in ISO 3166-1 alpha-2 format (e.g. GB)
  msisdn: string # An available inbound virtual number. (e.g. 447700900000)
  --target-api-key: string # If you’d like to perform an action on a subaccount, provide the `api_key` of that account here. If you’d like to perform an action on your own account, you do not need to provide this field. (e.g. 1a2345b7)
]: any -> record<error_code: string, error_code_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/number/buy")
  let req_body = {"country": $country, "msisdn": $msisdn, "target_api_key": $target_api_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Cancel a number
#
# POST /number/cancel
# operationId: cancelANumber
export def "number-cancel cancel" [
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
  country: string # The two character country code in ISO 3166-1 alpha-2 format (e.g. GB)
  msisdn: string # An available inbound virtual number. (e.g. 447700900000)
  --target-api-key: string # If you’d like to perform an action on a subaccount, provide the `api_key` of that account here. If you’d like to perform an action on your own account, you do not need to provide this field. (e.g. 1a2345b7)
]: any -> record<error_code: string, error_code_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/number/cancel")
  let req_body = {"country": $country, "msisdn": $msisdn, "target_api_key": $target_api_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Search available numbers
#
# GET /number/search
# operationId: getAvailableNumbers
export def "number-search get-available" [
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
  --country: string # The two character country code to filter on (in ISO 3166-1 alpha-2 format) (e.g. GB)
  --type: string@type-completer # Set this parameter to filter the type of number, such as mobile or landline (e.g. mobile-lvn)
  --pattern: string # The number pattern you want to search for. Use in conjunction with `search_pattern`. (e.g. 12345)
  --search-pattern: int@search-pattern-completer # The strategy you want to use for matching: * `0` - Search for numbers that start with `pattern` (Note: all numbers are in E.164 format, so the starting pattern includes the country code, such as 1 for USA) * `1` - Search for numbers that contain `pattern` * `2` - Search for numbers that end with `pattern` (default: 0, e.g. 1)
  --features: string@features-completer # Available features are `SMS`, `VOICE` and `MMS`. To look for numbers that support multiple features, use a comma-separated value: `SMS,MMS,VOICE`. (e.g. SMS)
  --size: int # Page size (default: 10, e.g. 10)
  --index: int # Page index (default: 1, e.g. 1)
]: nothing -> record<count: int, numbers: table<cost: string, country: string, features: list, msisdn: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "pattern" $pattern "scalar") (serialize-qp "search_pattern" $search_pattern "scalar") (serialize-qp "features" $features "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "index" $index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/number/search" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"country": $country, "type": $type, "pattern": $pattern, "search_pattern": $search_pattern, "features": $features, "size": $size, "index": $index} | compact), body: null}
}

# Update a number
#
# POST /number/update
# operationId: updateANumber
@deprecated --flag messages-callback-type
@deprecated --flag messages-callback-value
export def "number-update update" [
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
  --app-id: string # The Application that will handle inbound traffic to this number. (e.g. aaaaaaaa-bbbb-cccc-dddd-0123456789abc)
  country: string # The two character country code in ISO 3166-1 alpha-2 format (e.g. GB)
  --messages-callback-type: string@messages-callback-type-completer # DEPRECATED - We recommend that you use `app_id` instead. Specifies the Messages webhook type (always `app`) associated with this number and must be used with the `messagesCallbackValue` parameter. (DEPRECATED, e.g. app)
  --messages-callback-value: string # DEPRECATED - We recommend that you use `app_id` instead. Specifies the Application ID of your Messages application. It must be used with the `messagesCallbackType` parameter. (DEPRECATED, e.g. aaaaaaaa-bbbb-cccc-dddd-0123456789ab)
  --mo-http-url: string # An URL-encoded URI to the webhook endpoint that handles inbound messages. Your webhook endpoint must be active before you make this request. Vonage makes a `GET` request to the endpoint and checks that it returns a `200 OK` response. Set this parameter's value to an empty string to remove the webhook. (e.g. https://example.com/webhooks/inbound-sms)
  --mo-smpp-sys-type: string # The associated system type for your SMPP client (e.g. inbound)
  msisdn: string # An available inbound virtual number. (e.g. 447700900000)
  --voice-callback-type: string@voice-callback-type-completer # Specify whether inbound voice calls on your number are forwarded to a SIP or a telephone number. This must be used with the `voiceCallbackValue` parameter. If set, `sip` or `tel` are prioritized over the Voice capability in your Application. *Note: The `app` value is deprecated and will be removed in future.* (e.g. tel)
  --voice-callback-value: string # A SIP URI or telephone number. Must be used with the `voiceCallbackType` parameter. (e.g. 447700900000)
  --voice-status-callback: string # A webhook URI for Vonage to send a request to when a call ends (e.g. https://example.com/webhooks/status)
]: any -> record<error_code: string, error_code_label: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/number/update")
  let req_body = {"app_id": $app_id, "country": $country, "messagesCallbackType": $messages_callback_type, "messagesCallbackValue": $messages_callback_value, "moHttpUrl": $mo_http_url, "moSmppSysType": $mo_smpp_sys_type, "msisdn": $msisdn, "voiceCallbackType": $voice_callback_type, "voiceCallbackValue": $voice_callback_value, "voiceStatusCallback": $voice_status_callback} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = ($req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}
