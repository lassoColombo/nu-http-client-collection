# Auto-generated client for Twilio - Messaging v1.0.0
# Source: https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_messaging_v1.json
# Auth: --token flag or $env.TWILIO_MESSAGING_TOKEN

const BASE_URL = "https://messaging.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_MESSAGING_TOKEN | default "" }
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

def base-url-completer [] { ["https://messaging.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def VettingProvider-completer [] { ["aegis" "campaign-verify"] }
def InboundMethod-completer [] { ["GET" "POST"] }
def FallbackMethod-completer [] { ["GET" "POST"] }
def ScanMessageContent-completer [] { ["disable" "enable" "inherit"] }
def OptInType-completer [] { ["IMPORT" "IMPORT_PLEASE_REPLACE" "MOBILE_QR_CODE" "PAPER_FORM" "VERBAL" "VIA_TEXT" "WEB_FORM"] }
def BusinessRegistrationAuthority-completer [] { ["ABN" "ACN" "BRN" "CBN" "CIF" "CNPJ" "CRN" "EIN" "NEQ" "NIF" "NZBN" "OTHER" "PROVINCIAL_NUMBER" "SIREN" "SIRET" "UID" "USt-IdNr" "VAT"] }
def BusinessType-completer [] { ["GOVERNMENT" "NON_PROFIT" "PRIVATE_PROFIT" "PUBLIC_PROFIT" "SOLE_PROPRIETOR"] }
def VettingProvider-completer-1 [] { ["CAMPAIGN_VERIFY"] }
def Status-completer [] { ["IN_REVIEW" "PENDING_REVIEW" "TWILIO_APPROVED" "TWILIO_REJECTED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "services-alpha-senders CreateAlphaSender" } } | get name | first)
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

# POST /v1/Services/{ServiceSid}/AlphaSenders
#
# operationId: CreateAlphaSender
export def "services-alpha-senders CreateAlphaSender" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  AlphaSender: string # The Alphanumeric Sender ID string. Can be up to 11 characters long. Valid characters are A-Z, a-z, 0-9, space, hyphen `-`, plus `+`, underscore `_` and ampersand `&`. This value cannot contain only numbers.
]: any -> record<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, alpha_sender: string, capabilities: list<string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/AlphaSenders")
  let body = {AlphaSender: $AlphaSender} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/AlphaSenders
#
# operationId: ListAlphaSender
export def "services-alpha-senders ListAlphaSender" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<alpha_senders: table<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, alpha_sender: string, capabilities: list, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/AlphaSenders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/AlphaSenders/{Sid}
#
# operationId: FetchAlphaSender
export def "services-alpha-senders FetchAlphaSender" [
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
]: nothing -> record<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, alpha_sender: string, capabilities: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/AlphaSenders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{ServiceSid}/AlphaSenders/{Sid}
#
# operationId: DeleteAlphaSender
export def "services-alpha-senders DeleteAlphaSender" [
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/AlphaSenders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/a2p/BrandRegistrations/{BrandRegistrationSid}/SmsOtp
#
# operationId: CreateBrandRegistrationOtp
export def "a2p-brand-registrations-sms-otp CreateBrandRegistrationOtp" [
  BrandRegistrationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, brand_registration_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($BrandRegistrationSid)/SmsOtp")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/a2p/BrandRegistrations/{Sid}
#
# operationId: FetchBrandRegistrations
export def "a2p-brand-registrations FetchBrandRegistrations" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sid: string, account_sid: string, customer_profile_bundle_sid: string, a2p_profile_bundle_sid: string, date_created: string, date_updated: string, brand_type: string, status: string, tcr_id: string, failure_reason: string, errors: list<any>, url: string, brand_score: int, brand_feedback: list<string>, identity_status: string, russell_3000: bool, government_entity: bool, tax_exempt_status: string, skip_automatic_sec_vet: bool, mock: bool, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/a2p/BrandRegistrations/{Sid}
#
# operationId: UpdateBrandRegistrations
export def "a2p-brand-registrations UpdateBrandRegistrations" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sid: string, account_sid: string, customer_profile_bundle_sid: string, a2p_profile_bundle_sid: string, date_created: string, date_updated: string, brand_type: string, status: string, tcr_id: string, failure_reason: string, errors: list<any>, url: string, brand_score: int, brand_feedback: list<string>, identity_status: string, russell_3000: bool, government_entity: bool, tax_exempt_status: string, skip_automatic_sec_vet: bool, mock: bool, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/a2p/BrandRegistrations
#
# operationId: ListBrandRegistrations
export def "a2p-brand-registrations ListBrandRegistrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<data: table<sid: string, account_sid: string, customer_profile_bundle_sid: string, a2p_profile_bundle_sid: string, date_created: string, date_updated: string, brand_type: string, status: string, tcr_id: string, failure_reason: string, errors: list, url: string, brand_score: int, brand_feedback: list, identity_status: string, russell_3000: bool, government_entity: bool, tax_exempt_status: string, skip_automatic_sec_vet: bool, mock: bool, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/a2p/BrandRegistrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/a2p/BrandRegistrations
#
# operationId: CreateBrandRegistrations
export def "a2p-brand-registrations CreateBrandRegistrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  CustomerProfileBundleSid: string # Customer Profile Bundle Sid.
  A2PProfileBundleSid: string # A2P Messaging Profile Bundle Sid.
  --BrandType: string # Type of brand being created. One of: "STANDARD", "SOLE_PROPRIETOR". SOLE_PROPRIETOR is for low volume, SOLE_PROPRIETOR use cases. STANDARD is for all other use cases.
  --Mock: oneof<nothing, bool> # A boolean that specifies whether brand should be a mock or not. If true, brand will be registered as a mock brand. Defaults to false if no value is provided.
  --SkipAutomaticSecVet: oneof<nothing, bool> # A flag to disable automatic secondary vetting for brands which it would otherwise be done.
]: any -> record<sid: string, account_sid: string, customer_profile_bundle_sid: string, a2p_profile_bundle_sid: string, date_created: string, date_updated: string, brand_type: string, status: string, tcr_id: string, failure_reason: string, errors: list<any>, url: string, brand_score: int, brand_feedback: list<string>, identity_status: string, russell_3000: bool, government_entity: bool, tax_exempt_status: string, skip_automatic_sec_vet: bool, mock: bool, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/a2p/BrandRegistrations")
  let body = {CustomerProfileBundleSid: $CustomerProfileBundleSid, A2PProfileBundleSid: $A2PProfileBundleSid, BrandType: $BrandType, Mock: $Mock, SkipAutomaticSecVet: $SkipAutomaticSecVet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/a2p/BrandRegistrations/{BrandSid}/Vettings
#
# operationId: CreateBrandVetting
export def "a2p-brand-registrations-vettings CreateBrandVetting" [
  BrandSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  VettingProvider: string@VettingProvider-completer # The third-party provider that has conducted the vetting. One of “CampaignVerify” (Campaign Verify tokens) or “AEGIS” (Secondary Vetting).
  --VettingId: string # The unique ID of the vetting
]: any -> record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_updated: string, date_created: string, vetting_id: string, vetting_class: string, vetting_status: string, vetting_provider: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($BrandSid)/Vettings")
  let body = {VettingProvider: $VettingProvider, VettingId: $VettingId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/a2p/BrandRegistrations/{BrandSid}/Vettings
#
# operationId: ListBrandVetting
export def "a2p-brand-registrations-vettings ListBrandVetting" [
  BrandSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --VettingProvider: string@VettingProvider-completer # The third-party provider of the vettings to read
]: nothing -> record<data: table<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_updated: string, date_created: string, vetting_id: string, vetting_class: string, vetting_status: string, vetting_provider: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "VettingProvider" $VettingProvider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($BrandSid)/Vettings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/a2p/BrandRegistrations/{BrandSid}/Vettings/{BrandVettingSid}
#
# operationId: FetchBrandVetting
export def "a2p-brand-registrations-vettings FetchBrandVetting" [
  BrandSid: string
  BrandVettingSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, brand_sid: string, brand_vetting_sid: string, date_updated: string, date_created: string, vetting_id: string, vetting_class: string, vetting_status: string, vetting_provider: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/a2p/BrandRegistrations/($BrandSid)/Vettings/($BrandVettingSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{MessagingServiceSid}/ChannelSenders
#
# operationId: ListChannelSender
export def "services-channel-senders ListChannelSender" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<senders: table<account_sid: string, messaging_service_sid: string, sid: string, sender: string, sender_type: string, country_code: string, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/ChannelSenders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{MessagingServiceSid}/ChannelSenders
#
# operationId: CreateChannelSender
export def "services-channel-senders CreateChannelSender" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  Sid: string # The SID of the Channel Sender being added to the Service.
]: any -> record<account_sid: string, messaging_service_sid: string, sid: string, sender: string, sender_type: string, country_code: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/ChannelSenders")
  let body = {Sid: $Sid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{MessagingServiceSid}/ChannelSenders/{Sid}
#
# operationId: FetchChannelSender
export def "services-channel-senders FetchChannelSender" [
  MessagingServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, messaging_service_sid: string, sid: string, sender: string, sender_type: string, country_code: string, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/ChannelSenders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{MessagingServiceSid}/ChannelSenders/{Sid}
#
# operationId: DeleteChannelSender
export def "services-channel-senders DeleteChannelSender" [
  MessagingServiceSid: string
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/ChannelSenders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a list of all United States numbers that have been deactivated on a specific date.
#
# GET /v1/Deactivations
# operationId: FetchDeactivation
export def "deactivations FetchDeactivation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Date: string # The request will return a list of all United States Phone Numbers that were deactivated on the day specified by this parameter. This date should be specified in YYYY-MM-DD format. (format: date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "Date" $Date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Deactivations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/DestinationAlphaSenders
#
# operationId: CreateDestinationAlphaSender
export def "services-destination-alpha-senders CreateDestinationAlphaSender" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  AlphaSender: string # The Alphanumeric Sender ID string. Can be up to 11 characters long. Valid characters are A-Z, a-z, 0-9, space, hyphen `-`, plus `+`, underscore `_` and ampersand `&`. This value cannot contain only numbers.
  --IsoCountryCode: string # The Optional Two Character ISO Country Code the Alphanumeric Sender ID will be used for. If the IsoCountryCode is not provided, a default Alpha Sender will be created that can be used across all countries.
]: any -> record<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, alpha_sender: string, capabilities: list<string>, url: string, iso_country_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/DestinationAlphaSenders")
  let body = {AlphaSender: $AlphaSender, IsoCountryCode: $IsoCountryCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/DestinationAlphaSenders
#
# operationId: ListDestinationAlphaSender
export def "services-destination-alpha-senders ListDestinationAlphaSender" [
  ServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --IsoCountryCode: string # Optional filter to return only alphanumeric sender IDs associated with the specified two-character ISO country code.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<alpha_senders: table<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, alpha_sender: string, capabilities: list, url: string, iso_country_code: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "IsoCountryCode" $IsoCountryCode "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/DestinationAlphaSenders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/DestinationAlphaSenders/{Sid}
#
# operationId: FetchDestinationAlphaSender
export def "services-destination-alpha-senders FetchDestinationAlphaSender" [
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
]: nothing -> record<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, alpha_sender: string, capabilities: list<string>, url: string, iso_country_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/DestinationAlphaSenders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{ServiceSid}/DestinationAlphaSenders/{Sid}
#
# operationId: DeleteDestinationAlphaSender
export def "services-destination-alpha-senders DeleteDestinationAlphaSender" [
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/DestinationAlphaSenders/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: UpdateDomainCertV4
export def "link-shortening-domains-certificate UpdateDomainCertV4" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  TlsCert: string # Contains the full TLS certificate and private for this domain in PEM format: https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail. Twilio uses this information to process HTTPS traffic sent to your domain.
]: any -> record<domain_sid: string, date_updated: string, date_expires: string, date_created: string, domain_name: string, certificate_sid: string, url: string, cert_in_validation: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Certificate")
  let body = {TlsCert: $TlsCert} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: FetchDomainCertV4
export def "link-shortening-domains-certificate FetchDomainCertV4" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_sid: string, date_updated: string, date_expires: string, date_created: string, domain_name: string, certificate_sid: string, url: string, cert_in_validation: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Certificate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/LinkShortening/Domains/{DomainSid}/Certificate
#
# operationId: DeleteDomainCertV4
export def "link-shortening-domains-certificate DeleteDomainCertV4" [
  DomainSid: string
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Certificate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/Config
#
# operationId: UpdateDomainConfig
export def "link-shortening-domains-config UpdateDomainConfig" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --FallbackUrl: string # Any requests we receive to this domain that do not match an existing shortened message will be redirected to the fallback url. These will likely be either expired messages, random misdirected traffic, or intentional scraping. (format: uri)
  --CallbackUrl: string # URL to receive click events to your webhook whenever the recipients click on the shortened links (format: uri)
  --ContinueOnFailure: oneof<nothing, bool> # Boolean field to set customer delivery preference when there is a failure in linkShortening service
  --DisableHttps: oneof<nothing, bool> # Customer's choice to send links with/without "https://" attached to shortened url. If true, messages will not be sent with https:// at the beginning of the url. If false, messages will be sent with https:// at the beginning of the url. False is the default behavior if it is not specified.
]: any -> record<domain_sid: string, config_sid: string, fallback_url: string, callback_url: string, continue_on_failure: bool, date_created: string, date_updated: string, url: string, disable_https: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Config")
  let body = {FallbackUrl: $FallbackUrl, CallbackUrl: $CallbackUrl, ContinueOnFailure: $ContinueOnFailure, DisableHttps: $DisableHttps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/LinkShortening/Domains/{DomainSid}/Config
#
# operationId: FetchDomainConfig
export def "link-shortening-domains-config FetchDomainConfig" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_sid: string, config_sid: string, fallback_url: string, callback_url: string, continue_on_failure: bool, date_created: string, date_updated: string, url: string, disable_https: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/Config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/LinkShortening/MessagingService/{MessagingServiceSid}/DomainConfig
#
# operationId: FetchDomainConfigMessagingService
export def "link-shortening-messaging-service-domain-config FetchDomainConfigMessagingService" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_sid: string, config_sid: string, messaging_service_sid: string, fallback_url: string, callback_url: string, continue_on_failure: bool, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/MessagingService/($MessagingServiceSid)/DomainConfig")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/LinkShortening/Domains/{DomainSid}/ValidateDns
#
# operationId: FetchDomainDnsValidation
export def "link-shortening-domains-validate-dns FetchDomainDnsValidation" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_sid: string, is_valid: bool, reason: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/ValidateDns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/PreregisteredUsa2p
#
# operationId: CreateExternalCampaign
export def "services-preregistered-usa2p CreateExternalCampaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  CampaignId: string # ID of the preregistered campaign.
  MessagingServiceSid: string # The SID of the [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource) that the resource is associated with.
  --CnpMigration: oneof<nothing, bool> # Customers should use this flag during the ERC registration process to indicate to Twilio that the campaign being registered is undergoing CNP migration. It is important for the user to first trigger the CNP migration process for said campaign in their CSP portal and have Twilio accept the sharing request, before making this api call.
]: any -> record<sid: string, account_sid: string, campaign_id: string, messaging_service_sid: string, date_created: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services/PreregisteredUsa2p")
  let body = {CampaignId: $CampaignId, MessagingServiceSid: $MessagingServiceSid, CnpMigration: $CnpMigration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}
#
# operationId: CreateLinkshorteningMessagingService
export def "link-shortening-domains-messaging-services CreateLinkshorteningMessagingService" [
  DomainSid: string
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_sid: string, messaging_service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/MessagingServices/($MessagingServiceSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/LinkShortening/Domains/{DomainSid}/MessagingServices/{MessagingServiceSid}
#
# operationId: DeleteLinkshorteningMessagingService
export def "link-shortening-domains-messaging-services DeleteLinkshorteningMessagingService" [
  DomainSid: string
  MessagingServiceSid: string
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/MessagingServices/($MessagingServiceSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/LinkShortening/MessagingServices/{MessagingServiceSid}/Domain
#
# operationId: FetchLinkshorteningMessagingServiceDomainAssociation
export def "link-shortening-messaging-services-domain FetchLinkshorteningMessagingServiceDomainAssociation" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_sid: string, messaging_service_sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/MessagingServices/($MessagingServiceSid)/Domain")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/PhoneNumbers
#
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
  PhoneNumberSid: string # The SID of the Phone Number being added to the Service.
]: any -> record<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, phone_number: string, country_code: string, capabilities: list<string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers")
  let body = {PhoneNumberSid: $PhoneNumberSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/PhoneNumbers
#
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
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<phone_numbers: table<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, phone_number: string, country_code: string, capabilities: list, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
#
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/PhoneNumbers/{Sid}
#
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
]: nothing -> record<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, phone_number: string, country_code: string, capabilities: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/PhoneNumbers/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/LinkShortening/Domains/{DomainSid}/RequestManagedCert
#
# operationId: UpdateRequestManagedCert
export def "link-shortening-domains-request-managed-cert UpdateRequestManagedCert" [
  DomainSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<domain_sid: string, date_updated: string, date_created: string, date_expires: string, domain_name: string, certificate_sid: string, url: string, managed: bool, requesting: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/LinkShortening/Domains/($DomainSid)/RequestManagedCert")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services
#
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
  FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --InboundRequestUrl: string # The URL we call using `inbound_method` when a message is received by any phone number or short code in the Service. When this property is `null`, receiving inbound messages is disabled. All messages sent to the Twilio phone number or short code will not be logged and received on the Account. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `inbound_request_url` defined for the Messaging Service. (format: uri)
  --InboundMethod: string@InboundMethod-completer # The HTTP method we should use to call `inbound_request_url`. Can be `GET` or `POST` and the default is `POST`. (format: http-method)
  --FallbackUrl: string # The URL that we call using `fallback_method` if an error occurs while retrieving or executing the TwiML from the Inbound Request URL. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `fallback_url` defined for the Messaging Service. (format: uri)
  --FallbackMethod: string@FallbackMethod-completer # The HTTP method we should use to call `fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --StatusCallback: string # The URL we should call to [pass status updates](https://www.twilio.com/docs/sms/api/message-resource#message-status-values) about message delivery. (format: uri)
  --StickySender: oneof<nothing, bool> # Whether to enable [Sticky Sender](https://www.twilio.com/docs/messaging/services#sticky-sender) on the Service instance.
  --MmsConverter: oneof<nothing, bool> # Whether to enable the [MMS Converter](https://www.twilio.com/docs/messaging/services#mms-converter) for messages sent through the Service instance.
  --SmartEncoding: oneof<nothing, bool> # Whether to enable [Smart Encoding](https://www.twilio.com/docs/messaging/services#smart-encoding) for messages sent through the Service instance.
  --ScanMessageContent: string@ScanMessageContent-completer # Reserved.
  --FallbackToLongCode: oneof<nothing, bool> # [OBSOLETE] Former feature used to fallback to long code sender after certain short code message failures.
  --AreaCodeGeomatch: oneof<nothing, bool> # Whether to enable [Area Code Geomatch](https://www.twilio.com/docs/messaging/services#area-code-geomatch) on the Service Instance.
  --ValidityPeriod: int # How long, in seconds, messages sent from the Service are valid. Can be an integer from `1` to `36,000`. Default value is `36,000`.
  --SynchronousValidation: oneof<nothing, bool> # Reserved.
  --Usecase: string # A string that describes the scenario in which the Messaging Service will be used. Possible values are `notifications`, `marketing`, `verification`, `discussion`, `poll`, `undeclared`.
  --UseInboundWebhookOnNumber: oneof<nothing, bool> # A boolean value that indicates either the webhook url configured on the phone number will be used or `inbound_request_url`/`fallback_url` url will be called when a message is received from the phone number. If this field is enabled then the webhook url defined on the phone number will override the `inbound_request_url`/`fallback_url` defined for the Messaging Service.
]: any -> record<sid: string, account_sid: string, friendly_name: string, date_created: string, date_updated: string, inbound_request_url: string, inbound_method: string, fallback_url: string, fallback_method: string, status_callback: string, sticky_sender: bool, mms_converter: bool, smart_encoding: bool, scan_message_content: string, fallback_to_long_code: bool, area_code_geomatch: bool, synchronous_validation: bool, validity_period: int, url: string, links: record, usecase: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services")
  let body = {FriendlyName: $FriendlyName, InboundRequestUrl: $InboundRequestUrl, InboundMethod: $InboundMethod, FallbackUrl: $FallbackUrl, FallbackMethod: $FallbackMethod, StatusCallback: $StatusCallback, StickySender: $StickySender, MmsConverter: $MmsConverter, SmartEncoding: $SmartEncoding, ScanMessageContent: $ScanMessageContent, FallbackToLongCode: $FallbackToLongCode, AreaCodeGeomatch: $AreaCodeGeomatch, ValidityPeriod: $ValidityPeriod, SynchronousValidation: $SynchronousValidation, Usecase: $Usecase, UseInboundWebhookOnNumber: $UseInboundWebhookOnNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services
#
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
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<services: table<sid: string, account_sid: string, friendly_name: string, date_created: string, date_updated: string, inbound_request_url: string, inbound_method: string, fallback_url: string, fallback_method: string, status_callback: string, sticky_sender: bool, mms_converter: bool, smart_encoding: bool, scan_message_content: string, fallback_to_long_code: bool, area_code_geomatch: bool, synchronous_validation: bool, validity_period: int, url: string, links: record, usecase: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{Sid}
#
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
  --FriendlyName: string # A descriptive string that you create to describe the resource. It can be up to 64 characters long.
  --InboundRequestUrl: string # The URL we call using `inbound_method` when a message is received by any phone number or short code in the Service. When this property is `null`, receiving inbound messages is disabled. All messages sent to the Twilio phone number or short code will not be logged and received on the Account. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `inbound_request_url` defined for the Messaging Service. (format: uri)
  --InboundMethod: string@InboundMethod-completer # The HTTP method we should use to call `inbound_request_url`. Can be `GET` or `POST` and the default is `POST`. (format: http-method)
  --FallbackUrl: string # The URL that we call using `fallback_method` if an error occurs while retrieving or executing the TwiML from the Inbound Request URL. If the `use_inbound_webhook_on_number` field is enabled then the webhook url defined on the phone number will override the `fallback_url` defined for the Messaging Service. (format: uri)
  --FallbackMethod: string@FallbackMethod-completer # The HTTP method we should use to call `fallback_url`. Can be: `GET` or `POST`. (format: http-method)
  --StatusCallback: string # The URL we should call to [pass status updates](https://www.twilio.com/docs/sms/api/message-resource#message-status-values) about message delivery. (format: uri)
  --StickySender: oneof<nothing, bool> # Whether to enable [Sticky Sender](https://www.twilio.com/docs/messaging/services#sticky-sender) on the Service instance.
  --MmsConverter: oneof<nothing, bool> # Whether to enable the [MMS Converter](https://www.twilio.com/docs/messaging/services#mms-converter) for messages sent through the Service instance.
  --SmartEncoding: oneof<nothing, bool> # Whether to enable [Smart Encoding](https://www.twilio.com/docs/messaging/services#smart-encoding) for messages sent through the Service instance.
  --ScanMessageContent: string@ScanMessageContent-completer # Reserved.
  --FallbackToLongCode: oneof<nothing, bool> # [OBSOLETE] Former feature used to fallback to long code sender after certain short code message failures.
  --AreaCodeGeomatch: oneof<nothing, bool> # Whether to enable [Area Code Geomatch](https://www.twilio.com/docs/messaging/services#area-code-geomatch) on the Service Instance.
  --ValidityPeriod: int # How long, in seconds, messages sent from the Service are valid. Can be an integer from `1` to `36,000`. Default value is `36,000`.
  --SynchronousValidation: oneof<nothing, bool> # Reserved.
  --Usecase: string # A string that describes the scenario in which the Messaging Service will be used. Possible values are `notifications`, `marketing`, `verification`, `discussion`, `poll`, `undeclared`.
  --UseInboundWebhookOnNumber: oneof<nothing, bool> # A boolean value that indicates either the webhook url configured on the phone number will be used or `inbound_request_url`/`fallback_url` url will be called when a message is received from the phone number. If this field is enabled then the webhook url defined on the phone number will override the `inbound_request_url`/`fallback_url` defined for the Messaging Service.
]: any -> record<sid: string, account_sid: string, friendly_name: string, date_created: string, date_updated: string, inbound_request_url: string, inbound_method: string, fallback_url: string, fallback_method: string, status_callback: string, sticky_sender: bool, mms_converter: bool, smart_encoding: bool, scan_message_content: string, fallback_to_long_code: bool, area_code_geomatch: bool, synchronous_validation: bool, validity_period: int, url: string, links: record, usecase: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let body = {FriendlyName: $FriendlyName, InboundRequestUrl: $InboundRequestUrl, InboundMethod: $InboundMethod, FallbackUrl: $FallbackUrl, FallbackMethod: $FallbackMethod, StatusCallback: $StatusCallback, StickySender: $StickySender, MmsConverter: $MmsConverter, SmartEncoding: $SmartEncoding, ScanMessageContent: $ScanMessageContent, FallbackToLongCode: $FallbackToLongCode, AreaCodeGeomatch: $AreaCodeGeomatch, ValidityPeriod: $ValidityPeriod, SynchronousValidation: $SynchronousValidation, Usecase: $Usecase, UseInboundWebhookOnNumber: $UseInboundWebhookOnNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{Sid}
#
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
]: nothing -> record<sid: string, account_sid: string, friendly_name: string, date_created: string, date_updated: string, inbound_request_url: string, inbound_method: string, fallback_url: string, fallback_method: string, status_callback: string, sticky_sender: bool, mms_converter: bool, smart_encoding: bool, scan_message_content: string, fallback_to_long_code: bool, area_code_geomatch: bool, synchronous_validation: bool, validity_period: int, url: string, links: record, usecase: string, us_app_to_person_registered: bool, use_inbound_webhook_on_number: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{Sid}
#
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{ServiceSid}/ShortCodes
#
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
  ShortCodeSid: string # The SID of the ShortCode resource being added to the Service.
]: any -> record<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, short_code: string, country_code: string, capabilities: list<string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes")
  let body = {ShortCodeSid: $ShortCodeSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{ServiceSid}/ShortCodes
#
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
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<short_codes: table<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, short_code: string, country_code: string, capabilities: list, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{ServiceSid}/ShortCodes/{Sid}
#
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{ServiceSid}/ShortCodes/{Sid}
#
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
]: nothing -> record<sid: string, account_sid: string, service_sid: string, date_created: string, date_updated: string, short_code: string, country_code: string, capabilities: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ServiceSid)/ShortCodes/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a tollfree verification
#
# GET /v1/Tollfree/Verifications/{Sid}
# operationId: FetchTollfreeVerification
export def "tollfree-verifications FetchTollfreeVerification" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sid: string, account_sid: string, customer_profile_sid: string, trust_product_sid: string, date_created: string, date_updated: string, regulated_item_sid: string, business_name: string, business_street_address: string, business_street_address2: string, business_city: string, business_state_province_region: string, business_postal_code: string, business_country: string, business_website: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_email: string, business_contact_phone: string, notification_email: string, use_case_categories: list<string>, use_case_summary: string, production_message_sample: string, opt_in_image_urls: list<string>, opt_in_type: string, message_volume: string, additional_information: string, tollfree_phone_number_sid: string, tollfree_phone_number: string, status: string, url: string, rejection_reason: string, error_code: int, edit_expiration: string, edit_allowed: bool, business_registration_number: string, business_registration_authority: string, business_registration_country: string, business_type: string, business_registration_phone_number: string, doing_business_as: string, opt_in_confirmation_message: string, help_message_sample: string, privacy_policy_url: string, terms_and_conditions_url: string, age_gated_content: bool, opt_in_keywords: list<string>, rejection_reasons: list<any>, resource_links: any, external_reference_id: string, vetting_id: string, vetting_provider: string, vetting_id_expiration: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Tollfree/Verifications/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit a tollfree verification
#
# POST /v1/Tollfree/Verifications/{Sid}
# operationId: UpdateTollfreeVerification
export def "tollfree-verifications UpdateTollfreeVerification" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BusinessName: string # The name of the business or organization using the Tollfree number.
  --BusinessWebsite: string # The website of the business or organization using the Tollfree number.
  --NotificationEmail: string # The email address to receive the notification about the verification result. .
  --UseCaseCategories: list # The category of the use case for the Tollfree Number. List as many as are applicable. (nullable)
  --UseCaseSummary: string # Use this to further explain how messaging is used by the business or organization.
  --ProductionMessageSample: string # An example of message content, i.e. a sample message.
  --OptInImageUrls: list # Link to an image that shows the opt-in workflow. Multiple images allowed and must be a publicly hosted URL.
  --OptInType: string@OptInType-completer # Describe how a user opts-in to text messages.
  --MessageVolume: string # Estimate monthly volume of messages from the Tollfree Number.
  --BusinessStreetAddress: string # The address of the business or organization using the Tollfree number.
  --BusinessStreetAddress2: string # The address of the business or organization using the Tollfree number.
  --BusinessCity: string # The city of the business or organization using the Tollfree number.
  --BusinessStateProvinceRegion: string # The state/province/region of the business or organization using the Tollfree number.
  --BusinessPostalCode: string # The postal code of the business or organization using the Tollfree number.
  --BusinessCountry: string # The country of the business or organization using the Tollfree number.
  --AdditionalInformation: string # Additional information to be provided for verification.
  --BusinessContactFirstName: string # The first name of the contact for the business or organization using the Tollfree number.
  --BusinessContactLastName: string # The last name of the contact for the business or organization using the Tollfree number.
  --BusinessContactEmail: string # The email address of the contact for the business or organization using the Tollfree number.
  --BusinessContactPhone: string # The E.164 formatted phone number of the contact for the business or organization using the Tollfree number. (format: phone-number)
  --EditReason: string # Describe why the verification is being edited. If the verification was rejected because of a technical issue, such as the website being down, and the issue has been resolved this parameter should be set to something similar to 'Website fixed'.
  --BusinessRegistrationNumber: string # A legally recognized business registration number
  --BusinessRegistrationAuthority: string@BusinessRegistrationAuthority-completer # The organizational authority for business registrations. Required for all business types except SOLE_PROPRIETOR. (nullable)
  --BusinessRegistrationCountry: string # Country business is registered in
  --BusinessType: string@BusinessType-completer # The type of business, valid values are PRIVATE_PROFIT, PUBLIC_PROFIT, NON_PROFIT, SOLE_PROPRIETOR, GOVERNMENT. Required field. (nullable)
  --BusinessRegistrationPhoneNumber: string # The E.164 formatted number associated with the business.
  --DoingBusinessAs: string # Trade name, sub entity, or downstream business name of business being submitted for verification
  --OptInConfirmationMessage: string # The confirmation message sent to users when they opt in to receive messages.
  --HelpMessageSample: string # A sample help message provided to users.
  --PrivacyPolicyUrl: string # The URL to the privacy policy for the business or organization.
  --TermsAndConditionsUrl: string # The URL to the terms and conditions for the business or organization.
  --AgeGatedContent: oneof<nothing, bool> # Indicates if the content is age gated.
  --OptInKeywords: list # List of keywords that users can text in to opt in to receive messages.
  --VettingProvider: string@VettingProvider-completer-1 # The third-party political vetting provider. (nullable)
  --VettingId: string # The unique ID of the vetting
]: any -> record<sid: string, account_sid: string, customer_profile_sid: string, trust_product_sid: string, date_created: string, date_updated: string, regulated_item_sid: string, business_name: string, business_street_address: string, business_street_address2: string, business_city: string, business_state_province_region: string, business_postal_code: string, business_country: string, business_website: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_email: string, business_contact_phone: string, notification_email: string, use_case_categories: list<string>, use_case_summary: string, production_message_sample: string, opt_in_image_urls: list<string>, opt_in_type: string, message_volume: string, additional_information: string, tollfree_phone_number_sid: string, tollfree_phone_number: string, status: string, url: string, rejection_reason: string, error_code: int, edit_expiration: string, edit_allowed: bool, business_registration_number: string, business_registration_authority: string, business_registration_country: string, business_type: string, business_registration_phone_number: string, doing_business_as: string, opt_in_confirmation_message: string, help_message_sample: string, privacy_policy_url: string, terms_and_conditions_url: string, age_gated_content: bool, opt_in_keywords: list<string>, rejection_reasons: list<any>, resource_links: any, external_reference_id: string, vetting_id: string, vetting_provider: string, vetting_id_expiration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Tollfree/Verifications/($Sid)")
  let body = {BusinessName: $BusinessName, BusinessWebsite: $BusinessWebsite, NotificationEmail: $NotificationEmail, UseCaseCategories: $UseCaseCategories, UseCaseSummary: $UseCaseSummary, ProductionMessageSample: $ProductionMessageSample, OptInImageUrls: $OptInImageUrls, OptInType: $OptInType, MessageVolume: $MessageVolume, BusinessStreetAddress: $BusinessStreetAddress, BusinessStreetAddress2: $BusinessStreetAddress2, BusinessCity: $BusinessCity, BusinessStateProvinceRegion: $BusinessStateProvinceRegion, BusinessPostalCode: $BusinessPostalCode, BusinessCountry: $BusinessCountry, AdditionalInformation: $AdditionalInformation, BusinessContactFirstName: $BusinessContactFirstName, BusinessContactLastName: $BusinessContactLastName, BusinessContactEmail: $BusinessContactEmail, BusinessContactPhone: $BusinessContactPhone, EditReason: $EditReason, BusinessRegistrationNumber: $BusinessRegistrationNumber, BusinessRegistrationAuthority: $BusinessRegistrationAuthority, BusinessRegistrationCountry: $BusinessRegistrationCountry, BusinessType: $BusinessType, BusinessRegistrationPhoneNumber: $BusinessRegistrationPhoneNumber, DoingBusinessAs: $DoingBusinessAs, OptInConfirmationMessage: $OptInConfirmationMessage, HelpMessageSample: $HelpMessageSample, PrivacyPolicyUrl: $PrivacyPolicyUrl, TermsAndConditionsUrl: $TermsAndConditionsUrl, AgeGatedContent: $AgeGatedContent, OptInKeywords: $OptInKeywords, VettingProvider: $VettingProvider, VettingId: $VettingId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a tollfree verification
#
# DELETE /v1/Tollfree/Verifications/{Sid}
# operationId: DeleteTollfreeVerification
export def "tollfree-verifications DeleteTollfreeVerification" [
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Tollfree/Verifications/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List tollfree verifications
#
# GET /v1/Tollfree/Verifications
# operationId: ListTollfreeVerification
export def "tollfree-verifications ListTollfreeVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --TollfreePhoneNumberSid: string # The SID of the Phone Number associated with the Tollfree Verification.
  --Status: string@Status-completer # The compliance status of the Tollfree Verification record.
  --ExternalReferenceId: string # Customer supplied reference id for the Tollfree Verification record.
  --IncludeSubAccounts: oneof<nothing, bool> # Whether to include Tollfree Verifications from sub accounts in list response.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --TrustProductSid: list # The trust product sids / tollfree bundle sids of tollfree verifications
]: nothing -> record<verifications: table<sid: string, account_sid: string, customer_profile_sid: string, trust_product_sid: string, date_created: string, date_updated: string, regulated_item_sid: string, business_name: string, business_street_address: string, business_street_address2: string, business_city: string, business_state_province_region: string, business_postal_code: string, business_country: string, business_website: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_email: string, business_contact_phone: string, notification_email: string, use_case_categories: list, use_case_summary: string, production_message_sample: string, opt_in_image_urls: list, opt_in_type: string, message_volume: string, additional_information: string, tollfree_phone_number_sid: string, tollfree_phone_number: string, status: string, url: string, rejection_reason: string, error_code: int, edit_expiration: string, edit_allowed: bool, business_registration_number: string, business_registration_authority: string, business_registration_country: string, business_type: string, business_registration_phone_number: string, doing_business_as: string, opt_in_confirmation_message: string, help_message_sample: string, privacy_policy_url: string, terms_and_conditions_url: string, age_gated_content: bool, opt_in_keywords: list, rejection_reasons: list, resource_links: any, external_reference_id: string, vetting_id: string, vetting_provider: string, vetting_id_expiration: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "TollfreePhoneNumberSid" $TollfreePhoneNumberSid "scalar") (serialize-qp "Status" $Status "scalar") (serialize-qp "ExternalReferenceId" $ExternalReferenceId "scalar") (serialize-qp "IncludeSubAccounts" $IncludeSubAccounts "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar") (serialize-qp "TrustProductSid" $TrustProductSid "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Tollfree/Verifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tollfree verification
#
# POST /v1/Tollfree/Verifications
# operationId: CreateTollfreeVerification
export def "tollfree-verifications CreateTollfreeVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  BusinessName: string # The name of the business or organization using the Tollfree number.
  BusinessWebsite: string # The website of the business or organization using the Tollfree number.
  NotificationEmail: string # The email address to receive the notification about the verification result. .
  --UseCaseCategories: list # The category of the use case for the Tollfree Number. List as many as are applicable. (nullable)
  UseCaseSummary: string # Use this to further explain how messaging is used by the business or organization.
  ProductionMessageSample: string # An example of message content, i.e. a sample message.
  OptInImageUrls: list # Link to an image that shows the opt-in workflow. Multiple images allowed and must be a publicly hosted URL.
  OptInType: string@OptInType-completer # Describe how a user opts-in to text messages.
  MessageVolume: string # Estimate monthly volume of messages from the Tollfree Number.
  TollfreePhoneNumberSid: string # The SID of the Phone Number associated with the Tollfree Verification.
  --CustomerProfileSid: string # Customer's Profile Bundle BundleSid.
  --BusinessStreetAddress: string # The address of the business or organization using the Tollfree number.
  --BusinessStreetAddress2: string # The address of the business or organization using the Tollfree number.
  --BusinessCity: string # The city of the business or organization using the Tollfree number.
  --BusinessStateProvinceRegion: string # The state/province/region of the business or organization using the Tollfree number.
  --BusinessPostalCode: string # The postal code of the business or organization using the Tollfree number.
  --BusinessCountry: string # The country of the business or organization using the Tollfree number.
  --AdditionalInformation: string # Additional information to be provided for verification.
  --BusinessContactFirstName: string # The first name of the contact for the business or organization using the Tollfree number.
  --BusinessContactLastName: string # The last name of the contact for the business or organization using the Tollfree number.
  --BusinessContactEmail: string # The email address of the contact for the business or organization using the Tollfree number.
  --BusinessContactPhone: string # The E.164 formatted phone number of the contact for the business or organization using the Tollfree number. (format: phone-number)
  --ExternalReferenceId: string # An optional external reference ID supplied by customer and echoed back on status retrieval.
  --BusinessRegistrationNumber: string # A legally recognized business registration number. Required for all business types except SOLE_PROPRIETOR.
  --BusinessRegistrationAuthority: string@BusinessRegistrationAuthority-completer # The organizational authority for business registrations. Required for all business types except SOLE_PROPRIETOR. (nullable)
  --BusinessRegistrationCountry: string # The country where the business is registered. Required for all business types except SOLE_PROPRIETOR.
  --BusinessType: string@BusinessType-completer # The type of business, valid values are PRIVATE_PROFIT, PUBLIC_PROFIT, NON_PROFIT, SOLE_PROPRIETOR, GOVERNMENT. Required field. (nullable)
  --BusinessRegistrationPhoneNumber: string # The E.164 formatted number associated with the business.
  --DoingBusinessAs: string # Trade name, sub entity, or downstream business name of business being submitted for verification
  --OptInConfirmationMessage: string # The confirmation message sent to users when they opt in to receive messages.
  --HelpMessageSample: string # A sample help message provided to users.
  --PrivacyPolicyUrl: string # The URL to the privacy policy for the business or organization.
  --TermsAndConditionsUrl: string # The URL to the terms and conditions for the business or organization.
  --AgeGatedContent: oneof<nothing, bool> # Indicates if the content is age gated.
  --OptInKeywords: list # List of keywords that users can text in to opt in to receive messages.
  --VettingProvider: string@VettingProvider-completer-1 # The third-party political vetting provider. (nullable)
  --VettingId: string # The unique ID of the vetting
]: any -> record<sid: string, account_sid: string, customer_profile_sid: string, trust_product_sid: string, date_created: string, date_updated: string, regulated_item_sid: string, business_name: string, business_street_address: string, business_street_address2: string, business_city: string, business_state_province_region: string, business_postal_code: string, business_country: string, business_website: string, business_contact_first_name: string, business_contact_last_name: string, business_contact_email: string, business_contact_phone: string, notification_email: string, use_case_categories: list<string>, use_case_summary: string, production_message_sample: string, opt_in_image_urls: list<string>, opt_in_type: string, message_volume: string, additional_information: string, tollfree_phone_number_sid: string, tollfree_phone_number: string, status: string, url: string, rejection_reason: string, error_code: int, edit_expiration: string, edit_allowed: bool, business_registration_number: string, business_registration_authority: string, business_registration_country: string, business_type: string, business_registration_phone_number: string, doing_business_as: string, opt_in_confirmation_message: string, help_message_sample: string, privacy_policy_url: string, terms_and_conditions_url: string, age_gated_content: bool, opt_in_keywords: list<string>, rejection_reasons: list<any>, resource_links: any, external_reference_id: string, vetting_id: string, vetting_provider: string, vetting_id_expiration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Tollfree/Verifications")
  let body = {BusinessName: $BusinessName, BusinessWebsite: $BusinessWebsite, NotificationEmail: $NotificationEmail, UseCaseCategories: $UseCaseCategories, UseCaseSummary: $UseCaseSummary, ProductionMessageSample: $ProductionMessageSample, OptInImageUrls: $OptInImageUrls, OptInType: $OptInType, MessageVolume: $MessageVolume, TollfreePhoneNumberSid: $TollfreePhoneNumberSid, CustomerProfileSid: $CustomerProfileSid, BusinessStreetAddress: $BusinessStreetAddress, BusinessStreetAddress2: $BusinessStreetAddress2, BusinessCity: $BusinessCity, BusinessStateProvinceRegion: $BusinessStateProvinceRegion, BusinessPostalCode: $BusinessPostalCode, BusinessCountry: $BusinessCountry, AdditionalInformation: $AdditionalInformation, BusinessContactFirstName: $BusinessContactFirstName, BusinessContactLastName: $BusinessContactLastName, BusinessContactEmail: $BusinessContactEmail, BusinessContactPhone: $BusinessContactPhone, ExternalReferenceId: $ExternalReferenceId, BusinessRegistrationNumber: $BusinessRegistrationNumber, BusinessRegistrationAuthority: $BusinessRegistrationAuthority, BusinessRegistrationCountry: $BusinessRegistrationCountry, BusinessType: $BusinessType, BusinessRegistrationPhoneNumber: $BusinessRegistrationPhoneNumber, DoingBusinessAs: $DoingBusinessAs, OptInConfirmationMessage: $OptInConfirmationMessage, HelpMessageSample: $HelpMessageSample, PrivacyPolicyUrl: $PrivacyPolicyUrl, TermsAndConditionsUrl: $TermsAndConditionsUrl, AgeGatedContent: $AgeGatedContent, OptInKeywords: $OptInKeywords, VettingProvider: $VettingProvider, VettingId: $VettingId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# POST /v1/Services/{MessagingServiceSid}/Compliance/Usa2p
#
# operationId: CreateUsAppToPerson
export def "services-compliance-usa2p CreateUsAppToPerson" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Twilio-Api-Version: string # The version of the Messaging API to use for this request
  BrandRegistrationSid: string # A2P Brand Registration SID
  Description: string # A short description of what this SMS campaign does. Min length: 40 characters. Max length: 4096 characters.
  MessageFlow: string # Required for all Campaigns. Details around how a consumer opts-in to their campaign, therefore giving consent to receive their messages. If multiple opt-in methods can be used for the same campaign, they must all be listed. 40 character minimum. 2048 character maximum.
  MessageSamples: list # An array of sample message strings, min two and max five. Min length for each sample: 20 chars. Max length for each sample: 1024 chars.
  UsAppToPersonUsecase: string # A2P Campaign Use Case. Examples: [ 2FA, EMERGENCY, MARKETING..]
  --HasEmbeddedLinks: oneof<nothing, bool> # Indicates that this SMS campaign will send messages that contain links.
  --HasEmbeddedPhone: oneof<nothing, bool> # Indicates that this SMS campaign will send messages that contain phone numbers.
  --OptInMessage: string # If end users can text in a keyword to start receiving messages from this campaign, the auto-reply messages sent to the end users must be provided. The opt-in response should include the Brand name, confirmation of opt-in enrollment to a recurring message campaign, how to get help, and clear description of how to opt-out. This field is required if end users can text in a keyword to start receiving messages from this campaign. 20 character minimum. 320 character maximum.
  --OptOutMessage: string # Upon receiving the opt-out keywords from the end users, Twilio customers are expected to send back an auto-generated response, which must provide acknowledgment of the opt-out request and confirmation that no further messages will be sent. It is also recommended that these opt-out messages include the brand name. This field is required if managing opt out keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). 20 character minimum. 320 character maximum.
  --HelpMessage: string # When customers receive the help keywords from their end users, Twilio customers are expected to send back an auto-generated response; this may include the brand name and additional support contact information. This field is required if managing help keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). 20 character minimum. 320 character maximum.
  --OptInKeywords: list # If end users can text in a keyword to start receiving messages from this campaign, those keywords must be provided. This field is required if end users can text in a keyword to start receiving messages from this campaign. Values must be alphanumeric. 255 character maximum.
  --OptOutKeywords: list # End users should be able to text in a keyword to stop receiving messages from this campaign. Those keywords must be provided. This field is required if managing opt out keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). Values must be alphanumeric. 255 character maximum.
  --HelpKeywords: list # End users should be able to text in a keyword to receive help. Those keywords must be provided as part of the campaign registration request. This field is required if managing help keywords yourself (i.e. not using Twilio's Default or Advanced Opt Out features). Values must be alphanumeric. 255 character maximum.
  --SubscriberOptIn: oneof<nothing, bool> # A boolean that specifies whether campaign has Subscriber Optin or not.
  --AgeGated: oneof<nothing, bool> # A boolean that specifies whether campaign is age gated or not.
  --DirectLending: oneof<nothing, bool> # A boolean that specifies whether campaign allows direct lending or not.
  --PrivacyPolicyUrl: string # The URL of the privacy policy for the campaign. (format: uri)
  --TermsAndConditionsUrl: string # The URL of the terms and conditions for the campaign. (format: uri)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p")
  let body = {BrandRegistrationSid: $BrandRegistrationSid, Description: $Description, MessageFlow: $MessageFlow, MessageSamples: $MessageSamples, UsAppToPersonUsecase: $UsAppToPersonUsecase, HasEmbeddedLinks: $HasEmbeddedLinks, HasEmbeddedPhone: $HasEmbeddedPhone, OptInMessage: $OptInMessage, OptOutMessage: $OptOutMessage, HelpMessage: $HelpMessage, OptInKeywords: $OptInKeywords, OptOutKeywords: $OptOutKeywords, HelpKeywords: $HelpKeywords, SubscriberOptIn: $SubscriberOptIn, AgeGated: $AgeGated, DirectLending: $DirectLending, PrivacyPolicyUrl: $PrivacyPolicyUrl, TermsAndConditionsUrl: $TermsAndConditionsUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Api-Version": $X_Twilio_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p
#
# operationId: ListUsAppToPerson
export def "services-compliance-usa2p ListUsAppToPerson" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 1000. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
  --X-Twilio-Api-Version: string # The version of the Messaging API to use for this request
]: nothing -> record<compliance: list<any>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p" $qp)
  let extra_headers = {"X-Twilio-Api-Version": $X_Twilio_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# DELETE /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# operationId: DeleteUsAppToPerson
export def "services-compliance-usa2p DeleteUsAppToPerson" [
  MessagingServiceSid: string
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
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# operationId: FetchUsAppToPerson
export def "services-compliance-usa2p FetchUsAppToPerson" [
  MessagingServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Twilio-Api-Version: string # The version of the Messaging API to use for this request
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p/($Sid)")
  let extra_headers = {"X-Twilio-Api-Version": $X_Twilio_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/{Sid}
#
# operationId: UpdateUsAppToPerson
export def "services-compliance-usa2p UpdateUsAppToPerson" [
  MessagingServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Twilio-Api-Version: string # The version of the Messaging API to use for this request
  --HasEmbeddedLinks: oneof<nothing, bool> # Indicates that this SMS campaign will send messages that contain links.
  --HasEmbeddedPhone: oneof<nothing, bool> # Indicates that this SMS campaign will send messages that contain phone numbers.
  MessageSamples: list # An array of sample message strings, min two and max five. Min length for each sample: 20 chars. Max length for each sample: 1024 chars.
  MessageFlow: string # Required for all Campaigns. Details around how a consumer opts-in to their campaign, therefore giving consent to receive their messages. If multiple opt-in methods can be used for the same campaign, they must all be listed. 40 character minimum. 2048 character maximum.
  Description: string # A short description of what this SMS campaign does. Min length: 40 characters. Max length: 4096 characters.
  --AgeGated: oneof<nothing, bool> # A boolean that specifies whether campaign requires age gate for federally legal content.
  --DirectLending: oneof<nothing, bool> # A boolean that specifies whether campaign allows direct lending or not.
  --PrivacyPolicyUrl: string # The URL of the privacy policy for the campaign. (format: uri)
  --TermsAndConditionsUrl: string # The URL of the terms and conditions for the campaign. (format: uri)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p/($Sid)")
  let body = {HasEmbeddedLinks: $HasEmbeddedLinks, HasEmbeddedPhone: $HasEmbeddedPhone, MessageSamples: $MessageSamples, MessageFlow: $MessageFlow, Description: $Description, AgeGated: $AgeGated, DirectLending: $DirectLending, PrivacyPolicyUrl: $PrivacyPolicyUrl, TermsAndConditionsUrl: $TermsAndConditionsUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Api-Version": $X_Twilio_Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# GET /v1/Services/{MessagingServiceSid}/Compliance/Usa2p/Usecases
#
# operationId: FetchUsAppToPersonUsecase
export def "services-compliance-usa2p-usecases FetchUsAppToPersonUsecase" [
  MessagingServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --BrandRegistrationSid: string # The unique string to identify the A2P brand.
]: nothing -> record<us_app_to_person_usecases: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let qp = [(serialize-qp "BrandRegistrationSid" $BrandRegistrationSid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($MessagingServiceSid)/Compliance/Usa2p/Usecases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /v1/Services/Usecases
#
# operationId: FetchUsecase
export def "services-usecases FetchUsecase" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<usecases: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://messaging.twilio.com")
  let full_url = (build-url $base "/v1/Services/Usecases")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
