# Auto-generated client for Twilio - Wireless v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_wireless_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_WIRELESS_TOKEN

const BASE_URL = "https://wireless.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_WIRELESS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://wireless.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Status-completer [] { ["delivered" "failed" "queued" "received" "sent"] }
def Direction-completer [] { ["from_sim" "to_sim"] }
def Transport-completer [] { ["ip" "sms"] }
def CallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def CommandMode-completer [] { ["binary" "text"] }
def Status-completer-1 [] { ["active" "canceled" "deactivated" "new" "ready" "scheduled" "suspended" "updating"] }
def CommandsCallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def ResetStatus-completer [] { ["resetting"] }
def SmsFallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def SmsMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def VoiceFallbackMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def VoiceMethod-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def Granularity-completer [] { ["all" "daily" "hourly"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "commands ListCommand" } } | get name | first)
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

# Retrieve a list of Commands from your account.
#
# GET /v1/Commands
# operationId: ListCommand
export def "commands ListCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Sim: string # The `sid` or `unique_name` of the [Sim resources](https://www.twilio.com/docs/wireless/api/sim-resource) to read.
  --Status: string@Status-completer # The status of the resources to read. Can be: `queued`, `sent`, `delivered`, `received`, or `failed`.
  --Direction: string@Direction-completer # Only return Commands with this direction value.
  --Transport: string@Transport-completer # Only return Commands with this transport value. Can be: `sms` or `ip`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<commands: table<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, delivery_receipt_requested: bool, direction: string, sid: string, sim_sid: string, status: string, transport: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let qp = [(serialize-qp "Sim" $Sim "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "Direction" $Direction "scalar") (serialize-qp "Transport" $Transport "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Commands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a Command to a Sim.
#
# POST /v1/Commands
# operationId: CreateCommand
export def "commands CreateCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CallbackMethod: string@CallbackMethod-completer # The HTTP method we use to call `callback_url`. Can be: `POST` or `GET`, and the default is `POST`. (format: http-method)
  --CallbackUrl: string # The URL we call using the `callback_url` when the Command has finished sending, whether the command was delivered or it failed. (format: uri)
  Command: string # The message body of the Command. Can be plain text in text mode or a Base64 encoded byte string in binary mode.
  --CommandMode: string@CommandMode-completer
  --DeliveryReceiptRequested: oneof<nothing, bool> # Whether to request delivery receipt from the recipient. For Commands that request delivery receipt, the Command state transitions to 'delivered' once the server has received a delivery receipt from the device. The default value is `true`.
  --IncludeSid: string # Whether to include the SID of the command in the message body. Can be: `none`, `start`, or `end`, and the default behavior is `none`. When sending a Command to a SIM in text mode, we can automatically include the SID of the Command in the message body, which could be used to ensure that the device does not process the same Command more than once.  A value of `start` will prepend the message with the Command SID, and `end` will append it to the end, separating the Command SID from the message body with a space. The length of the Command SID is included in the 160 character limit so the SMS body must be 128 characters or less before the Command SID is included.
  --Sim: string # The `sid` or `unique_name` of the [SIM](https://www.twilio.com/docs/wireless/api/sim-resource) to send the Command to.
]: any -> record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, delivery_receipt_requested: bool, direction: string, sid: string, sim_sid: string, status: string, transport: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base "/v1/Commands")
  let body = {CallbackMethod: $CallbackMethod, CallbackUrl: $CallbackUrl, Command: $Command, CommandMode: $CommandMode, DeliveryReceiptRequested: $DeliveryReceiptRequested, IncludeSid: $IncludeSid, Sim: $Sim} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a Command instance from your account.
#
# DELETE /v1/Commands/{Sid}
# operationId: DeleteCommand
export def "commands DeleteCommand" [
  Sid: string
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
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base $"/v1/Commands/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a Command instance from your account.
#
# GET /v1/Commands/{Sid}
# operationId: FetchCommand
export def "commands FetchCommand" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, command: string, command_mode: string, date_created: string, date_updated: string, delivery_receipt_requested: bool, direction: string, sid: string, sim_sid: string, status: string, transport: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base $"/v1/Commands/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/RatePlans
#
# operationId: ListRatePlan
export def "rate-plans ListRatePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rate_plans: table<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list, international_roaming_data_limit: int, messaging_enabled: bool, national_roaming_data_limit: int, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/RatePlans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/RatePlans
#
# operationId: CreateRatePlan
export def "rate-plans CreateRatePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DataEnabled: oneof<nothing, bool> # Whether SIMs can use GPRS/3G/4G/LTE data connectivity.
  --DataLimit: int # The total data usage (download and upload combined) in Megabytes that the Network allows during one month on the home network (T-Mobile USA). The metering period begins the day of activation and ends on the same day in the following month. Can be up to 2TB and the default value is `1000`.
  --DataMetering: string # The model used to meter data usage. Can be: `payg` and `quota-1`, `quota-10`, and `quota-50`. Learn more about the available [data metering models](https://www.twilio.com/docs/wireless/api/rateplan-resource#payg-vs-quota-data-plans).
  --FriendlyName: string # A descriptive string that you create to describe the resource. It does not have to be unique.
  --InternationalRoaming: list # The list of services that SIMs capable of using GPRS/3G/4G/LTE data connectivity can use outside of the United States. Can contain: `data` and `messaging`.
  --InternationalRoamingDataLimit: int # The total data usage (download and upload combined) in Megabytes that the Network allows during one month when roaming outside the United States. Can be up to 2TB.
  --MessagingEnabled: oneof<nothing, bool> # Whether SIMs can make, send, and receive SMS using [Commands](https://www.twilio.com/docs/wireless/api/command-resource).
  --NationalRoamingDataLimit: int # The total data usage (download and upload combined) in Megabytes that the Network allows during one month on non-home networks in the United States. The metering period begins the day of activation and ends on the same day in the following month. Can be up to 2TB. See [national roaming](https://www.twilio.com/docs/wireless/api/rateplan-resource#national-roaming) for more info.
  --NationalRoamingEnabled: oneof<nothing, bool> # Whether SIMs can roam on networks other than the home network (T-Mobile USA) in the United States. See [national roaming](https://www.twilio.com/docs/wireless/api/rateplan-resource#national-roaming).
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
  --VoiceEnabled: oneof<nothing, bool> # Deprecated.
]: any -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, international_roaming_data_limit: int, messaging_enabled: bool, national_roaming_data_limit: int, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base "/v1/RatePlans")
  let body = {DataEnabled: $DataEnabled, DataLimit: $DataLimit, DataMetering: $DataMetering, FriendlyName: $FriendlyName, InternationalRoaming: $InternationalRoaming, InternationalRoamingDataLimit: $InternationalRoamingDataLimit, MessagingEnabled: $MessagingEnabled, NationalRoamingDataLimit: $NationalRoamingDataLimit, NationalRoamingEnabled: $NationalRoamingEnabled, UniqueName: $UniqueName, VoiceEnabled: $VoiceEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/RatePlans/{Sid}
#
# operationId: DeleteRatePlan
export def "rate-plans DeleteRatePlan" [
  Sid: string
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
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base $"/v1/RatePlans/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/RatePlans/{Sid}
#
# operationId: FetchRatePlan
export def "rate-plans FetchRatePlan" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, international_roaming_data_limit: int, messaging_enabled: bool, national_roaming_data_limit: int, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base $"/v1/RatePlans/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/RatePlans/{Sid}
#
# operationId: UpdateRatePlan
export def "rate-plans UpdateRatePlan" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # A descriptive string that you create to describe the resource. It does not have to be unique.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used in place of the resource's `sid` in the URL to address the resource.
]: any -> record<account_sid: string, data_enabled: bool, data_limit: int, data_metering: string, date_created: string, date_updated: string, friendly_name: string, international_roaming: list<string>, international_roaming_data_limit: int, messaging_enabled: bool, national_roaming_data_limit: int, national_roaming_enabled: bool, sid: string, unique_name: string, url: string, voice_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base $"/v1/RatePlans/($Sid)")
  let body = {FriendlyName: $FriendlyName, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of Sim resources on your Account.
#
# GET /v1/Sims
# operationId: ListSim
export def "sims ListSim" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Status: string@Status-completer-1 # Only return Sim resources with this status.
  --Iccid: string # Only return Sim resources with this ICCID. This will return a list with a maximum size of 1.
  --RatePlan: string # The SID or unique name of a [RatePlan resource](https://www.twilio.com/docs/wireless/api/rateplan-resource). Only return Sim resources assigned to this RatePlan resource.
  --EId: string # Deprecated.
  --SimRegistrationCode: string # Only return Sim resources with this registration code. This will return a list with a maximum size of 1.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sims: table<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, ip_address: string, links: record, rate_plan_sid: string, reset_status: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let qp = [(serialize-qp "Status" $Status "scalar") (serialize-qp "Iccid" $Iccid "scalar") (serialize-qp "RatePlan" $RatePlan "scalar") (serialize-qp "EId" $EId "scalar") (serialize-qp "SimRegistrationCode" $SimRegistrationCode "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Sims" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Sim resource on your Account.
#
# DELETE /v1/Sims/{Sid}
# operationId: DeleteSim
export def "sims DeleteSim" [
  Sid: string
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
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base $"/v1/Sims/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a Sim resource on your Account.
#
# GET /v1/Sims/{Sid}
# operationId: FetchSim
export def "sims FetchSim" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, ip_address: string, links: record, rate_plan_sid: string, reset_status: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base $"/v1/Sims/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the given properties of a Sim resource on your Account.
#
# POST /v1/Sims/{Sid}
# operationId: UpdateSim
export def "sims UpdateSim" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --AccountSid: string # The SID of the [Account](https://www.twilio.com/docs/iam/api/account) to which the Sim resource should belong. The Account SID can only be that of the requesting Account or that of a [Subaccount](https://www.twilio.com/docs/iam/api/subaccounts) of the requesting Account. Only valid when the Sim resource's status is `new`. For more information, see the [Move SIMs between Subaccounts documentation](https://www.twilio.com/docs/wireless/api/sim-resource#move-sims-between-subaccounts).
  --CallbackMethod: string@CallbackMethod-completer # The HTTP method we should use to call `callback_url`. Can be: `POST` or `GET`. The default is `POST`. (format: http-method)
  --CallbackUrl: string # The URL we should call using the `callback_url` when the SIM has finished updating. When the SIM transitions from `new` to `ready` or from any status to `deactivated`, we call this URL when the status changes to an intermediate status (`ready` or `deactivated`) and again when the status changes to its final status (`active` or `canceled`). (format: uri)
  --CommandsCallbackMethod: string@CommandsCallbackMethod-completer # The HTTP method we should use to call `commands_callback_url`. Can be: `POST` or `GET`. The default is `POST`. (format: http-method)
  --CommandsCallbackUrl: string # The URL we should call using the `commands_callback_method` when the SIM sends a [Command](https://www.twilio.com/docs/wireless/api/command-resource). Your server should respond with an HTTP status code in the 200 range; any response body is ignored. (format: uri)
  --FriendlyName: string # A descriptive string that you create to describe the Sim resource. It does not need to be unique.
  --RatePlan: string # The SID or unique name of the [RatePlan resource](https://www.twilio.com/docs/wireless/api/rateplan-resource) to which the Sim resource should be assigned.
  --ResetStatus: string@ResetStatus-completer
  --SmsFallbackMethod: string@SmsFallbackMethod-completer # The HTTP method we should use to call `sms_fallback_url`. Can be: `GET` or `POST`. Default is `POST`. (format: http-method)
  --SmsFallbackUrl: string # The URL we should call using the `sms_fallback_method` when an error occurs while retrieving or executing the TwiML requested from `sms_url`. (format: uri)
  --SmsMethod: string@SmsMethod-completer # The HTTP method we should use to call `sms_url`. Can be: `GET` or `POST`. Default is `POST`. (format: http-method)
  --SmsUrl: string # The URL we should call using the `sms_method` when the SIM-connected device sends an SMS message that is not a [Command](https://www.twilio.com/docs/wireless/api/command-resource). (format: uri)
  --Status: string@Status-completer-1
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used in place of the `sid` in the URL path to address the resource.
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # Deprecated. (format: http-method)
  --VoiceFallbackUrl: string # Deprecated. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # Deprecated. (format: http-method)
  --VoiceUrl: string # Deprecated. (format: uri)
]: any -> record<account_sid: string, commands_callback_method: string, commands_callback_url: string, date_created: string, date_updated: string, e_id: string, friendly_name: string, iccid: string, ip_address: string, links: record, rate_plan_sid: string, reset_status: string, sid: string, sms_fallback_method: string, sms_fallback_url: string, sms_method: string, sms_url: string, status: string, unique_name: string, url: string, voice_fallback_method: string, voice_fallback_url: string, voice_method: string, voice_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let full_url = (build-url $base $"/v1/Sims/($Sid)")
  let body = {AccountSid: $AccountSid, CallbackMethod: $CallbackMethod, CallbackUrl: $CallbackUrl, CommandsCallbackMethod: $CommandsCallbackMethod, CommandsCallbackUrl: $CommandsCallbackUrl, FriendlyName: $FriendlyName, RatePlan: $RatePlan, ResetStatus: $ResetStatus, SmsFallbackMethod: $SmsFallbackMethod, SmsFallbackUrl: $SmsFallbackUrl, SmsMethod: $SmsMethod, SmsUrl: $SmsUrl, Status: $Status, UniqueName: $UniqueName, VoiceFallbackMethod: $VoiceFallbackMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceMethod: $VoiceMethod, VoiceUrl: $VoiceUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Sims/{SimSid}/DataSessions
#
# operationId: ListDataSession
export def "sims-data-sessions ListDataSession" [
  SimSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<data_sessions: table<account_sid: string, cell_id: string, cell_location_estimate: any, end: string, imei: string, last_updated: string, operator_country: string, operator_mcc: string, operator_mnc: string, operator_name: string, packets_downloaded: int, packets_uploaded: int, radio_link: string, sid: string, sim_sid: string, start: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Sims/($SimSid)/DataSessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Sims/{SimSid}/UsageRecords
#
# operationId: ListUsageRecord
export def "sims-usage-records ListUsageRecord" [
  SimSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --End: string # Only include usage that occurred on or before this date, specified in [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html). The default is the current time. (format: date-time)
  --Start: string # Only include usage that has occurred on or after this date, specified in [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html). The default is one month before the `end` parameter value. (format: date-time)
  --Granularity: string@Granularity-completer # How to summarize the usage by time. Can be: `daily`, `hourly`, or `all`. The default is `all`. A value of `all` returns one Usage Record that describes the usage for the entire period.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, usage_records: table<account_sid: string, commands: any, data: any, period: any, sim_sid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let qp = [(serialize-qp "End" $End "scalar") (serialize-qp "Start" $Start "scalar") (serialize-qp "Granularity" $Granularity "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Sims/($SimSid)/UsageRecords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/UsageRecords
#
# operationId: ListAccountUsageRecord
export def "usage-records ListAccountUsageRecord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --End: string # Only include usage that has occurred on or before this date. Format is [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html). (format: date-time)
  --Start: string # Only include usage that has occurred on or after this date. Format is [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html). (format: date-time)
  --Granularity: string@Granularity-completer # How to summarize the usage by time. Can be: `daily`, `hourly`, or `all`. A value of `all` returns one Usage Record that describes the usage for the entire period.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, usage_records: table<account_sid: string, commands: any, data: any, period: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://wireless.twilio.com")
  let qp = [(serialize-qp "End" $End "scalar") (serialize-qp "Start" $Start "scalar") (serialize-qp "Granularity" $Granularity "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/UsageRecords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
