# Auto-generated client for Property Business (MTD) v6.0
# Source: https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/property-business-api/6.0/oas/resolved
# Auth: --token flag or $env.PROPERTY_BUSINESS_MTD_TOKEN

const BASE_URL = "https://test-api.service.hmrc.gov.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PROPERTY_BUSINESS_MTD_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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
def base-url-completer [] { ["https://test-api.service.hmrc.gov.uk" "https://api.service.hmrc.gov.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Accept-completer [] { ["application/vnd.hmrc.6.0+json"] }
def Content-Type-completer [] { ["application/json"] }
def endReason-completer [] { ["added-in-error" "disposal" "no-longer-renting-property-out"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "individuals-business-property-uk-annual get" } } | get name | first)
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

# GET /individuals/business/property/uk/{nino}/{businessId}/annual/{taxYear}
export def "individuals-business-property-uk-annual get" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/($nino)/($businessId)/annual/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/uk/{nino}/{businessId}/annual/{taxYear}
export def "individuals-business-property-uk-annual put" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/($nino)/($businessId)/annual/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a UK Property Income & Expenses Period Summary
#
# POST /individuals/business/property/uk/{nino}/{businessId}/period/{taxYear}
# --ukFhlProperty shape: {income?: record, expenses?: record}
# --ukNonFhlProperty shape: {income?: record, expenses?: record}
export def "individuals-business-property-uk-period post" [
  nino: string
  businessId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
  --fromDate: string # The first day that the income and expenses period summary covers. Must conform to the format YYYY-MM-DD (Our systems only accept dates between 1900-01-01 and 2100-01-01) (e.g. 2020-01-01)
  --toDate: string # The last day that the income and expenses period summary covers. Must conform to the format YYYY-MM-DD (Our systems only accept dates between 1900-01-01 and 2100-01-01) (e.g. 2020-01-31)
  --ukFhlProperty: record # Object  holding the income and expenses of the UK property business. (At least one of income or expenses should be present) — shape: {income?: record, expenses?: record}
  --ukNonFhlProperty: record # Object  holding the income and expenses of the UK property business - excluding Furnished Holiday Lettings (FHL) for the period. (At least one of income or expenses should be present) — shape: {income?: record, expenses?: record}
]: any -> record<submissionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/($nino)/($businessId)/period/($taxYear)")
  let body = {fromDate: $fromDate, toDate: $toDate, ukFhlProperty: $ukFhlProperty, ukNonFhlProperty: $ukNonFhlProperty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /individuals/business/property/uk/{nino}/{businessId}/period/{taxYear}/{submissionId}
export def "individuals-business-property-uk-period get" [
  nino: any
  businessId: any
  taxYear: any
  submissionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/($nino)/($businessId)/period/($taxYear)/($submissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/uk/{nino}/{businessId}/period/{taxYear}/{submissionId}
export def "individuals-business-property-uk-period put" [
  nino: any
  businessId: any
  taxYear: any
  submissionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/($nino)/($businessId)/period/($taxYear)/($submissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/uk/{nino}/{businessId}/cumulative/{taxYear}
export def "individuals-business-property-uk-cumulative get" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/($nino)/($businessId)/cumulative/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/uk/{nino}/{businessId}/cumulative/{taxYear}
export def "individuals-business-property-uk-cumulative put" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/($nino)/($businessId)/cumulative/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/uk/annual/furnished-holiday-lettings/{nino}/{taxYear}
export def "individuals-business-property-uk-annual-furnished-holiday-lettings get" [
  nino: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/annual/furnished-holiday-lettings/($nino)/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/uk/annual/furnished-holiday-lettings/{nino}/{taxYear}
export def "individuals-business-property-uk-annual-furnished-holiday-lettings put" [
  nino: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/annual/furnished-holiday-lettings/($nino)/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /individuals/business/property/uk/annual/furnished-holiday-lettings/{nino}/{taxYear}
export def "individuals-business-property-uk-annual-furnished-holiday-lettings delete" [
  nino: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/annual/furnished-holiday-lettings/($nino)/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/uk/annual/non-furnished-holiday-lettings/{nino}/{taxYear}
export def "individuals-business-property-uk-annual-non-furnished-holiday-lettings get" [
  nino: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/annual/non-furnished-holiday-lettings/($nino)/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/uk/annual/non-furnished-holiday-lettings/{nino}/{taxYear}
export def "individuals-business-property-uk-annual-non-furnished-holiday-lettings put" [
  nino: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/annual/non-furnished-holiday-lettings/($nino)/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /individuals/business/property/uk/annual/non-furnished-holiday-lettings/{nino}/{taxYear}
export def "individuals-business-property-uk-annual-non-furnished-holiday-lettings delete" [
  nino: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/annual/non-furnished-holiday-lettings/($nino)/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/uk/period/furnished-holiday-lettings/{nino}
export def "individuals-business-property-uk-period-furnished-holiday-lettings list" [
  nino: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/period/furnished-holiday-lettings/($nino)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /individuals/business/property/uk/period/furnished-holiday-lettings/{nino}
export def "individuals-business-property-uk-period-furnished-holiday-lettings post" [
  nino: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/period/furnished-holiday-lettings/($nino)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/uk/period/furnished-holiday-lettings/{nino}/{periodId}
export def "individuals-business-property-uk-period-furnished-holiday-lettings get" [
  nino: any
  periodId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/period/furnished-holiday-lettings/($nino)/($periodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/uk/period/furnished-holiday-lettings/{nino}/{periodId}
export def "individuals-business-property-uk-period-furnished-holiday-lettings put" [
  nino: any
  periodId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/period/furnished-holiday-lettings/($nino)/($periodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/uk/period/non-furnished-holiday-lettings/{nino}
export def "individuals-business-property-uk-period-non-furnished-holiday-lettings list" [
  nino: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/period/non-furnished-holiday-lettings/($nino)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /individuals/business/property/uk/period/non-furnished-holiday-lettings/{nino}
export def "individuals-business-property-uk-period-non-furnished-holiday-lettings post" [
  nino: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/period/non-furnished-holiday-lettings/($nino)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/uk/period/non-furnished-holiday-lettings/{nino}/{periodId}
export def "individuals-business-property-uk-period-non-furnished-holiday-lettings get" [
  nino: any
  periodId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/period/non-furnished-holiday-lettings/($nino)/($periodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/uk/period/non-furnished-holiday-lettings/{nino}/{periodId}
export def "individuals-business-property-uk-period-non-furnished-holiday-lettings put" [
  nino: any
  periodId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/uk/period/non-furnished-holiday-lettings/($nino)/($periodId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Foreign Property Income & Expenses Period Summary
#
# POST /individuals/business/property/foreign/{nino}/{businessId}/period/{taxYear}
# --foreignFhlEea shape: {income?: record, expenses?: record}
# --foreignNonFhlProperty item shape: {countryCode: string, income: record, expenses?: record}
export def "individuals-business-property-foreign-period post" [
  nino: string
  businessId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
  --fromDate: string # The first day that the income and expenses period summary covers. Must conform to the format YYYY-MM-DD (Our systems only accept dates between 1900-01-01 and 2100-01-01) (e.g. 2020-01-01)
  --toDate: string # The last day that the income and expenses period summary covers. Must conform to the format YYYY-MM-DD (Our systems only accept dates between 1900-01-01 and 2100-01-01) (e.g. 2020-01-31)
  --foreignFhlEea: record # Object holding the income and expenses of the user's Furnished Holiday Lettings (FHL) in the European Economic Area (EEA) for the period. — shape: {income?: record, expenses?: record}
  --foreignNonFhlProperty: list # Array holding the income and expenses of the user's foreign property business - excluding Furnished Holiday Lettings (FHL) in the European Economic Area (EEA) - for the period. — item shape: {countryCode: string, income: record, expenses?: record}
]: any -> record<submissionId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/period/($taxYear)")
  let body = {fromDate: $fromDate, toDate: $toDate, foreignFhlEea: $foreignFhlEea, foreignNonFhlProperty: $foreignNonFhlProperty} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /individuals/business/property/foreign/{nino}/{businessId}/period/{taxYear}/{submissionId}
export def "individuals-business-property-foreign-period get" [
  nino: any
  businessId: any
  taxYear: any
  submissionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/period/($taxYear)/($submissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/foreign/{nino}/{businessId}/period/{taxYear}/{submissionId}
export def "individuals-business-property-foreign-period put" [
  nino: any
  businessId: any
  taxYear: any
  submissionId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/period/($taxYear)/($submissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/foreign/{nino}/{businessId}/cumulative/{taxYear}
export def "individuals-business-property-foreign-cumulative get" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/cumulative/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/foreign/{nino}/{businessId}/cumulative/{taxYear}
export def "individuals-business-property-foreign-cumulative put" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/cumulative/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/foreign/{nino}/{businessId}/annual/{taxYear}
export def "individuals-business-property-foreign-annual get" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/annual/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /individuals/business/property/foreign/{nino}/{businessId}/annual/{taxYear}
export def "individuals-business-property-foreign-annual put" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/annual/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a Property Annual Submission
#
# DELETE /individuals/business/property/{nino}/{businessId}/annual/{taxYear}
export def "individuals-business-property-annual delete" [
  nino: string
  businessId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/($nino)/($businessId)/annual/($taxYear)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Property Income and Expenses Period Summaries
#
# GET /individuals/business/property/{nino}/{businessId}/period/{taxYear}
export def "individuals-business-property-period get" [
  nino: string
  businessId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> record<submissions: table<submissionId: string, fromDate: string, toDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/($nino)/($businessId)/period/($taxYear)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /individuals/business/property/foreign/{nino}/{businessId}/details/{taxYear}
export def "individuals-business-property-foreign-details get" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/details/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /individuals/business/property/foreign/{nino}/{businessId}/details/{taxYear}
export def "individuals-business-property-foreign-details post" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/($businessId)/details/($taxYear)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Foreign Property Details
#
# PUT /individuals/business/property/foreign/{nino}/details/{propId}/{taxYear}
export def "individuals-business-property-foreign-details put" [
  nino: string
  propertyId: string
  taxYear: string
  propId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
  propertyName: string # A customer-friendly name for the foreign property. This name must be unique for each country. Uniqueness checks ignore differences in letter case and any leading or trailing spaces. Must not be empty or contain only whitespace. (e.g. Bob & Bobby Co)
  --endDate: string # The date on which income is no longer received from the property. The end date must not be later than the end of the relevant tax year. A property with an end date must always have an associated end reason.   Must conform to the format `YYYY-MM-DD` (format: date, e.g. 2026-08-24)
  --endReason: string@endReason-completer # Specifies the reason for ending the property record. A property with an end reason must always have an associated end date.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/property/foreign/($nino)/details/($propId)/($taxYear)")
  let body = {propertyName: $propertyName, endDate: $endDate, endReason: $endReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
