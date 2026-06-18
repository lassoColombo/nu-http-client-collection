# Auto-generated client for Twilio - Verify v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_verify_v2/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_VERIFY_TOKEN

const BASE_URL = "https://verify.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_VERIFY_TOKEN | default "" }
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

def base-url-completer [] { ["https://verify.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def channel-completer [] { ["call" "email" "sms" "whatsapp"] }
def status-completer [] { ["converted" "unconverted"] }
def factor-type-completer [] { ["push"] }
def status-completer-1 [] { ["approved" "denied" "expired" "pending"] }
def order-completer [] { ["asc" "desc"] }
def config-alg-completer [] { ["sha1" "sha256" "sha512"] }
def config-notification-platform-completer [] { ["apn" "fcm" "none"] }
def factor-type-completer-1 [] { ["push" "totp"] }
def status-completer-2 [] { ["approved" "canceled"] }
def status-completer-3 [] { ["disabled" "enabled"] }
def version-completer [] { ["v1" "v2"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "attempts list-verification" } } | get name | first)
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

# List all the verification attempts for a given Account.
#
# GET /v2/Attempts
# operationId: ListVerificationAttempt
export def "attempts list-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-created-after: string # Datetime filter used to query Verification Attempts created after this datetime. Given as GMT in RFC 2822 format. (format: date-time)
  --date-created-before: string # Datetime filter used to query Verification Attempts created before this datetime. Given as GMT in RFC 2822 format. (format: date-time)
  --channel-data-to: string # Destination of a verification. It is phone number in E.164 format.
  --country: string # Filter used to query Verification Attempts sent to the specified destination country. (format: iso-country-code)
  --channel: string@channel-completer # Filter used to query Verification Attempts by communication channel. Valid values are `SMS` and `CALL`
  --verify-service-sid: string # Filter used to query Verification Attempts by verify service. Only attempts of the provided SID will be returned.
  --verification-sid: string # Filter used to return all the Verification Attempts of a single verification. Only attempts of the provided verification SID will be returned.
  --status: string@status-completer # Filter used to query Verification Attempts by conversion status. Valid values are `UNCONVERTED`, for attempts that were not converted, and `CONVERTED`, for attempts that were confirmed.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<attempts: table<account_sid: string, channel: string, channel_data: any, conversion_status: string, date_created: string, date_updated: string, price: any, service_sid: string, sid: string, url: string, verification_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "DateCreatedAfter" $date_created_after "scalar") (serialize-qp "DateCreatedBefore" $date_created_before "scalar") (serialize-qp "ChannelData.To" $channel_data_to "scalar") (serialize-qp "Country" $country "scalar") (serialize-qp "Channel" $channel "scalar") (serialize-qp "VerifyServiceSid" $verify_service_sid "scalar") (serialize-qp "VerificationSid" $verification_sid "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Attempts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a summary of how many attempts were made and how many were converted.
#
# GET /v2/Attempts/Summary
# operationId: FetchVerificationAttemptsSummary
export def "attempts-summary get-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --verify-service-sid: string # Filter used to consider only Verification Attempts of the given verify service on the summary aggregation.
  --date-created-after: string # Datetime filter used to consider only Verification Attempts created after this datetime on the summary aggregation. Given as GMT in RFC 2822 format. (format: date-time)
  --date-created-before: string # Datetime filter used to consider only Verification Attempts created before this datetime on the summary aggregation. Given as GMT in RFC 2822 format. (format: date-time)
  --country: string # Filter used to consider only Verification Attempts sent to the specified destination country on the summary aggregation. (format: iso-country-code)
  --channel: string@channel-completer # Filter Verification Attempts considered on the summary aggregation by communication channel. Valid values are `SMS` and `CALL`
  --destination-prefix: string # Filter the Verification Attempts considered on the summary aggregation by Destination prefix. It is the prefix of a phone number in E.164 format.
]: nothing -> record<conversion_rate_percentage: float, total_attempts: int, total_converted: int, total_unconverted: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "VerifyServiceSid" $verify_service_sid "scalar") (serialize-qp "DateCreatedAfter" $date_created_after "scalar") (serialize-qp "DateCreatedBefore" $date_created_before "scalar") (serialize-qp "Country" $country "scalar") (serialize-qp "Channel" $channel "scalar") (serialize-qp "DestinationPrefix" $destination_prefix "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Attempts/Summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific verification attempt.
#
# GET /v2/Attempts/{Sid}
# operationId: FetchVerificationAttempt
export def "attempts get-verification" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel: string, channel_data: any, conversion_status: string, date_created: string, date_updated: string, price: any, service_sid: string, sid: string, url: string, verification_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Attempts/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the forms for a specific Form Type.
#
# GET /v2/Forms/{FormType}
# operationId: FetchForm
export def "forms get" [
  form_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<form_meta: any, form_type: string, forms: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({form_type: (encode-path-segment $form_type)} | format pattern "/v2/Forms/{form_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new phone number to SafeList.
#
# POST /v2/SafeList/Numbers
# operationId: CreateSafelist
export def "safe-list-numbers create-safelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  phone_number: string # The phone number to be added in SafeList. Phone numbers must be in [E.164 format](https://www.twilio.com/docs/glossary/what-e164).
]: any -> record<phone_number: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base "/v2/SafeList/Numbers")
  let req_body = {"PhoneNumber": $phone_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a phone number from SafeList.
#
# DELETE /v2/SafeList/Numbers/{PhoneNumber}
# operationId: DeleteSafelist
export def "safe-list-numbers delete-safelist" [
  phone_number: string
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
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number)} | format pattern "/v2/SafeList/Numbers/{phone_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if a phone number exists in SafeList.
#
# GET /v2/SafeList/Numbers/{PhoneNumber}
# operationId: FetchSafelist
export def "safe-list-numbers get-safelist" [
  phone_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<phone_number: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({phone_number: (encode-path-segment $phone_number)} | format pattern "/v2/SafeList/Numbers/{phone_number}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all Verification Services for an account.
#
# GET /v2/Services
# operationId: ListService
export def "services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Verification Service.
#
# POST /v2/Services
# operationId: CreateService
export def "services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code-length: int # The length of the verification code to generate. Must be an integer value between 4 and 10, inclusive.
  --custom-code-enabled: oneof<nothing, bool> # Whether to allow sending verifications with a custom code instead of a randomly generated one. Not available for all customers.
  --default-template-sid: string # The default message [template](https://www.twilio.com/docs/verify/api/templates). Will be used for all SMS verifications unless explicitly overriden. SMS channel only.
  --do-not-share-warning-enabled: oneof<nothing, bool> # Whether to add a security warning at the end of an SMS verification body. Disabled by default and applies only to SMS. Example SMS body: `Your AppName verification code is: 1234. Don’t share this code with anyone; our employees will never ask for the code`
  --dtmf-input-required: oneof<nothing, bool> # Whether to ask the user to press a number before delivering the verify code in a phone call.
  friendly_name: string # A descriptive string that you create to describe the verification service. It can be up to 32 characters long. **This value should not contain PII.**
  --lookup-enabled: oneof<nothing, bool> # Whether to perform a lookup with each verification started and return info about the phone number.
  --psd2-enabled: oneof<nothing, bool> # Whether to pass PSD2 transaction parameters when starting a verification.
  --push-apn-credential-sid: string # Optional configuration for the Push factors. Set the APN Credential for this service. This will allow to send push notifications to iOS devices. See [Credential Resource](https://www.twilio.com/docs/notify/api/credential-resource)
  --push-fcm-credential-sid: string # Optional configuration for the Push factors. Set the FCM Credential for this service. This will allow to send push notifications to Android devices. See [Credential Resource](https://www.twilio.com/docs/notify/api/credential-resource)
  --push-include-date: oneof<nothing, bool> # Optional configuration for the Push factors. If true, include the date in the Challenge's response. Otherwise, the date is omitted from the response. See [Challenge](https://www.twilio.com/docs/verify/api/challenge) resource’s details parameter for more info. Default: false. **Deprecated** do not use this parameter. This timestamp value is the same one as the one found in `date_created`, please use that one instead.
  --skip-sms-to-landlines: oneof<nothing, bool> # Whether to skip sending SMS verifications to landlines. Requires `lookup_enabled`.
  --totp-code-length: int # Optional configuration for the TOTP factors. Number of digits for generated TOTP codes. Must be between 3 and 8, inclusive. Defaults to 6
  --totp-issuer: string # Optional configuration for the TOTP factors. Set TOTP Issuer for this service. This will allow to configure the issuer of the TOTP URI. Defaults to the service friendly name if not provided.
  --totp-skew: int # Optional configuration for the TOTP factors. The number of time-steps, past and future, that are valid for validation of TOTP codes. Must be between 0 and 2, inclusive. Defaults to 1
  --totp-time-step: int # Optional configuration for the TOTP factors. Defines how often, in seconds, are TOTP codes generated. i.e, a new TOTP code is generated every time_step seconds. Must be between 20 and 60 seconds, inclusive. Defaults to 30 seconds
  --tts-name: string # The name of an alternative text-to-speech service to use in phone calls. Applies only to TTS languages.
]: any -> record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base "/v2/Services")
  let req_body = {"CodeLength": $code_length, "CustomCodeEnabled": $custom_code_enabled, "DefaultTemplateSid": $default_template_sid, "DoNotShareWarningEnabled": $do_not_share_warning_enabled, "DtmfInputRequired": $dtmf_input_required, "FriendlyName": $friendly_name, "LookupEnabled": $lookup_enabled, "Psd2Enabled": $psd2_enabled, "Push.ApnCredentialSid": $push_apn_credential_sid, "Push.FcmCredentialSid": $push_fcm_credential_sid, "Push.IncludeDate": $push_include_date, "SkipSmsToLandlines": $skip_sms_to_landlines, "Totp.CodeLength": $totp_code_length, "Totp.Issuer": $totp_issuer, "Totp.Skew": $totp_skew, "Totp.TimeStep": $totp_time_step, "TtsName": $tts_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Create a new enrollment Access Token for the Entity
#
# POST /v2/Services/{ServiceSid}/AccessTokens
# operationId: CreateAccessToken
export def "services-access-tokens create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --factor-friendly-name: string # The friendly name of the factor that is going to be created with this access token
  factor_type: string@factor-type-completer
  identity: string # The unique external identifier for the Entity of the Service. This identifier should be immutable, not PII, and generated by your external system, such as your user's UUID, GUID, or SID.
  --ttl: int # How long, in seconds, the access token is valid. Can be an integer between 60 and 300. Default is 60.
]: any -> record<account_sid: string, date_created: string, entity_identity: string, factor_friendly_name: string, factor_type: string, service_sid: string, sid: string, token: string, ttl: int, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/AccessTokens"))
  let req_body = {"FactorFriendlyName": $factor_friendly_name, "FactorType": $factor_type, "Identity": $identity, "Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Fetch an Access Token for the Entity
#
# GET /v2/Services/{ServiceSid}/AccessTokens/{Sid}
# operationId: FetchAccessToken
export def "services-access-tokens get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, entity_identity: string, factor_friendly_name: string, factor_type: string, service_sid: string, sid: string, token: string, ttl: int, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/AccessTokens/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all Entities for a Service.
#
# GET /v2/Services/{ServiceSid}/Entities
# operationId: ListEntity
export def "services-entities list-entity" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<entities: table<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Entities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Entity for the Service
#
# POST /v2/Services/{ServiceSid}/Entities
# operationId: CreateEntity
export def "services-entities create-entity" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  identity: string # The unique external identifier for the Entity of the Service. This identifier should be immutable, not PII, length between 8 and 64 characters, and generated by your external system, such as your user's UUID, GUID, or SID. It can only contain dash (-) separated alphanumeric characters.
]: any -> record<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Entities"))
  let req_body = {"Identity": $identity} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Delete a specific Entity.
#
# DELETE /v2/Services/{ServiceSid}/Entities/{Identity}
# operationId: DeleteEntity
export def "services-entities delete-entity" [
  service_sid: string
  identity: string
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
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Entity.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}
# operationId: FetchEntity
export def "services-entities get-entity" [
  service_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, identity: string, links: record, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all Challenges for a Factor.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges
# operationId: ListChallenge
export def "services-entities-challenges list" [
  service_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --factor-sid: string # The unique SID identifier of the Factor.
  --status: string@status-completer-1 # The Status of the Challenges to fetch. One of `pending`, `expired`, `approved` or `denied`.
  --order: string@order-completer # The desired sort order of the Challenges list. One of `asc` or `desc` for ascending and descending respectively. Defaults to `asc`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<challenges: table<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "FactorSid" $factor_sid "scalar") (serialize-qp "Status" $status "scalar") (serialize-qp "Order" $order "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Challenges") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Challenge for the Factor
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges
# operationId: CreateChallenge
export def "services-entities-challenges create" [
  service_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-payload: string # Optional payload used to verify the Challenge upon creation. Only used with a Factor of type `totp` to carry the TOTP code that needs to be verified. For `TOTP` this value must be between 3 and 8 characters long.
  --details-fields: list # A list of objects that describe the Fields included in the Challenge. Each object contains the label and value of the field, the label can be up to 36 characters in length and the value can be up to 128 characters in length. Used when `factor_type` is `push`. There can be up to 20 details fields.
  --details-message: string # Shown to the user when the push notification arrives. Required when `factor_type` is `push`. Can be up to 256 characters in length
  --expiration-date: string # The date-time when this Challenge expires, given in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) format. The default value is five (5) minutes after Challenge creation. The max value is sixty (60) minutes after creation. (format: date-time)
  factor_sid: string # The unique SID identifier of the Factor.
  --hidden-details: any # Details provided to give context about the Challenge. Not shown to the end user. It must be a stringified JSON with only strings values eg. `{"ip": "172.168.1.234"}`. Can be up to 1024 characters in length
]: any -> record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Challenges"))
  let req_body = {"AuthPayload": $auth_payload, "Details.Fields": $details_fields, "Details.Message": $details_message, "ExpirationDate": $expiration_date, "FactorSid": $factor_sid, "HiddenDetails": $hidden_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Create a new Notification for the corresponding Challenge
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{ChallengeSid}/Notifications
# operationId: CreateNotification
export def "services-entities-challenges-notifications create" [
  service_sid: string
  identity: string
  challenge_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # How long, in seconds, the notification is valid. Can be an integer between 0 and 300. Default is 300. Delivery is attempted until the TTL elapses, even if the device is offline. 0 means that the notification delivery is attempted immediately, only once, and is not stored for future delivery.
]: any -> record<account_sid: string, challenge_sid: string, date_created: string, entity_sid: string, identity: string, priority: string, service_sid: string, sid: string, ttl: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity), challenge_sid: (encode-path-segment $challenge_sid)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Challenges/{challenge_sid}/Notifications"))
  let req_body = {"Ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Fetch a specific Challenge.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{Sid}
# operationId: FetchChallenge
export def "services-entities-challenges get" [
  service_sid: string
  identity: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Challenges/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Verify a specific Challenge.
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Challenges/{Sid}
# operationId: UpdateChallenge
export def "services-entities-challenges update" [
  service_sid: string
  identity: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-payload: string # The optional payload needed to verify the Challenge. E.g., a TOTP would use the numeric code. For `TOTP` this value must be between 3 and 8 characters long. For `Push` this value can be up to 5456 characters in length
  --metadata: any # Custom metadata associated with the challenge. This is added by the Device/SDK directly to allow for the inclusion of device information. It must be a stringified JSON with only strings values eg. `{"os": "Android"}`. Can be up to 1024 characters in length.
]: any -> record<account_sid: string, date_created: string, date_responded: string, date_updated: string, details: any, entity_sid: string, expiration_date: string, factor_sid: string, factor_type: string, hidden_details: any, identity: string, links: record, metadata: any, responded_reason: string, service_sid: string, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Challenges/{sid}"))
  let req_body = {"AuthPayload": $auth_payload, "Metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all Factors for an Entity.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}/Factors
# operationId: ListFactor
export def "services-entities-factors list" [
  service_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<factors: table<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Factors") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Factor for the Entity
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Factors
# operationId: CreateNewFactor
export def "services-entities-factors create-new" [
  service_sid: string
  identity: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --binding-alg: string # The algorithm used when `factor_type` is `push`. Algorithm supported: `ES256`
  --binding-public-key: string # The Ecdsa public key in PKIX, ASN.1 DER format encoded in Base64. Required when `factor_type` is `push`
  --binding-secret: string # The shared secret for TOTP factors encoded in Base32. This can be provided when creating the Factor, otherwise it will be generated. Used when `factor_type` is `totp`
  --config-alg: string@config-alg-completer
  --config-app-id: string # The ID that uniquely identifies your app in the Google or Apple store, such as `com.example.myapp`. It can be up to 100 characters long. Required when `factor_type` is `push`.
  --config-code-length: int # Number of digits for generated TOTP codes. Must be between 3 and 8, inclusive. The default value is defined at the service level in the property `totp.code_length`. If not configured defaults to 6. Used when `factor_type` is `totp`
  --config-notification-platform: string@config-notification-platform-completer
  --config-notification-token: string # For APN, the device token. For FCM, the registration token. It is used to send the push notifications. Must be between 32 and 255 characters long. Required when `factor_type` is `push`.
  --config-sdk-version: string # The Verify Push SDK version used to configure the factor Required when `factor_type` is `push`
  --config-skew: int # The number of time-steps, past and future, that are valid for validation of TOTP codes. Must be between 0 and 2, inclusive. The default value is defined at the service level in the property `totp.skew`. If not configured defaults to 1. Used when `factor_type` is `totp`
  --config-time-step: int # Defines how often, in seconds, are TOTP codes generated. i.e, a new TOTP code is generated every time_step seconds. Must be between 20 and 60 seconds, inclusive. The default value is defined at the service level in the property `totp.time_step`. Defaults to 30 seconds if not configured. Used when `factor_type` is `totp`
  factor_type: string@factor-type-completer-1
  friendly_name: string # The friendly name of this Factor. This can be any string up to 64 characters, meant for humans to distinguish between Factors. For `factor_type` `push`, this could be a device name. For `factor_type` `totp`, this value is used as the “account name” in constructing the `binding.uri` property. At the same time, we recommend avoiding providing PII.
  --metadata: any # Custom metadata associated with the factor. This is added by the Device/SDK directly to allow for the inclusion of device information. It must be a stringified JSON with only strings values eg. `{"os": "Android"}`. Can be up to 1024 characters in length.
]: any -> record<account_sid: string, binding: any, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Factors"))
  let req_body = {"Binding.Alg": $binding_alg, "Binding.PublicKey": $binding_public_key, "Binding.Secret": $binding_secret, "Config.Alg": $config_alg, "Config.AppId": $config_app_id, "Config.CodeLength": $config_code_length, "Config.NotificationPlatform": $config_notification_platform, "Config.NotificationToken": $config_notification_token, "Config.SdkVersion": $config_sdk_version, "Config.Skew": $config_skew, "Config.TimeStep": $config_time_step, "FactorType": $factor_type, "FriendlyName": $friendly_name, "Metadata": $metadata} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Delete a specific Factor.
#
# DELETE /v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}
# operationId: DeleteFactor
export def "services-entities-factors delete" [
  service_sid: string
  identity: string
  sid: string
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
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Factors/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Factor.
#
# GET /v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}
# operationId: FetchFactor
export def "services-entities-factors get" [
  service_sid: string
  identity: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Factors/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Factor. This endpoint can be used to Verify a Factor if passed an `AuthPayload` param.
#
# POST /v2/Services/{ServiceSid}/Entities/{Identity}/Factors/{Sid}
# operationId: UpdateFactor
export def "services-entities-factors update" [
  service_sid: string
  identity: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-payload: string # The optional payload needed to verify the Factor for the first time. E.g. for a TOTP, the numeric code.
  --config-alg: string@config-alg-completer
  --config-code-length: int # Number of digits for generated TOTP codes. Must be between 3 and 8, inclusive
  --config-notification-platform: string # The transport technology used to generate the Notification Token. Can be `apn`, `fcm` or `none`. Required when `factor_type` is `push`.
  --config-notification-token: string # For APN, the device token. For FCM, the registration token. It is used to send the push notifications. Required when `factor_type` is `push`. If specified, this value must be between 32 and 255 characters long.
  --config-sdk-version: string # The Verify Push SDK version used to configure the factor
  --config-skew: int # The number of time-steps, past and future, that are valid for validation of TOTP codes. Must be between 0 and 2, inclusive
  --config-time-step: int # Defines how often, in seconds, are TOTP codes generated. i.e, a new TOTP code is generated every time_step seconds. Must be between 20 and 60 seconds, inclusive
  --friendly-name: string # The new friendly name of this Factor. It can be up to 64 characters.
]: any -> record<account_sid: string, config: any, date_created: string, date_updated: string, entity_sid: string, factor_type: string, friendly_name: string, identity: string, metadata: any, service_sid: string, sid: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), identity: (encode-path-segment $identity), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Entities/{identity}/Factors/{sid}"))
  let req_body = {"AuthPayload": $auth_payload, "Config.Alg": $config_alg, "Config.CodeLength": $config_code_length, "Config.NotificationPlatform": $config_notification_platform, "Config.NotificationToken": $config_notification_token, "Config.SdkVersion": $config_sdk_version, "Config.Skew": $config_skew, "Config.TimeStep": $config_time_step, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all Messaging Configurations for a Service.
#
# GET /v2/Services/{ServiceSid}/MessagingConfigurations
# operationId: ListMessagingConfiguration
export def "services-messaging-configurations list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<messaging_configurations: table<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/MessagingConfigurations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new MessagingConfiguration for a service.
#
# POST /v2/Services/{ServiceSid}/MessagingConfigurations
# operationId: CreateMessagingConfiguration
export def "services-messaging-configurations create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string # The [ISO-3166-1](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code of the country this configuration will be applied to. If this is a global configuration, Country will take the value `all`.
  messaging_service_sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) to be used to send SMS to the country of this configuration.
]: any -> record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/MessagingConfigurations"))
  let req_body = {"Country": $country, "MessagingServiceSid": $messaging_service_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Delete a specific MessagingConfiguration.
#
# DELETE /v2/Services/{ServiceSid}/MessagingConfigurations/{Country}
# operationId: DeleteMessagingConfiguration
export def "services-messaging-configurations delete" [
  service_sid: string
  country: string
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
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), country: (encode-path-segment $country)} | format pattern "/v2/Services/{service_sid}/MessagingConfigurations/{country}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific MessagingConfiguration.
#
# GET /v2/Services/{ServiceSid}/MessagingConfigurations/{Country}
# operationId: FetchMessagingConfiguration
export def "services-messaging-configurations get" [
  service_sid: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), country: (encode-path-segment $country)} | format pattern "/v2/Services/{service_sid}/MessagingConfigurations/{country}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific MessagingConfiguration
#
# POST /v2/Services/{ServiceSid}/MessagingConfigurations/{Country}
# operationId: UpdateMessagingConfiguration
export def "services-messaging-configurations update" [
  service_sid: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  messaging_service_sid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) to be used to send SMS to the country of this configuration.
]: any -> record<account_sid: string, country: string, date_created: string, date_updated: string, messaging_service_sid: string, service_sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), country: (encode-path-segment $country)} | format pattern "/v2/Services/{service_sid}/MessagingConfigurations/{country}"))
  let req_body = {"MessagingServiceSid": $messaging_service_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all Rate Limits for a service.
#
# GET /v2/Services/{ServiceSid}/RateLimits
# operationId: ListRateLimit
export def "services-rate-limits list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rate_limits: table<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/RateLimits") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Rate Limit for a Service
#
# POST /v2/Services/{ServiceSid}/RateLimits
# operationId: CreateRateLimit
export def "services-rate-limits create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of this Rate Limit
  unique_name: string # Provides a unique and addressable name to be assigned to this Rate Limit, assigned by the developer, to be optionally used in addition to SID. **This value should not contain PII.**
]: any -> record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/RateLimits"))
  let req_body = {"Description": $description, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all Buckets for a Rate Limit.
#
# GET /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets
# operationId: ListBucket
export def "services-rate-limits-buckets list" [
  service_sid: string
  rate_limit_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<buckets: table<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), rate_limit_sid: (encode-path-segment $rate_limit_sid)} | format pattern "/v2/Services/{service_sid}/RateLimits/{rate_limit_sid}/Buckets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Bucket for a Rate Limit
#
# POST /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets
# operationId: CreateBucket
export def "services-rate-limits-buckets create" [
  service_sid: string
  rate_limit_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  interval: int # Number of seconds that the rate limit will be enforced over.
  max: int # Maximum number of requests permitted in during the interval.
]: any -> record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), rate_limit_sid: (encode-path-segment $rate_limit_sid)} | format pattern "/v2/Services/{service_sid}/RateLimits/{rate_limit_sid}/Buckets"))
  let req_body = {"Interval": $interval, "Max": $max} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Delete a specific Bucket.
#
# DELETE /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}
# operationId: DeleteBucket
export def "services-rate-limits-buckets delete" [
  service_sid: string
  rate_limit_sid: string
  sid: string
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
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), rate_limit_sid: (encode-path-segment $rate_limit_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/RateLimits/{rate_limit_sid}/Buckets/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Bucket.
#
# GET /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}
# operationId: FetchBucket
export def "services-rate-limits-buckets get" [
  service_sid: string
  rate_limit_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), rate_limit_sid: (encode-path-segment $rate_limit_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/RateLimits/{rate_limit_sid}/Buckets/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Bucket.
#
# POST /v2/Services/{ServiceSid}/RateLimits/{RateLimitSid}/Buckets/{Sid}
# operationId: UpdateBucket
export def "services-rate-limits-buckets update" [
  service_sid: string
  rate_limit_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --interval: int # Number of seconds that the rate limit will be enforced over.
  --max: int # Maximum number of requests permitted in during the interval.
]: any -> record<account_sid: string, date_created: string, date_updated: string, interval: int, max: int, rate_limit_sid: string, service_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), rate_limit_sid: (encode-path-segment $rate_limit_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/RateLimits/{rate_limit_sid}/Buckets/{sid}"))
  let req_body = {"Interval": $interval, "Max": $max} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Delete a specific Rate Limit.
#
# DELETE /v2/Services/{ServiceSid}/RateLimits/{Sid}
# operationId: DeleteRateLimit
export def "services-rate-limits delete" [
  service_sid: string
  sid: string
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
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/RateLimits/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Rate Limit.
#
# GET /v2/Services/{ServiceSid}/RateLimits/{Sid}
# operationId: FetchRateLimit
export def "services-rate-limits get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/RateLimits/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Rate Limit.
#
# POST /v2/Services/{ServiceSid}/RateLimits/{Sid}
# operationId: UpdateRateLimit
export def "services-rate-limits update" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Description of this Rate Limit
]: any -> record<account_sid: string, date_created: string, date_updated: string, description: string, links: record, service_sid: string, sid: string, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/RateLimits/{sid}"))
  let req_body = {"Description": $description} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# challenge a specific Verification Check.
#
# POST /v2/Services/{ServiceSid}/VerificationCheck
# operationId: CreateVerificationCheck
export def "services-verification-check create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # The amount of the associated PSD2 compliant transaction. Requires the PSD2 Service flag enabled.
  --code: string # The 4-10 character string being verified.
  --payee: string # The payee of the associated PSD2 compliant transaction. Requires the PSD2 Service flag enabled.
  --body-to: string # The phone number or [email](https://www.twilio.com/docs/verify/email) to verify. Either this parameter or the `verification_sid` must be specified. Phone numbers must be in [E.164 format](https://www.twilio.com/docs/glossary/what-e164).
  --verification-sid: string # A SID that uniquely identifies the Verification Check. Either this parameter or the `to` phone number/[email](https://www.twilio.com/docs/verify/email) must be specified.
]: any -> record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, payee: string, service_sid: string, sid: string, sna_attempts_error_codes: list<any>, status: string, to: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/VerificationCheck"))
  let req_body = {"Amount": $amount, "Code": $code, "Payee": $payee, "To": $body_to, "VerificationSid": $verification_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Create a new Verification using a Service
#
# POST /v2/Services/{ServiceSid}/Verifications
# operationId: CreateVerification
export def "services-verifications create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: string # The amount of the associated PSD2 compliant transaction. Requires the PSD2 Service flag enabled.
  --app-hash: string # Your [App Hash](https://developers.google.com/identity/sms-retriever/verify#computing_your_apps_hash_string) to be appended at the end of your verification SMS body. Applies only to SMS. Example SMS body: `<#> Your AppName verification code is: 1234 He42w354ol9`.
  channel: string # The verification method to use. One of: [`email`](https://www.twilio.com/docs/verify/email), `sms`, `whatsapp`, `call`, `sna` or `auto`.
  --channel-configuration: any # [`email`](https://www.twilio.com/docs/verify/email) channel configuration in json format. The fields 'from' and 'from_name' are optional but if included the 'from' field must have a valid email address.
  --custom-code: string # A pre-generated code to use for verification. The code can be between 4 and 10 characters, inclusive.
  --custom-friendly-name: string # A custom user defined friendly name that overwrites the existing one in the verification message
  --custom-message: string # The text of a custom message to use for the verification.
  --device-ip: string # Strongly encouraged if using the auto channel. The IP address of the client's device. If provided, it has to be a valid IPv4 or IPv6 address.
  --locale: string # Locale will automatically resolve based on phone number country code for SMS, WhatsApp, and call channel verifications. It will fallback to English or the template’s default translation if the selected translation is not available. This parameter will override the automatic locale resolution. [See supported languages and more information here](https://www.twilio.com/docs/verify/supported-languages).
  --payee: string # The payee of the associated PSD2 compliant transaction. Requires the PSD2 Service flag enabled.
  --rate-limits: any # The custom key-value pairs of Programmable Rate Limits. Keys correspond to `unique_name` fields defined when [creating your Rate Limit](https://www.twilio.com/docs/verify/api/service-rate-limits). Associated value pairs represent values in the request that you are rate limiting on. You may include multiple Rate Limit values in each request.
  --send-digits: string # The digits to send after a phone call is answered, for example, to dial an extension. For more information, see the Programmable Voice documentation of [sendDigits](https://www.twilio.com/docs/voice/twiml/number#attributes-sendDigits).
  --template-custom-substitutions: string # A stringified JSON object in which the keys are the template's special variables and the values are the variables substitutions.
  --template-sid: string # The message [template](https://www.twilio.com/docs/verify/api/templates). If provided, will override the default template for the Service. SMS and Voice channels only.
  --body-to: string # The phone number or [email](https://www.twilio.com/docs/verify/email) to verify. Phone numbers must be in [E.164 format](https://www.twilio.com/docs/glossary/what-e164).
]: any -> record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Verifications"))
  let req_body = {"Amount": $amount, "AppHash": $app_hash, "Channel": $channel, "ChannelConfiguration": $channel_configuration, "CustomCode": $custom_code, "CustomFriendlyName": $custom_friendly_name, "CustomMessage": $custom_message, "DeviceIp": $device_ip, "Locale": $locale, "Payee": $payee, "RateLimits": $rate_limits, "SendDigits": $send_digits, "TemplateCustomSubstitutions": $template_custom_substitutions, "TemplateSid": $template_sid, "To": $body_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Fetch a specific Verification
#
# GET /v2/Services/{ServiceSid}/Verifications/{Sid}
# operationId: FetchVerification
export def "services-verifications get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Verifications/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Verification status
#
# POST /v2/Services/{ServiceSid}/Verifications/{Sid}
# operationId: UpdateVerification
export def "services-verifications update" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-2
]: any -> record<account_sid: string, amount: string, channel: string, date_created: string, date_updated: string, lookup: any, payee: string, send_code_attempts: list<any>, service_sid: string, sid: string, sna: any, status: string, to: string, url: string, valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Verifications/{sid}"))
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all Webhooks for a Service.
#
# GET /v2/Services/{ServiceSid}/Webhooks
# operationId: ListWebhook
export def "services-webhooks list" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, date_created: string, date_updated: string, event_types: list, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Webhooks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Webhook for the Service
#
# POST /v2/Services/{ServiceSid}/Webhooks
# operationId: CreateWebhook
export def "services-webhooks create" [
  service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  event_types: list<string> # The array of events that this Webhook is subscribed to. Possible event types: `*, factor.deleted, factor.created, factor.verified, challenge.approved, challenge.denied`
  friendly_name: string # The string that you assigned to describe the webhook. **This value should not contain PII.**
  --status: string@status-completer-3
  --version: string@version-completer
  webhook_url: string # The URL associated with this Webhook.
]: any -> record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid)} | format pattern "/v2/Services/{service_sid}/Webhooks"))
  let req_body = {"EventTypes": $event_types, "FriendlyName": $friendly_name, "Status": $status, "Version": $version, "WebhookUrl": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Delete a specific Webhook.
#
# DELETE /v2/Services/{ServiceSid}/Webhooks/{Sid}
# operationId: DeleteWebhook
export def "services-webhooks delete" [
  service_sid: string
  sid: string
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
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific Webhook.
#
# GET /v2/Services/{ServiceSid}/Webhooks/{Sid}
# operationId: FetchWebhook
export def "services-webhooks get" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v2/Services/{ServiceSid}/Webhooks/{Sid}
#
# operationId: UpdateWebhook
export def "services-webhooks update" [
  service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-types: list<string> # The array of events that this Webhook is subscribed to. Possible event types: `*, factor.deleted, factor.created, factor.verified, challenge.approved, challenge.denied`
  --friendly-name: string # The string that you assigned to describe the webhook. **This value should not contain PII.**
  --status: string@status-completer-3
  --version: string@version-completer
  --webhook-url: string # The URL associated with this Webhook.
]: any -> record<account_sid: string, date_created: string, date_updated: string, event_types: list<string>, friendly_name: string, service_sid: string, sid: string, status: string, url: string, version: string, webhook_method: string, webhook_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({service_sid: (encode-path-segment $service_sid), sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{service_sid}/Webhooks/{sid}"))
  let req_body = {"EventTypes": $event_types, "FriendlyName": $friendly_name, "Status": $status, "Version": $version, "WebhookUrl": $webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Delete a specific Verification Service Instance.
#
# DELETE /v2/Services/{Sid}
# operationId: DeleteService
export def "services delete" [
  sid: string
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
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch specific Verification Service Instance.
#
# GET /v2/Services/{Sid}
# operationId: FetchService
export def "services get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Verification Service.
#
# POST /v2/Services/{Sid}
# operationId: UpdateService
export def "services update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code-length: int # The length of the verification code to generate. Must be an integer value between 4 and 10, inclusive.
  --custom-code-enabled: oneof<nothing, bool> # Whether to allow sending verifications with a custom code instead of a randomly generated one. Not available for all customers.
  --default-template-sid: string # The default message [template](https://www.twilio.com/docs/verify/api/templates). Will be used for all SMS verifications unless explicitly overriden. SMS channel only.
  --do-not-share-warning-enabled: oneof<nothing, bool> # Whether to add a privacy warning at the end of an SMS. **Disabled by default and applies only for SMS.**
  --dtmf-input-required: oneof<nothing, bool> # Whether to ask the user to press a number before delivering the verify code in a phone call.
  --friendly-name: string # A descriptive string that you create to describe the verification service. It can be up to 32 characters long. **This value should not contain PII.**
  --lookup-enabled: oneof<nothing, bool> # Whether to perform a lookup with each verification started and return info about the phone number.
  --psd2-enabled: oneof<nothing, bool> # Whether to pass PSD2 transaction parameters when starting a verification.
  --push-apn-credential-sid: string # Optional configuration for the Push factors. Set the APN Credential for this service. This will allow to send push notifications to iOS devices. See [Credential Resource](https://www.twilio.com/docs/notify/api/credential-resource)
  --push-fcm-credential-sid: string # Optional configuration for the Push factors. Set the FCM Credential for this service. This will allow to send push notifications to Android devices. See [Credential Resource](https://www.twilio.com/docs/notify/api/credential-resource)
  --push-include-date: oneof<nothing, bool> # Optional configuration for the Push factors. If true, include the date in the Challenge's response. Otherwise, the date is omitted from the response. See [Challenge](https://www.twilio.com/docs/verify/api/challenge) resource’s details parameter for more info. Default: false. **Deprecated** do not use this parameter.
  --skip-sms-to-landlines: oneof<nothing, bool> # Whether to skip sending SMS verifications to landlines. Requires `lookup_enabled`.
  --totp-code-length: int # Optional configuration for the TOTP factors. Number of digits for generated TOTP codes. Must be between 3 and 8, inclusive. Defaults to 6
  --totp-issuer: string # Optional configuration for the TOTP factors. Set TOTP Issuer for this service. This will allow to configure the issuer of the TOTP URI.
  --totp-skew: int # Optional configuration for the TOTP factors. The number of time-steps, past and future, that are valid for validation of TOTP codes. Must be between 0 and 2, inclusive. Defaults to 1
  --totp-time-step: int # Optional configuration for the TOTP factors. Defines how often, in seconds, are TOTP codes generated. i.e, a new TOTP code is generated every time_step seconds. Must be between 20 and 60 seconds, inclusive. Defaults to 30 seconds
  --tts-name: string # The name of an alternative text-to-speech service to use in phone calls. Applies only to TTS languages.
]: any -> record<account_sid: string, code_length: int, custom_code_enabled: bool, date_created: string, date_updated: string, default_template_sid: string, do_not_share_warning_enabled: bool, dtmf_input_required: bool, friendly_name: string, links: record, lookup_enabled: bool, psd2_enabled: bool, push: any, sid: string, skip_sms_to_landlines: bool, totp: any, tts_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v2/Services/{sid}"))
  let req_body = {"CodeLength": $code_length, "CustomCodeEnabled": $custom_code_enabled, "DefaultTemplateSid": $default_template_sid, "DoNotShareWarningEnabled": $do_not_share_warning_enabled, "DtmfInputRequired": $dtmf_input_required, "FriendlyName": $friendly_name, "LookupEnabled": $lookup_enabled, "Psd2Enabled": $psd2_enabled, "Push.ApnCredentialSid": $push_apn_credential_sid, "Push.FcmCredentialSid": $push_fcm_credential_sid, "Push.IncludeDate": $push_include_date, "SkipSmsToLandlines": $skip_sms_to_landlines, "Totp.CodeLength": $totp_code_length, "Totp.Issuer": $totp_issuer, "Totp.Skew": $totp_skew, "Totp.TimeStep": $totp_time_step, "TtsName": $tts_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# List all the available templates for a given Account.
#
# GET /v2/Templates
# operationId: ListVerificationTemplate
export def "templates list-verification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --friendly-name: string # String filter used to query templates with a given friendly name.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, templates: table<account_sid: string, channels: list, friendly_name: string, sid: string, translations: any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://verify.twilio.com")
  let qp = [(serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/Templates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
