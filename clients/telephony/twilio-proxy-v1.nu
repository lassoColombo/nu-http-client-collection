# Auto-generated client for Twilio - Proxy v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_proxy_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_PROXY_TOKEN

const BASE_URL = "https://proxy.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_PROXY_TOKEN | default "" }
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

def base-url-completer [] { ["https://proxy.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def GeoMatchLevel-completer [] { ["area-code" "country" "overlay" "radius"] }
def NumberSelectionBehavior-completer [] { ["avoid-sticky" "prefer-sticky"] }
def Mode-completer [] { ["message-only" "voice-and-message" "voice-only"] }
def Status-completer [] { ["closed" "failed" "in-progress" "open" "unknown"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "services ListService" } } | get name | first)
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

# Retrieve a list of all Services for Twilio Proxy. A maximum of 100 records will be returned per page.
#
# GET /v1/Services
# operationId: ListService
export def "services ListService" [
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, callback_url: string, chat_instance_sid: string, date_created: string, date_updated: string, default_ttl: int, geo_match_level: string, intercept_callback_url: string, links: record, number_selection_behavior: string, out_of_session_callback_url: string, sid: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Service for Twilio Proxy
#
# POST /v1/Services
# operationId: CreateService
export def "services CreateService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CallbackUrl: string # The URL we should call when the interaction status changes. (format: uri)
  --ChatInstanceSid: string # The SID of the Chat Service Instance managed by Proxy Service. The Chat Service enables Proxy to forward SMS and channel messages to this chat instance. This is a one-to-one relationship.
  --DefaultTtl: int # The default `ttl` value to set for Sessions created in the Service. The TTL (time to live) is measured in seconds after the Session's last create or last Interaction. The default value of `0` indicates an unlimited Session length. You can override a Session's default TTL value by setting its `ttl` value.
  --GeoMatchLevel: string@GeoMatchLevel-completer
  --InterceptCallbackUrl: string # The URL we call on each interaction. If we receive a 403 status, we block the interaction; otherwise the interaction continues. (format: uri)
  --NumberSelectionBehavior: string@NumberSelectionBehavior-completer
  --OutOfSessionCallbackUrl: string # The URL we should call when an inbound call or SMS action occurs on a closed or non-existent Session. If your server (or a Twilio [function](https://www.twilio.com/functions)) responds with valid [TwiML](https://www.twilio.com/docs/voice/twiml), we will process it. This means it is possible, for example, to play a message for a call, send an automated text message response, or redirect a call to another Phone Number. See [Out-of-Session Callback Response Guide](https://www.twilio.com/docs/proxy/out-session-callback-response-guide) for more information. (format: uri)
  UniqueName: string # An application-defined string that uniquely identifies the resource. This value must be 191 characters or fewer in length and be unique. **This value should not have PII.**
]: any -> record<account_sid: string, callback_url: string, chat_instance_sid: string, date_created: string, date_updated: string, default_ttl: int, geo_match_level: string, intercept_callback_url: string, links: record, number_selection_behavior: string, out_of_session_callback_url: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base "/v1/Services")
  let body = {CallbackUrl: $CallbackUrl, ChatInstanceSid: $ChatInstanceSid, DefaultTtl: $DefaultTtl, GeoMatchLevel: $GeoMatchLevel, InterceptCallbackUrl: $InterceptCallbackUrl, NumberSelectionBehavior: $NumberSelectionBehavior, OutOfSessionCallbackUrl: $OutOfSessionCallbackUrl, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Phone Numbers in the Proxy Number Pool for a Service. A maximum of 100 records will be returned per page.
#
# GET /v1/Services/{ServiceSid}/PhoneNumbers
# operationId: ListPhoneNumber
export def "services-phone-numbers ListPhoneNumber" [
  ServiceSid: string
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, phone_numbers: table<account_sid: string, capabilities: record, date_created: string, date_updated: string, friendly_name: string, in_use: int, is_reserved: bool, iso_country: string, phone_number: string, service_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Phone Number to a Service's Proxy Number Pool.
#
# POST /v1/Services/{ServiceSid}/PhoneNumbers
# operationId: CreatePhoneNumber
export def "services-phone-numbers CreatePhoneNumber" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IsReserved: oneof<nothing, bool> # Whether the new phone number should be reserved and not be assigned to a participant using proxy pool logic. See [Reserved Phone Numbers](https://www.twilio.com/docs/proxy/reserved-phone-numbers) for more information.
  --PhoneNumber: string # The phone number in [E.164](https://www.twilio.com/docs/glossary/what-e164) format.  E.164 phone numbers consist of a + followed by the country code and subscriber number without punctuation characters. For example, +14155551234. (format: phone-number)
  --Sid: string # The SID of a Twilio [IncomingPhoneNumber](https://www.twilio.com/docs/phone-numbers/api/incomingphonenumber-resource) resource that represents the Twilio Number you would like to assign to your Proxy Service.
]: any -> record<account_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, friendly_name: string, in_use: int, is_reserved: bool, iso_country: string, phone_number: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers")
  let body = {IsReserved: $IsReserved, PhoneNumber: $PhoneNumber, Sid: $Sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Phone Number from a Service.
#
# DELETE /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
# operationId: DeletePhoneNumber
export def "services-phone-numbers DeletePhoneNumber" [
  ServiceSid: string
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
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Phone Number.
#
# GET /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
# operationId: FetchPhoneNumber
export def "services-phone-numbers FetchPhoneNumber" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, friendly_name: string, in_use: int, is_reserved: bool, iso_country: string, phone_number: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Proxy Number.
#
# POST /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
# operationId: UpdatePhoneNumber
export def "services-phone-numbers UpdatePhoneNumber" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IsReserved: oneof<nothing, bool> # Whether the phone number should be reserved and not be assigned to a participant using proxy pool logic. See [Reserved Phone Numbers](https://www.twilio.com/docs/proxy/reserved-phone-numbers) for more information.
]: any -> record<account_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, friendly_name: string, in_use: int, is_reserved: bool, iso_country: string, phone_number: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers/($Sid)")
  let body = {IsReserved: $IsReserved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Sessions for the Service. A maximum of 100 records will be returned per page.
#
# GET /v1/Services/{ServiceSid}/Sessions
# operationId: ListSession
export def "services-sessions ListSession" [
  ServiceSid: string
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, sessions: table<account_sid: string, closed_reason: string, date_created: string, date_ended: string, date_expiry: string, date_last_interaction: string, date_started: string, date_updated: string, links: record, mode: string, service_sid: string, sid: string, status: string, ttl: int, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Session
#
# POST /v1/Services/{ServiceSid}/Sessions
# operationId: CreateSession
export def "services-sessions CreateSession" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DateExpiry: string # The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date when the Session should expire. If this is value is present, it overrides the `ttl` value. (format: date-time)
  --Mode: string@Mode-completer
  --Participants: list # The Participant objects to include in the new session.
  --Status: string@Status-completer
  --Ttl: int # The time, in seconds, when the session will expire. The time is measured from the last Session create or the Session's last Interaction.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. This value must be 191 characters or fewer in length and be unique. **This value should not have PII.**
]: any -> record<account_sid: string, closed_reason: string, date_created: string, date_ended: string, date_expiry: string, date_last_interaction: string, date_started: string, date_updated: string, links: record, mode: string, service_sid: string, sid: string, status: string, ttl: int, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions")
  let body = {DateExpiry: $DateExpiry, Mode: $Mode, Participants: $Participants, Status: $Status, Ttl: $Ttl, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Interactions for a Session. A maximum of 100 records will be returned per page.
#
# GET /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Interactions
# operationId: ListInteraction
export def "services-sessions-interactions ListInteraction" [
  ServiceSid: string
  SessionSid: string
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
]: nothing -> record<interactions: table<account_sid: string, data: string, date_created: string, date_updated: string, inbound_participant_sid: string, inbound_resource_sid: string, inbound_resource_status: string, inbound_resource_type: string, inbound_resource_url: string, outbound_participant_sid: string, outbound_resource_sid: string, outbound_resource_status: string, outbound_resource_type: string, outbound_resource_url: string, service_sid: string, session_sid: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Interactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific Interaction.
#
# DELETE /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Interactions/{Sid}
# operationId: DeleteInteraction
export def "services-sessions-interactions DeleteInteraction" [
  ServiceSid: string
  SessionSid: string
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
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Interactions/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of Interactions for a given [Session](https://www.twilio.com/docs/proxy/api/session).
#
# GET /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Interactions/{Sid}
# operationId: FetchInteraction
export def "services-sessions-interactions FetchInteraction" [
  ServiceSid: string
  SessionSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, data: string, date_created: string, date_updated: string, inbound_participant_sid: string, inbound_resource_sid: string, inbound_resource_status: string, inbound_resource_type: string, inbound_resource_url: string, outbound_participant_sid: string, outbound_resource_sid: string, outbound_resource_status: string, outbound_resource_type: string, outbound_resource_url: string, service_sid: string, session_sid: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Interactions/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all Participants in a Session.
#
# GET /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Participants
# operationId: ListParticipant
export def "services-sessions-participants ListParticipant" [
  ServiceSid: string
  SessionSid: string
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, date_created: string, date_deleted: string, date_updated: string, friendly_name: string, identifier: string, links: record, proxy_identifier: string, proxy_identifier_sid: string, service_sid: string, session_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new Participant to the Session
#
# POST /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Participants
# operationId: CreateParticipant
export def "services-sessions-participants CreateParticipant" [
  ServiceSid: string
  SessionSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FriendlyName: string # The string that you assigned to describe the participant. This value must be 255 characters or fewer. **This value should not have PII.**
  Identifier: string # The phone number of the Participant.
  --ProxyIdentifier: string # The proxy phone number to use for the Participant. If not specified, Proxy will select a number from the pool.
  --ProxyIdentifierSid: string # The SID of the Proxy Identifier to assign to the Participant.
]: any -> record<account_sid: string, date_created: string, date_deleted: string, date_updated: string, friendly_name: string, identifier: string, links: record, proxy_identifier: string, proxy_identifier_sid: string, service_sid: string, session_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Participants")
  let body = {FriendlyName: $FriendlyName, Identifier: $Identifier, ProxyIdentifier: $ProxyIdentifier, ProxyIdentifierSid: $ProxyIdentifierSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Participants/{ParticipantSid}/MessageInteractions
#
# operationId: ListMessageInteraction
export def "services-sessions-participants-message-interactions ListMessageInteraction" [
  ServiceSid: string
  SessionSid: string
  ParticipantSid: string
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
]: nothing -> record<interactions: table<account_sid: string, data: string, date_created: string, date_updated: string, inbound_participant_sid: string, inbound_resource_sid: string, inbound_resource_status: string, inbound_resource_type: string, inbound_resource_url: string, outbound_participant_sid: string, outbound_resource_sid: string, outbound_resource_status: string, outbound_resource_type: string, outbound_resource_url: string, participant_sid: string, service_sid: string, session_sid: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Participants/($ParticipantSid)/MessageInteractions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new message Interaction to send directly from your system to one [Participant](https://www.twilio.com/docs/proxy/api/participant).  The `inbound` properties for the Interaction will always be empty.
#
# POST /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Participants/{ParticipantSid}/MessageInteractions
# operationId: CreateMessageInteraction
export def "services-sessions-participants-message-interactions CreateMessageInteraction" [
  ServiceSid: string
  SessionSid: string
  ParticipantSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Body: string # The message to send to the participant
  --MediaUrl: list # Reserved. Not currently supported.
]: any -> record<account_sid: string, data: string, date_created: string, date_updated: string, inbound_participant_sid: string, inbound_resource_sid: string, inbound_resource_status: string, inbound_resource_type: string, inbound_resource_url: string, outbound_participant_sid: string, outbound_resource_sid: string, outbound_resource_status: string, outbound_resource_type: string, outbound_resource_url: string, participant_sid: string, service_sid: string, session_sid: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Participants/($ParticipantSid)/MessageInteractions")
  let body = {Body: $Body, MediaUrl: $MediaUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Participants/{ParticipantSid}/MessageInteractions/{Sid}
#
# operationId: FetchMessageInteraction
export def "services-sessions-participants-message-interactions FetchMessageInteraction" [
  ServiceSid: string
  SessionSid: string
  ParticipantSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, data: string, date_created: string, date_updated: string, inbound_participant_sid: string, inbound_resource_sid: string, inbound_resource_status: string, inbound_resource_type: string, inbound_resource_url: string, outbound_participant_sid: string, outbound_resource_sid: string, outbound_resource_status: string, outbound_resource_type: string, outbound_resource_url: string, participant_sid: string, service_sid: string, session_sid: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Participants/($ParticipantSid)/MessageInteractions/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific Participant. This is a soft-delete. The participant remains associated with the session and cannot be re-added. Participants are only permanently deleted when the [Session](https://www.twilio.com/docs/proxy/api/session) is deleted.
#
# DELETE /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Participants/{Sid}
# operationId: DeleteParticipant
export def "services-sessions-participants DeleteParticipant" [
  ServiceSid: string
  SessionSid: string
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
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Participants/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Participant.
#
# GET /v1/Services/{ServiceSid}/Sessions/{SessionSid}/Participants/{Sid}
# operationId: FetchParticipant
export def "services-sessions-participants FetchParticipant" [
  ServiceSid: string
  SessionSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_deleted: string, date_updated: string, friendly_name: string, identifier: string, links: record, proxy_identifier: string, proxy_identifier_sid: string, service_sid: string, session_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($SessionSid)/Participants/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific Session.
#
# DELETE /v1/Services/{ServiceSid}/Sessions/{Sid}
# operationId: DeleteSession
export def "services-sessions DeleteSession" [
  ServiceSid: string
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
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Session.
#
# GET /v1/Services/{ServiceSid}/Sessions/{Sid}
# operationId: FetchSession
export def "services-sessions FetchSession" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, closed_reason: string, date_created: string, date_ended: string, date_expiry: string, date_last_interaction: string, date_started: string, date_updated: string, links: record, mode: string, service_sid: string, sid: string, status: string, ttl: int, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Session.
#
# POST /v1/Services/{ServiceSid}/Sessions/{Sid}
# operationId: UpdateSession
export def "services-sessions UpdateSession" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --DateExpiry: string # The [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date when the Session should expire. If this is value is present, it overrides the `ttl` value. (format: date-time)
  --Status: string@Status-completer
  --Ttl: int # The time, in seconds, when the session will expire. The time is measured from the last Session create or the Session's last Interaction.
]: any -> record<account_sid: string, closed_reason: string, date_created: string, date_ended: string, date_expiry: string, date_last_interaction: string, date_started: string, date_updated: string, links: record, mode: string, service_sid: string, sid: string, status: string, ttl: int, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/Sessions/($Sid)")
  let body = {DateExpiry: $DateExpiry, Status: $Status, Ttl: $Ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all Short Codes in the Proxy Number Pool for the Service. A maximum of 100 records will be returned per page.
#
# GET /v1/Services/{ServiceSid}/ShortCodes
# operationId: ListShortCode
export def "services-short-codes ListShortCode" [
  ServiceSid: string
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
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, short_codes: table<account_sid: string, capabilities: record, date_created: string, date_updated: string, is_reserved: bool, iso_country: string, service_sid: string, short_code: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a Short Code to the Proxy Number Pool for the Service.
#
# POST /v1/Services/{ServiceSid}/ShortCodes
# operationId: CreateShortCode
export def "services-short-codes CreateShortCode" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Sid: string # The SID of a Twilio [ShortCode](https://www.twilio.com/docs/sms/api/short-code) resource that represents the short code you would like to assign to your Proxy Service.
]: any -> record<account_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, is_reserved: bool, iso_country: string, service_sid: string, short_code: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes")
  let body = {Sid: $Sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Short Code from a Service.
#
# DELETE /v1/Services/{ServiceSid}/ShortCodes/{Sid}
# operationId: DeleteShortCode
export def "services-short-codes DeleteShortCode" [
  ServiceSid: string
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
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Short Code.
#
# GET /v1/Services/{ServiceSid}/ShortCodes/{Sid}
# operationId: FetchShortCode
export def "services-short-codes FetchShortCode" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, is_reserved: bool, iso_country: string, service_sid: string, short_code: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Short Code.
#
# POST /v1/Services/{ServiceSid}/ShortCodes/{Sid}
# operationId: UpdateShortCode
export def "services-short-codes UpdateShortCode" [
  ServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IsReserved: oneof<nothing, bool> # Whether the short code should be reserved and not be assigned to a participant using proxy pool logic. See [Reserved Phone Numbers](https://www.twilio.com/docs/proxy/reserved-phone-numbers) for more information.
]: any -> record<account_sid: string, capabilities: record<fax: bool, mms: bool, sms: bool, voice: bool>, date_created: string, date_updated: string, is_reserved: bool, iso_country: string, service_sid: string, short_code: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes/($Sid)")
  let body = {IsReserved: $IsReserved} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific Service.
#
# DELETE /v1/Services/{Sid}
# operationId: DeleteService
export def "services DeleteService" [
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
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Service.
#
# GET /v1/Services/{Sid}
# operationId: FetchService
export def "services FetchService" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, callback_url: string, chat_instance_sid: string, date_created: string, date_updated: string, default_ttl: int, geo_match_level: string, intercept_callback_url: string, links: record, number_selection_behavior: string, out_of_session_callback_url: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Service.
#
# POST /v1/Services/{Sid}
# operationId: UpdateService
export def "services UpdateService" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --CallbackUrl: string # The URL we should call when the interaction status changes. (format: uri)
  --ChatInstanceSid: string # The SID of the Chat Service Instance managed by Proxy Service. The Chat Service enables Proxy to forward SMS and channel messages to this chat instance. This is a one-to-one relationship.
  --DefaultTtl: int # The default `ttl` value to set for Sessions created in the Service. The TTL (time to live) is measured in seconds after the Session's last create or last Interaction. The default value of `0` indicates an unlimited Session length. You can override a Session's default TTL value by setting its `ttl` value.
  --GeoMatchLevel: string@GeoMatchLevel-completer
  --InterceptCallbackUrl: string # The URL we call on each interaction. If we receive a 403 status, we block the interaction; otherwise the interaction continues. (format: uri)
  --NumberSelectionBehavior: string@NumberSelectionBehavior-completer
  --OutOfSessionCallbackUrl: string # The URL we should call when an inbound call or SMS action occurs on a closed or non-existent Session. If your server (or a Twilio [function](https://www.twilio.com/functions)) responds with valid [TwiML](https://www.twilio.com/docs/voice/twiml), we will process it. This means it is possible, for example, to play a message for a call, send an automated text message response, or redirect a call to another Phone Number. See [Out-of-Session Callback Response Guide](https://www.twilio.com/docs/proxy/out-session-callback-response-guide) for more information. (format: uri)
  --UniqueName: string # An application-defined string that uniquely identifies the resource. This value must be 191 characters or fewer in length and be unique. **This value should not have PII.**
]: any -> record<account_sid: string, callback_url: string, chat_instance_sid: string, date_created: string, date_updated: string, default_ttl: int, geo_match_level: string, intercept_callback_url: string, links: record, number_selection_behavior: string, out_of_session_callback_url: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://proxy.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let body = {CallbackUrl: $CallbackUrl, ChatInstanceSid: $ChatInstanceSid, DefaultTtl: $DefaultTtl, GeoMatchLevel: $GeoMatchLevel, InterceptCallbackUrl: $InterceptCallbackUrl, NumberSelectionBehavior: $NumberSelectionBehavior, OutOfSessionCallbackUrl: $OutOfSessionCallbackUrl, UniqueName: $UniqueName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
