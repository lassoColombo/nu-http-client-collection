# Auto-generated client for Twilio - Voice v1.0.0
# Source: https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_voice_v1.json
# Auth: --token flag or $env.TWILIO_VOICE_TOKEN

const BASE_URL = "https://voice.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_VOICE_TOKEN | default "" }
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
def base-url-completer [] { ["https://voice.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def VoiceMethod-completer [] { ["GET" "POST"] }
def VoiceFallbackMethod-completer [] { ["GET" "POST"] }
def StatusCallbackMethod-completer [] { ["GET" "POST"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "archives-calls DeleteArchivedCall" } } | get name | first)
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

# Delete an archived call record from Bulk Export. Note: this does not also delete the record from the Voice API.
#
# DELETE /v1/Archives/{Date}/Calls/{Sid}
# operationId: DeleteArchivedCall
export def "archives-calls DeleteArchivedCall" [
  Date: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/Archives/($Date)/Calls/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/ByocTrunks
#
# operationId: CreateByocTrunk
export def "byoc-trunks CreateByocTrunk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --VoiceUrl: string # The URL we should call when the BYOC Trunk receives a call. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method we should use to call `voice_url`. Can be: `GET` or `POST`. (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs while retrieving or executing the TwiML from `voice_url`. (format: uri)
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --StatusCallbackUrl: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --CnamLookupEnabled: string@bool-completer # Whether Caller ID Name (CNAM) lookup is enabled for the trunk. If enabled, all inbound calls to the BYOC Trunk from the United States and Canada automatically perform a CNAM Lookup and display Caller ID data on your phone. See [CNAM Lookups](https://www.twilio.com/docs/sip-trunking#CNAM) for more information.
  --ConnectionPolicySid: string # The SID of the Connection Policy that Twilio will use when routing traffic to your communications infrastructure.
  --FromDomainSid: string # The SID of the SIP Domain that should be used in the `From` header of originating calls sent to your SIP infrastructure. If your SIP infrastructure allows users to "call back" an incoming call, configure this with a [SIP Domain](https://www.twilio.com/docs/voice/api/sending-sip) to ensure proper routing. If not configured, the from domain will default to "sip.twilio.com".
]: any -> record<account_sid: string, sid: string, friendly_name: string, voice_url: string, voice_method: string, voice_fallback_url: string, voice_fallback_method: string, status_callback_url: string, status_callback_method: string, cnam_lookup_enabled: bool, connection_policy_sid: string, from_domain_sid: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base "/v1/ByocTrunks")
  let body = {FriendlyName: $FriendlyName, VoiceUrl: $VoiceUrl, VoiceMethod: $VoiceMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceFallbackMethod: $VoiceFallbackMethod, StatusCallbackUrl: $StatusCallbackUrl, StatusCallbackMethod: $StatusCallbackMethod, CnamLookupEnabled: $CnamLookupEnabled, ConnectionPolicySid: $ConnectionPolicySid, FromDomainSid: $FromDomainSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/ByocTrunks
#
# operationId: ListByocTrunk
export def "byoc-trunks ListByocTrunk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<byoc_trunks: table<account_sid: string, sid: string, friendly_name: string, voice_url: string, voice_method: string, voice_fallback_url: string, voice_fallback_method: string, status_callback_url: string, status_callback_method: string, cnam_lookup_enabled: bool, connection_policy_sid: string, from_domain_sid: string, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ByocTrunks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/ByocTrunks/{Sid}
#
# operationId: FetchByocTrunk
export def "byoc-trunks FetchByocTrunk" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, sid: string, friendly_name: string, voice_url: string, voice_method: string, voice_fallback_url: string, voice_fallback_method: string, status_callback_url: string, status_callback_method: string, cnam_lookup_enabled: bool, connection_policy_sid: string, from_domain_sid: string, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ByocTrunks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/ByocTrunks/{Sid}
#
# operationId: UpdateByocTrunk
export def "byoc-trunks UpdateByocTrunk" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --VoiceUrl: string # The URL we should call when the BYOC Trunk receives a call. (format: uri)
  --VoiceMethod: string@VoiceMethod-completer # The HTTP method we should use to call `voice_url` (format: http-method)
  --VoiceFallbackUrl: string # The URL that we should call when an error occurs while retrieving or executing the TwiML requested by `voice_url`. (format: uri)
  --VoiceFallbackMethod: string@VoiceFallbackMethod-completer # The HTTP method we should use to call `voice_fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --StatusCallbackUrl: string # The URL that we should call to pass status parameters (such as call ended) to your application. (format: uri)
  --StatusCallbackMethod: string@StatusCallbackMethod-completer # The HTTP method we should use to call `status_callback_url`. Can be: `GET` or `POST`. (format: http-method)
  --CnamLookupEnabled: string@bool-completer # Whether Caller ID Name (CNAM) lookup is enabled for the trunk. If enabled, all inbound calls to the BYOC Trunk from the United States and Canada automatically perform a CNAM Lookup and display Caller ID data on your phone. See [CNAM Lookups](https://www.twilio.com/docs/sip-trunking#CNAM) for more information.
  --ConnectionPolicySid: string # The SID of the Connection Policy that Twilio will use when routing traffic to your communications infrastructure.
  --FromDomainSid: string # The SID of the SIP Domain that should be used in the `From` header of originating calls sent to your SIP infrastructure. If your SIP infrastructure allows users to "call back" an incoming call, configure this with a [SIP Domain](https://www.twilio.com/docs/voice/api/sending-sip) to ensure proper routing. If not configured, the from domain will default to "sip.twilio.com".
]: any -> record<account_sid: string, sid: string, friendly_name: string, voice_url: string, voice_method: string, voice_fallback_url: string, voice_fallback_method: string, status_callback_url: string, status_callback_method: string, cnam_lookup_enabled: bool, connection_policy_sid: string, from_domain_sid: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ByocTrunks/($Sid)")
  let body = {FriendlyName: $FriendlyName, VoiceUrl: $VoiceUrl, VoiceMethod: $VoiceMethod, VoiceFallbackUrl: $VoiceFallbackUrl, VoiceFallbackMethod: $VoiceFallbackMethod, StatusCallbackUrl: $StatusCallbackUrl, StatusCallbackMethod: $StatusCallbackMethod, CnamLookupEnabled: $CnamLookupEnabled, ConnectionPolicySid: $ConnectionPolicySid, FromDomainSid: $FromDomainSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/ByocTrunks/{Sid}
#
# operationId: DeleteByocTrunk
export def "byoc-trunks DeleteByocTrunk" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ByocTrunks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/ConnectionPolicies
#
# operationId: CreateConnectionPolicy
export def "connection-policies CreateConnectionPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
]: any -> record<account_sid: string, sid: string, friendly_name: string, date_created: string, date_updated: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base "/v1/ConnectionPolicies")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/ConnectionPolicies
#
# operationId: ListConnectionPolicy
export def "connection-policies ListConnectionPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<connection_policies: table<account_sid: string, sid: string, friendly_name: string, date_created: string, date_updated: string, url: string, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ConnectionPolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/ConnectionPolicies/{Sid}
#
# operationId: FetchConnectionPolicy
export def "connection-policies FetchConnectionPolicy" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, sid: string, friendly_name: string, date_created: string, date_updated: string, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ConnectionPolicies/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/ConnectionPolicies/{Sid}
#
# operationId: UpdateConnectionPolicy
export def "connection-policies UpdateConnectionPolicy" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
]: any -> record<account_sid: string, sid: string, friendly_name: string, date_created: string, date_updated: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ConnectionPolicies/($Sid)")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/ConnectionPolicies/{Sid}
#
# operationId: DeleteConnectionPolicy
export def "connection-policies DeleteConnectionPolicy" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ConnectionPolicies/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets
#
# operationId: CreateConnectionPolicyTarget
export def "connection-policies-targets CreateConnectionPolicyTarget" [
  ConnectionPolicySid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Target: string # The SIP address you want Twilio to route your calls to. This must be a `sip:` schema. `sips` is NOT supported. (format: uri)
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --Priority: int # The relative importance of the target. Can be an integer from 0 to 65535, inclusive, and the default is 10. The lowest number represents the most important target.
  --Weight: int # The value that determines the relative share of the load the Target should receive compared to other Targets with the same priority. Can be an integer from 1 to 65535, inclusive, and the default is 10. Targets with higher values receive more load than those with lower ones with the same priority.
  --Enabled: string@bool-completer # Whether the Target is enabled. The default is `true`.
]: any -> record<account_sid: string, connection_policy_sid: string, sid: string, friendly_name: string, target: string, priority: int, weight: int, enabled: bool, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ConnectionPolicies/($ConnectionPolicySid)/Targets")
  let body = {Target: $Target, FriendlyName: $FriendlyName, Priority: $Priority, Weight: $Weight, Enabled: $Enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets
#
# operationId: ListConnectionPolicyTarget
export def "connection-policies-targets ListConnectionPolicyTarget" [
  ConnectionPolicySid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<targets: table<account_sid: string, connection_policy_sid: string, sid: string, friendly_name: string, target: string, priority: int, weight: int, enabled: bool, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/ConnectionPolicies/($ConnectionPolicySid)/Targets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}
#
# operationId: FetchConnectionPolicyTarget
export def "connection-policies-targets FetchConnectionPolicyTarget" [
  ConnectionPolicySid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, connection_policy_sid: string, sid: string, friendly_name: string, target: string, priority: int, weight: int, enabled: bool, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ConnectionPolicies/($ConnectionPolicySid)/Targets/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}
#
# operationId: UpdateConnectionPolicyTarget
export def "connection-policies-targets UpdateConnectionPolicyTarget" [
  ConnectionPolicySid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --Target: string # The SIP address you want Twilio to route your calls to. This must be a `sip:` schema. `sips` is NOT supported. (format: uri)
  --Priority: int # The relative importance of the target. Can be an integer from 0 to 65535, inclusive. The lowest number represents the most important target.
  --Weight: int # The value that determines the relative share of the load the Target should receive compared to other Targets with the same priority. Can be an integer from 1 to 65535, inclusive. Targets with higher values receive more load than those with lower ones with the same priority.
  --Enabled: string@bool-completer # Whether the Target is enabled.
]: any -> record<account_sid: string, connection_policy_sid: string, sid: string, friendly_name: string, target: string, priority: int, weight: int, enabled: bool, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ConnectionPolicies/($ConnectionPolicySid)/Targets/($Sid)")
  let body = {FriendlyName: $FriendlyName, Target: $Target, Priority: $Priority, Weight: $Weight, Enabled: $Enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/ConnectionPolicies/{ConnectionPolicySid}/Targets/{Sid}
#
# operationId: DeleteConnectionPolicyTarget
export def "connection-policies-targets DeleteConnectionPolicyTarget" [
  ConnectionPolicySid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/ConnectionPolicies/($ConnectionPolicySid)/Targets/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve voice dialing country permissions identified by the given ISO country code
#
# GET /v1/DialingPermissions/Countries/{IsoCode}
# operationId: FetchDialingPermissionsCountry
export def "dialing-permissions-countries FetchDialingPermissionsCountry" [
  IsoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<iso_code: string, name: string, continent: string, country_codes: list<string>, low_risk_numbers_enabled: bool, high_risk_special_numbers_enabled: bool, high_risk_tollfraud_numbers_enabled: bool, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/DialingPermissions/Countries/($IsoCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all voice dialing country permissions for this account
#
# GET /v1/DialingPermissions/Countries
# operationId: ListDialingPermissionsCountry
export def "dialing-permissions-countries ListDialingPermissionsCountry" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --IsoCode: string # Filter to retrieve the country permissions by specifying the [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) (format: iso-country-code)
  --Continent: string # Filter to retrieve the country permissions by specifying the continent
  --CountryCode: string # Filter the results by specified [country codes](https://www.itu.int/itudoc/itu-t/ob-lists/icc/e164_763.html)
  --LowRiskNumbersEnabled: string@bool-completer # Filter to retrieve the country permissions with dialing to low-risk numbers enabled. Can be: `true` or `false`.
  --HighRiskSpecialNumbersEnabled: string@bool-completer # Filter to retrieve the country permissions with dialing to high-risk special service numbers enabled. Can be: `true` or `false`
  --HighRiskTollfraudNumbersEnabled: string@bool-completer # Filter to retrieve the country permissions with dialing to high-risk [toll fraud](https://www.twilio.com/blog/how-to-protect-your-account-from-toll-fraud-with-voice-dialing-geo-permissions-html) numbers enabled. Can be: `true` or `false`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<content: table<iso_code: string, name: string, continent: string, country_codes: list, low_risk_numbers_enabled: bool, high_risk_special_numbers_enabled: bool, high_risk_tollfraud_numbers_enabled: bool, url: string, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let qp = [(serialize-qp "IsoCode" $IsoCode "scalar") (serialize-qp "Continent" $Continent "scalar") (serialize-qp "CountryCode" $CountryCode "scalar") (serialize-qp "LowRiskNumbersEnabled" $LowRiskNumbersEnabled "scalar") (serialize-qp "HighRiskSpecialNumbersEnabled" $HighRiskSpecialNumbersEnabled "scalar") (serialize-qp "HighRiskTollfraudNumbersEnabled" $HighRiskTollfraudNumbersEnabled "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/DialingPermissions/Countries" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a bulk update request to change voice dialing country permissions of one or more countries identified by the corresponding [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)
#
# POST /v1/DialingPermissions/BulkCountryUpdates
# operationId: CreateDialingPermissionsCountryBulkUpdate
export def "dialing-permissions-bulk-country-updates CreateDialingPermissionsCountryBulkUpdate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  UpdateRequest: string # URL encoded JSON array of update objects. example : `[ { "iso_code": "GB", "low_risk_numbers_enabled": "true", "high_risk_special_numbers_enabled":"true", "high_risk_tollfraud_numbers_enabled": "false" } ]`
]: any -> record<update_count: int, update_request: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base "/v1/DialingPermissions/BulkCountryUpdates")
  let body = {UpdateRequest: $UpdateRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch the high-risk special services prefixes from the country resource corresponding to the [ISO country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)
#
# GET /v1/DialingPermissions/Countries/{IsoCode}/HighRiskSpecialPrefixes
# operationId: ListDialingPermissionsHrsPrefixes
export def "dialing-permissions-countries-high-risk-special-prefixes ListDialingPermissionsHrsPrefixes" [
  IsoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<content: table<prefix: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/DialingPermissions/Countries/($IsoCode)/HighRiskSpecialPrefixes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve voice dialing permissions inheritance for the sub-account
#
# GET /v1/Settings
# operationId: FetchDialingPermissionsSettings
export def "settings FetchDialingPermissionsSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dialing_permissions_inheritance: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base "/v1/Settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update voice dialing permissions inheritance for the sub-account
#
# POST /v1/Settings
# operationId: UpdateDialingPermissionsSettings
export def "settings UpdateDialingPermissionsSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --DialingPermissionsInheritance: string@bool-completer # `true` for the sub-account to inherit voice dialing permissions from the Master Project; otherwise `false`.
]: any -> record<dialing_permissions_inheritance: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base "/v1/Settings")
  let body = {DialingPermissionsInheritance: $DialingPermissionsInheritance} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/IpRecords
#
# operationId: CreateIpRecord
export def "ip-records CreateIpRecord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  IpAddress: string # An IP address in dotted decimal notation, IPv4 only.
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
  --CidrPrefixLength: int # An integer representing the length of the [CIDR](https://tools.ietf.org/html/rfc4632) prefix to use with this IP address. By default the entire IP address is used, which for IPv4 is value 32.
]: any -> record<account_sid: string, sid: string, friendly_name: string, ip_address: string, cidr_prefix_length: int, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base "/v1/IpRecords")
  let body = {IpAddress: $IpAddress, FriendlyName: $FriendlyName, CidrPrefixLength: $CidrPrefixLength} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/IpRecords
#
# operationId: ListIpRecord
export def "ip-records ListIpRecord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<ip_records: table<account_sid: string, sid: string, friendly_name: string, ip_address: string, cidr_prefix_length: int, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/IpRecords" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/IpRecords/{Sid}
#
# operationId: FetchIpRecord
export def "ip-records FetchIpRecord" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, sid: string, friendly_name: string, ip_address: string, cidr_prefix_length: int, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/IpRecords/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/IpRecords/{Sid}
#
# operationId: UpdateIpRecord
export def "ip-records UpdateIpRecord" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # A descriptive string that you create to describe the resource. It is not unique and can be up to 255 characters long.
]: any -> record<account_sid: string, sid: string, friendly_name: string, ip_address: string, cidr_prefix_length: int, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/IpRecords/($Sid)")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/IpRecords/{Sid}
#
# operationId: DeleteIpRecord
export def "ip-records DeleteIpRecord" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/IpRecords/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/SourceIpMappings
#
# operationId: CreateSourceIpMapping
export def "source-ip-mappings CreateSourceIpMapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  IpRecordSid: string # The Twilio-provided string that uniquely identifies the IP Record resource to map from.
  SipDomainSid: string # The SID of the SIP Domain that the IP Record should be mapped to.
]: any -> record<sid: string, ip_record_sid: string, sip_domain_sid: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base "/v1/SourceIpMappings")
  let body = {IpRecordSid: $IpRecordSid, SipDomainSid: $SipDomainSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/SourceIpMappings
#
# operationId: ListSourceIpMapping
export def "source-ip-mappings ListSourceIpMapping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<source_ip_mappings: table<sid: string, ip_record_sid: string, sip_domain_sid: string, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/SourceIpMappings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/SourceIpMappings/{Sid}
#
# operationId: FetchSourceIpMapping
export def "source-ip-mappings FetchSourceIpMapping" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, ip_record_sid: string, sip_domain_sid: string, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/SourceIpMappings/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/SourceIpMappings/{Sid}
#
# operationId: UpdateSourceIpMapping
export def "source-ip-mappings UpdateSourceIpMapping" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  SipDomainSid: string # The SID of the SIP Domain that the IP Record should be mapped to.
]: any -> record<sid: string, ip_record_sid: string, sip_domain_sid: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/SourceIpMappings/($Sid)")
  let body = {SipDomainSid: $SipDomainSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# DELETE /v1/SourceIpMappings/{Sid}
#
# operationId: DeleteSourceIpMapping
export def "source-ip-mappings DeleteSourceIpMapping" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://voice.twilio.com")
  let full_url = (build-url $base $"/v1/SourceIpMappings/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
