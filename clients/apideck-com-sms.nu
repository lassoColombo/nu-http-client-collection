# Auto-generated client for SMS API v9.3.0
# Source: https://api.apis.guru/v2/specs/apideck.com/sms/9.3.0/openapi.json
# Auth: --token flag or $env.SMS_API_TOKEN

const BASE_URL = "https://unify.apideck.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SMS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://unify.apideck.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["mms" "sms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sms-messages list" } } | get name | first)
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

# List Messages
#
# GET /sms/messages
# operationId: messagesAll
export def "sms-messages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --cursor: string # Cursor to start from. You can find cursors for next/previous pages in the meta.cursors property of the response. (nullable)
  --limit: int # Number of results to return. Minimum 1, Maximum 200, Default 20 (default: 20)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sms/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Message
#
# POST /sms/messages
# operationId: messagesAdd
# --price shape: {currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH"}
export def "sms-messages create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  body: string # The message text. (e.g. Hi! How are you doing?)
  --body-from: string # The phone number that initiated the message. (e.g. +15017122661)
  --messaging-service-id: string # The ID of the Messaging Service used with the message. In case of Plivo this links to the Powerpack ID. (e.g. 123456)
  --reference: string # A client reference. (e.g. CUST001)
  --scheduled-at: string # The scheduled date and time of the message. (format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --subject: string # e.g. Picture
  --body-to: string # The phone number that received the message. (e.g. +15017122662)
  --type: string@type-completer # Set to sms for SMS messages and mms for MMS messages. (e.g. sms)
  --webhook-url: string # Define a webhook to receive delivery notifications. (e.g. https://unify.apideck.com/webhook/webhooks/eyz329dkffdl4949/x/sms)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sms/messages" $qp)
  let req_body = {"body": $body, "from": $body_from, "messaging_service_id": $messaging_service_id, "reference": $reference, "scheduled_at": $scheduled_at, "subject": $subject, "to": $body_to, "type": $type, "webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Message
#
# DELETE /sms/messages/{id}
# operationId: messagesDelete
export def "sms-messages delete" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sms/messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get Message
#
# GET /sms/messages/{id}
# operationId: messagesOne
export def "sms-messages get-one" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --fields: string # The 'fields' parameter allows API users to specify the fields they want to include in the API response. If this parameter is not present, the API will return all available fields. If this parameter is present, only the fields specified in the comma-separated string will be included in the response. Nested properties can also be requested by using a dot notation. Example: `fields=name,email,addresses.city`In the example above, the response will only include the fields "name", "email" and "addresses.city". If any other fields are available, they will be excluded. (nullable, e.g. id,updated_at)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sms/messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update Message
#
# PATCH /sms/messages/{id}
# operationId: messagesUpdate
# --price shape: {currency?: "UNKNOWN_CURRENCY"|"AED"|"AFN"|"ALL"|"AMD"|"ANG"|"AOA"|"ARS"|"AUD"|"AWG"|"AZN"|"BAM"|"BBD"|"BDT"|"BGN"|"BHD"|"BIF"|"BMD"|"BND"|"BOB"|"BOV"|"BRL"|"BSD"|"BTN"|"BWP"|"BYR"|"BZD"|"CAD"|"CDF"|"CHE"|"CHF"|"CHW"|"CLF"|"CLP"|"CNY"|"COP"|"COU"|"CRC"|"CUC"|"CUP"|"CVE"|"CZK"|"DJF"|"DKK"|"DOP"|"DZD"|"EGP"|"ERN"|"ETB"|"EUR"|"FJD"|"FKP"|"GBP"|"GEL"|"GHS"|"GIP"|"GMD"|"GNF"|"GTQ"|"GYD"|"HKD"|"HNL"|"HRK"|"HTG"|"HUF"|"IDR"|"ILS"|"INR"|"IQD"|"IRR"|"ISK"|"JMD"|"JOD"|"JPY"|"KES"|"KGS"|"KHR"|"KMF"|"KPW"|"KRW"|"KWD"|"KYD"|"KZT"|"LAK"|"LBP"|"LKR"|"LRD"|"LSL"|"LTL"|"LVL"|"LYD"|"MAD"|"MDL"|"MGA"|"MKD"|"MMK"|"MNT"|"MOP"|"MRO"|"MUR"|"MVR"|"MWK"|"MXN"|"MXV"|"MYR"|"MZN"|"NAD"|"NGN"|"NIO"|"NOK"|"NPR"|"NZD"|"OMR"|"PAB"|"PEN"|"PGK"|"PHP"|"PKR"|"PLN"|"PYG"|"QAR"|"RON"|"RSD"|"RUB"|"RWF"|"SAR"|"SBD"|"SCR"|"SDG"|"SEK"|"SGD"|"SHP"|"SLL"|"SOS"|"SRD"|"SSP"|"STD"|"SVC"|"SYP"|"SZL"|"THB"|"TJS"|"TMT"|"TND"|"TOP"|"TRC"|"TRY"|"TTD"|"TWD"|"TZS"|"UAH"|"UGX"|"USD"|"USN"|"USS"|"UYI"|"UYU"|"UZS"|"VEF"|"VND"|"VUV"|"WST"|"XAF"|"XAG"|"XAU"|"XBA"|"XBB"|"XBC"|"XBD"|"XCD"|"XDR"|"XOF"|"XPD"|"XPF"|"XPT"|"XTS"|"XXX"|"YER"|"ZAR"|"ZMK"|"ZMW"|"BTC"|"ETH"}
export def "sms-messages update" [
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
  --qp-raw: oneof<nothing, bool> # Include raw response. Mostly used for debugging purposes (default: false)
  --x-apideck-consumer-id: string # ID of the consumer which you want to get or push data from
  --x-apideck-app-id: string # The ID of your Unify application (e.g. dSBdXd2H6Mqwfg0atXHXYcysLJE9qyn1VwBtXHX)
  --x-apideck-service-id: string # Provide the service id you want to call (e.g., pipedrive). Only needed when a consumer has activated multiple integrations for a Unified API.
  body: string # The message text. (e.g. Hi! How are you doing?)
  --body-from: string # The phone number that initiated the message. (e.g. +15017122661)
  --messaging-service-id: string # The ID of the Messaging Service used with the message. In case of Plivo this links to the Powerpack ID. (e.g. 123456)
  --reference: string # A client reference. (e.g. CUST001)
  --scheduled-at: string # The scheduled date and time of the message. (format: date-time, e.g. 2020-09-30T07:43:32.000Z)
  --subject: string # e.g. Picture
  --body-to: string # The phone number that received the message. (e.g. +15017122662)
  --type: string@type-completer # Set to sms for SMS messages and mms for MMS messages. (e.g. sms)
  --webhook-url: string # Define a webhook to receive delivery notifications. (e.g. https://unify.apideck.com/webhook/webhooks/eyz329dkffdl4949/x/sms)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/sms/messages/{id}") $qp)
  let req_body = {"body": $body, "from": $body_from, "messaging_service_id": $messaging_service_id, "reference": $reference, "scheduled_at": $scheduled_at, "subject": $subject, "to": $body_to, "type": $type, "webhook_url": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-apideck-consumer-id": $x_apideck_consumer_id, "x-apideck-app-id": $x_apideck_app_id, "x-apideck-service-id": $x_apideck_service_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
