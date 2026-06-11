# Auto-generated client for Twilio - Lookups v1.0.0
# Source: https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_lookups_v2.json
# Auth: --token flag or $env.TWILIO_LOOKUPS_TOKEN

const BASE_URL = "https://lookups.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_LOOKUPS_TOKEN | default "" }
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
def base-url-completer [] { ["https://lookups.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def line-type-completer [] { ["fixedVoip" "landline" "mobile" "nonFixedVoip" "pager" "personal" "premium" "sharedCost" "tollFree" "uan" "unknown" "voicemail"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "phone-numbers FetchPhoneNumber" } } | get name | first)
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

# Full API documentation: https://www.twilio.com/docs/lookup/v2-api
#
# GET /v2/PhoneNumbers/{PhoneNumber}
# operationId: FetchPhoneNumber
export def "phone-numbers FetchPhoneNumber" [
  PhoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Fields: string # A comma-separated list of fields to return. Possible values are validation, caller_name, sim_swap, call_forwarding, line_status, line_type_intelligence, identity_match, reassigned_number, sms_pumping_risk, phone_number_quality_score, pre_fill.
  --CountryCode: string # The [country code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) used if the phone number provided is in national format.
  --FirstName: string # User’s first name. This query parameter is only used (optionally) for identity_match package requests.
  --LastName: string # User’s last name. This query parameter is only used (optionally) for identity_match package requests.
  --AddressLine1: string # User’s first address line. This query parameter is only used (optionally) for identity_match package requests.
  --AddressLine2: string # User’s second address line. This query parameter is only used (optionally) for identity_match package requests.
  --City: string # User’s city. This query parameter is only used (optionally) for identity_match package requests.
  --State: string # User’s country subdivision, such as state, province, or locality. This query parameter is only used (optionally) for identity_match package requests.
  --PostalCode: string # User’s postal zip code. This query parameter is only used (optionally) for identity_match package requests.
  --AddressCountryCode: string # User’s country, up to two characters. This query parameter is only used (optionally) for identity_match package requests. (format: iso-country-code)
  --NationalId: string # User’s national ID, such as SSN or Passport ID. This query parameter is only used (optionally) for identity_match package requests.
  --DateOfBirth: string # User’s date of birth, in YYYYMMDD format. This query parameter is only used (optionally) for identity_match package requests.
  --LastVerifiedDate: string # The date you obtained consent to call or text the end-user of the phone number or a date on which you are reasonably certain that the end-user could still be reached at that number. This query parameter is only used (optionally) for reassigned_number package requests.
  --VerificationSid: string # The unique identifier associated with a verification process through verify API. This query parameter is only used (optionally) for pre_fill package requests.
  --PartnerSubId: string # The optional partnerSubId parameter to provide context for your sub-accounts, tenantIDs, sender IDs or other segmentation, enhancing the accuracy of the risk analysis.
]: nothing -> record<calling_country_code: string, country_code: string, phone_number: string, national_format: string, valid: bool, validation_errors: list<string>, caller_name: record<caller_name: string, caller_type: string, error_code: int>, sim_swap: record<last_sim_swap: record<last_sim_swap_date: string, swapped_period: string, swapped_in_period: bool>, carrier_name: string, mobile_country_code: string, mobile_network_code: string, error_code: int>, call_forwarding: record<call_forwarding_enabled: bool, error_code: int>, line_type_intelligence: record<mobile_country_code: string, mobile_network_code: string, carrier_name: string, type: string, error_code: int>, line_status: record<status: string, error_code: int>, identity_match: record<first_name_match: string, last_name_match: string, address_lines_match: string, city_match: string, state_match: string, postal_code_match: string, address_country_match: string, national_id_match: string, date_of_birth_match: string, summary_score: int, error_code: int, error_message: string>, reassigned_number: record<last_verified_date: string, is_number_reassigned: string, error_code: string>, sms_pumping_risk: record<carrier_risk_category: string, number_blocked: bool, number_blocked_date: string, number_blocked_last_3_months: bool, sms_pumping_risk_score: int, error_code: int>, phone_number_quality_score: any, pre_fill: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://lookups.twilio.com")
  let qp = [(serialize-qp "Fields" $Fields "scalar") (serialize-qp "CountryCode" $CountryCode "scalar") (serialize-qp "FirstName" $FirstName "scalar") (serialize-qp "LastName" $LastName "scalar") (serialize-qp "AddressLine1" $AddressLine1 "scalar") (serialize-qp "AddressLine2" $AddressLine2 "scalar") (serialize-qp "City" $City "scalar") (serialize-qp "State" $State "scalar") (serialize-qp "PostalCode" $PostalCode "scalar") (serialize-qp "AddressCountryCode" $AddressCountryCode "scalar") (serialize-qp "NationalId" $NationalId "scalar") (serialize-qp "DateOfBirth" $DateOfBirth "scalar") (serialize-qp "LastVerifiedDate" $LastVerifiedDate "scalar") (serialize-qp "VerificationSid" $VerificationSid "scalar") (serialize-qp "PartnerSubId" $PartnerSubId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/PhoneNumbers/($PhoneNumber)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# In Request Bulk
#
# POST /v2/batch/query
# operationId: CreateBulkLookup
# --phone_numbers item shape: {correlation_id?: string, phone_number: string, fields?: list, country_code?: string, identity_match?: record, reassigned_number?: record, sms_pumping_risk?: record}
export def "batch-query CreateBulkLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --phone-numbers: list # item shape: {correlation_id?: string, phone_number: string, fields?: list, country_code?: string, identity_match?: record, reassigned_number?: record, sms_pumping_risk?: record}
]: any -> record<phone_numbers: table<correlation_id: string, twilio_error_code: int, calling_country_code: string, country_code: string, phone_number: string, national_format: string, valid: bool, validation_errors: list, caller_name: record, sim_swap: record, call_forwarding: record, line_type_intelligence: record, line_status: record, identity_match: record, reassigned_number: record, sms_pumping_risk: record, phone_number_quality_score: any, pre_fill: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/batch/query")
  let body = {phone_numbers: $phone_numbers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get account rate limits
#
# GET /v2/RateLimits
# operationId: FetchLookupAccountRateLimits
export def "rate-limits FetchLookupAccountRateLimits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Fields: list
]: nothing -> record<rate_limits: table<field: string, limit: int, bucket: string, owner: string, ttl: int>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Fields" $Fields "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/RateLimits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rate limit
#
# GET /v2/RateLimits/Fields/{Field}/Bucket/{Bucket}
# operationId: FetchLookupRateLimit
export def "rate-limits-fields-bucket FetchLookupRateLimit" [
  Field: string
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<field: string, limit: int, bucket: string, owner: string, ttl: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/RateLimits/Fields/($Field)/Bucket/($Bucket)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete rate limit
#
# DELETE /v2/RateLimits/Fields/{Field}/Bucket/{Bucket}
# operationId: DeleteLookupRateLimit
export def "rate-limits-fields-bucket DeleteLookupRateLimit" [
  Field: string
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/RateLimits/Fields/($Field)/Bucket/($Bucket)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upsert rate limit
#
# PUT /v2/RateLimits/Fields/{Field}/Bucket/{Bucket}
# operationId: UpdateLookupRateLimit
export def "rate-limits-fields-bucket UpdateLookupRateLimit" [
  Field: string
  Bucket: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit of requests for the bucket (format: int32)
  --ttl: int # Time to live of the rule (format: int32)
]: any -> record<field: string, limit: int, bucket: string, owner: string, ttl: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/RateLimits/Fields/($Field)/Bucket/($Bucket)")
  let body = {limit: $limit, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Overrides for a Phone Number for a specific field.
#
# GET /v2/PhoneNumbers/{PhoneNumber}/Overrides/{Field}
# operationId: FetchLookupPhoneNumberOverrides
export def "phone-numbers-overrides FetchLookupPhoneNumberOverrides" [
  Field: string
  PhoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<phone_number: string, original_line_type: string, overridden_line_type: string, override_reason: string, override_timestamp: string, overridden_by_account_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/PhoneNumbers/($PhoneNumber)/Overrides/($Field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Override for a Phone Number for a specific field
#
# POST /v2/PhoneNumbers/{PhoneNumber}/Overrides/{Field}
# operationId: CreateLookupPhoneNumberOverrides
export def "phone-numbers-overrides CreateLookupPhoneNumberOverrides" [
  Field: string
  PhoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --line-type: string@line-type-completer # The new line type to override the original line type
  --reason: string # The reason for the override
]: any -> record<phone_number: string, original_line_type: string, overridden_line_type: string, override_reason: string, override_timestamp: string, overridden_by_account_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/PhoneNumbers/($PhoneNumber)/Overrides/($Field)")
  let body = {line_type: $line_type, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Override for a Phone Number for a specific field
#
# PUT /v2/PhoneNumbers/{PhoneNumber}/Overrides/{Field}
# operationId: UpdateLookupPhoneNumberOverrides
export def "phone-numbers-overrides UpdateLookupPhoneNumberOverrides" [
  Field: string
  PhoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --line-type: string@line-type-completer # The new line type to override the original line type
  --reason: string # The reason for the override
]: any -> record<phone_number: string, original_line_type: string, overridden_line_type: string, override_reason: string, override_timestamp: string, overridden_by_account_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/PhoneNumbers/($PhoneNumber)/Overrides/($Field)")
  let body = {line_type: $line_type, reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Override for a Phone Number for a specific field
#
# DELETE /v2/PhoneNumbers/{PhoneNumber}/Overrides/{Field}
# operationId: DeleteLookupPhoneNumberOverrides
export def "phone-numbers-overrides DeleteLookupPhoneNumberOverrides" [
  Field: string
  PhoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/PhoneNumbers/($PhoneNumber)/Overrides/($Field)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
