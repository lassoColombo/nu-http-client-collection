# Auto-generated client for Obligations (MTD) v3.0
# Source: https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/obligations-api/3.0/oas/resolved
# Auth: --token flag or $env.OBLIGATIONS_MTD_TOKEN

const BASE_URL = "https://test-api.service.hmrc.gov.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OBLIGATIONS_MTD_TOKEN | default "" }
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

def base-url-completer [] { ["https://test-api.service.hmrc.gov.uk" "https://api.service.hmrc.gov.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def typeOfBusiness-completer [] { ["foreign-property" "self-employment" "uk-property"] }
def Accept-completer [] { ["application/vnd.hmrc.3.0+json"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "obligations-details-income-and-expenditure get" } } | get name | first)
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

# Retrieve Income Tax (Self Assessment) Income and Expenditure Obligations
#
# GET /obligations/details/{nino}/income-and-expenditure
export def "obligations-details-income-and-expenditure get" [
  nino: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --typeOfBusiness: string@typeOfBusiness-completer # The type of business whose obligations are to be returned. If the type is not specified the default is to return obligations for all businesses. The type must be provided if "businessId" is provided.  (e.g. self-employment)
  --businessId: string # The unique identifier for the business whose obligations are to be returned.  (e.g. XAIS12345678901)
  --fromDate: string # The start date of the range to filter obligations in the format YYYY-MM-DD. Mandatory if the “to” query parameter is supplied. If the “from” and “to” date parameters are not supplied, the date range will default to a year from today unless the status parameter is set to "open". The toDate & fromDate can be a maximum of 366 days apart.  (e.g. 2018-04-06)
  --toDate: string # The end date of the range to filter obligations in the format YYYY-MM-DD. Mandatory if the “from” query parameter is supplied. If the “from” and “to” date parameters are not supplied, the date range will default to a year from today unless the status parameter is set to "open". The toDate & fromDate can be a maximum of 366 days apart.  (e.g. 2019-04-05)
  --status: string # Status of the obligations to return.  Accepted values are ‘open’ and ‘fulfilled’. If no status is supplied, both open and fulfilled obligations are returned.  (e.g. open)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> record<obligations: table<typeOfBusiness: string, businessId: string, obligationDetails: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeOfBusiness" $typeOfBusiness "scalar") (serialize-qp "businessId" $businessId "scalar") (serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/obligations/details/($nino)/income-and-expenditure" $qp)
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Income Tax (Self Assessment) Final Declaration Obligations
#
# GET /obligations/details/{nino}/crystallisation
export def "obligations-details-crystallisation get" [
  nino: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taxYear: string # The tax year the data applies to.  If a tax year is not specified, returns all obligations starting from 4 years before the current tax year.  For example, if current tax year is 2023-24 and no tax year is specified, all obligations from 2019-20 to 2023-24 are returned.  The earliest allowable tax year is 2017-18.  (e.g. 2022-23)
  --status: string # Status of the obligations to return.  Accepted values are ‘open’ and ‘fulfilled’. If no status is supplied, both open and fulfilled obligations are returned.  (e.g. open)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> record<obligations: table<periodStartDate: string, periodEndDate: string, dueDate: string, status: string, receivedDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taxYear" $taxYear "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/obligations/details/($nino)/crystallisation" $qp)
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
