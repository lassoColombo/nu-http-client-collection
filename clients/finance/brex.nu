# Auto-generated client for KYC API Documentation v2021.12
# Source: https://api.apis.guru/v2/specs/brex.io/2021.12/openapi.json
# Auth: --token flag or $env.KYC_API_DOCUMENTATION_TOKEN

const BASE_URL = "https://api.kompany.com"
const DEFAULT_AUTH = "user_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KYC_API_DOCUMENTATION_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "user_key" => { {headers: {user_key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.kompany.com"] }
def auth-scheme-completer [] { ["user_key"] }

# Completers for enum parameters
def lang-completer [] { ["" "EN" "OG"] }
def lang-completer-1 [] { ["" "EN" "ES" "FR"] }
def accept-completer [] { ["application/json" "application/pdf"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "company-announcement CompanyAnnouncement" } } | get name | first)
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

# Retrieves announcement data
#
# GET /api/v1/company/announcement/{id}
# operationId: CompanyAnnouncement
export def "company-announcement CompanyAnnouncement" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<countryCode: string, id: string, registrationNumber: string, structured: string, text: string, time: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/announcement/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of stock exchange listings
#
# POST /api/v1/company/deepsearch/isin
# operationId: CompanyDeepsearchISIN
export def "company-deepsearch-isin CompanyDeepsearchISIN" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isin: string # A list of ISIN numbers seperated by comma (maximum) is 100
]: any -> table<isin: string, listings: list<record>, validIsin: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/company/deepsearch/isin")
  let body = {isin: $isin} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieves a list of companies
#
# GET /api/v1/company/deepsearch/lei/{number}
# operationId: CompanyDeepsearchLEI
export def "company-deepsearch-lei CompanyDeepsearchLEI" [
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Pagination for the ISIN number results (1000 numbers per page) (format: int32, e.g. 1)
]: nothing -> record<company: record<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string>, current_page: int, isins: list<string>, last_page: int, lei: string, next_page: string, total_num_isins: int, validLei: bool> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/company/deepsearch/lei/($number)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of companies from the official business register
#
# GET /api/v1/company/deepsearch/name/{country}/{name}
# operationId: CompanyDeepsearchName
export def "company-deepsearch-name CompanyDeepsearchName" [
  country: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/deepsearch/name/($country)/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of companies from the official business register
#
# GET /api/v1/company/deepsearch/number/{country}/{number}
# operationId: CompanyDeepsearchNumber
export def "company-deepsearch-number CompanyDeepsearchNumber" [
  country: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/deepsearch/number/($country)/($number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get available ChangeTypes
#
# GET /api/v1/company/monitoring/changeTypes
# operationId: CompanyMonitorChangeTypesList
export def "company-monitoring-change-types CompanyMonitorChangeTypesList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/company/monitoring/changeTypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of registered monitors
#
# GET /api/v1/company/monitoring/list
# operationId: CompanyMonitorList
export def "company-monitoring-list CompanyMonitorList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/company/monitoring/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get monitor status for specific company id
#
# GET /api/v1/company/monitoring/list/{id}
# operationId: CompanyMonitorId
export def "company-monitoring-list CompanyMonitorId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/monitoring/list/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Register a Company for monitoring
#
# POST /api/v1/company/monitoring/register/{id}
# operationId: CompanyMonitorRegister
export def "company-monitoring-register CompanyMonitorRegister" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  callbackUrl: string # Callback URL
  changeType: string # ChangeType to monitor
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/monitoring/register/($id)")
  let body = {callbackUrl: $callbackUrl, changeType: $changeType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Deactivates an active notification
#
# POST /api/v1/company/monitoring/unregister/{id}
# operationId: CompanyMonitorUnregister
export def "company-monitoring-unregister CompanyMonitorUnregister" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/monitoring/unregister/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of registered notifications
#
# GET /api/v1/company/notification/list
# operationId: CompanyNotificationList
export def "company-notification-list CompanyNotificationList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/company/notification/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of registered notifications
#
# GET /api/v1/company/notification/list/{id}
# operationId: CompanyNotificationId
export def "company-notification-list CompanyNotificationId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<callbackCount: int, callbackUrl: string, created: any, monitorStatus: string, notificationId: string, subjectId: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/notification/list/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new notification
#
# POST /api/v1/company/notification/register/{id}
# operationId: CompanyNotificationRegister
export def "company-notification-register CompanyNotificationRegister" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  callbackUrl: string # Callback URL
]: any -> record<monitorStatus: string, notificationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/notification/register/($id)")
  let body = {callbackUrl: $callbackUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Unregister a company from Monitoring
#
# POST /api/v1/company/notification/unregister/{id}
# operationId: CompanyNotificationUnregister
export def "company-notification-unregister CompanyNotificationUnregister" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/notification/unregister/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of companies from the KYC API company index
#
# GET /api/v1/company/search/name/{country}/{name}
# operationId: CompanySearchName
export def "company-search-name CompanySearchName" [
  country: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # number of search results (format: int64)
]: nothing -> table<address: list<string>, country: string, dateOfIncorporation: string, extraData: record, formattedAddress: list<string>, id: string, legalForm: string, managingDirectors: list<string>, name: string, registrationNumber: string, requestTime: int, secretaries: list<string>, sicNaceCodes: list<string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/company/search/name/($country)/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of companies from the KYC API company index
#
# GET /api/v1/company/search/number/{country}/{number}
# operationId: CompanySearchNumber
export def "company-search-number CompanySearchNumber" [
  country: string
  number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # number of search results (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/company/search/number/($country)/($number)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of companies from the KYC API company index
#
# POST /api/v1/company/search/{country}
# operationId: CompanyAlternativeSearch
export def "company-search CompanyAlternativeSearch" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # Company address (or address partial)
  --name: string # Company name
  --number: string # Company registration number
  --phone: string # Company contact phone number
  --body-url: string # Company url
  --vat: string # Company VAT number
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/company/search/($country)")
  let body = {address: $address, name: $name, number: $number, phone: $phone, url: $body_url, vat: $vat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieves company announcements
#
# GET /api/v1/company/{id}/announcements
# operationId: CompanyIdAnnouncements
export def "company-announcements CompanyIdAnnouncements" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # limit of announcements in response (default 10) (format: int32)
  --offset: int # to paginate through results (default 0) (format: int32)
  --data: oneof<nothing, bool> # If this parameter is set to false, you will only receive ids, and no additional data about announcements and no hits to the metric will be counted. (and potentially minimizing your costs) (format: )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "data" $data "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/company/($id)/announcements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves structured data extracted from a company document
#
# GET /api/v1/company/{id}/super/{country}
# operationId: CompanyIdSuper
export def "company-super CompanyIdSuper" [
  id: string
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lang: string@lang-completer # Optional data translation (only available in limited jurisdictions) (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/company/($id)/super/($country)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves company details
#
# GET /api/v1/company/{id}/{dataset}
# operationId: CompanyIdDataset
export def "company CompanyIdDataset" [
  id: string
  dataset: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --check-stock-listing: oneof<nothing, bool> # Try to retrieve additional stock information for this company. (Only available on refresh)
  --lang: string@lang-completer-1 # Optional data translation (only available in limited jurisdictions) (format: string)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "check_stock_listing" $check_stock_listing "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/company/($id)/($dataset)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verifies an EIN number
#
# GET /api/v1/ein-verification/basic-check
# operationId: EinVerificationBasic
export def "ein-verification-basic-check EinVerificationBasic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ein: string # Nine letter EIN number with or without hyphens (format: string)
]: nothing -> record<confidence_score: string, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, irs_score: string, irs_score_explanation: string, timestamp: float, validationStatus: bool> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ein" $ein "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/ein-verification/basic-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verifies EIN number and retrieves company data
#
# GET /api/v1/ein-verification/comprehensive-check
# operationId: EinVerificationComprehensive
export def "ein-verification-comprehensive-check EinVerificationComprehensive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ein: string # Nine letter EIN number with or without hyphens (format: string)
]: nothing -> record<ein: string, matched_ein_companies: any, timestamp: float, validationStatus: bool> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ein" $ein "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/ein-verification/comprehensive-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a list of EIN numbers
#
# GET /api/v1/ein-verification/lookup
# operationId: EinVerificationLookup
export def "ein-verification-lookup EinVerificationLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Business name of the company (format: string)
  --state: string # Optional state parameter to improve results. (Two letter code for example CA or US-CA for California) (format: string)
  --zip: string # Optional zip code parameter to improve results. (Zip is preferred over state) (format: string)
  --tight: oneof<nothing, bool> # Optional parameter to do tight matching. (Only the best match will be returned rather then the top 5)
]: nothing -> record<matched_ein_companies: table<address: list, company_score: float, company_score_explanation: string, confidence_score: float, confidence_score_explanation: string, dba_score: string, dba_score_explanation: string, ein: string, formattedAddress: list, irs_score: string, irs_score_explanation: string, name: string, provided_status: string, provided_status_explanation: string>, searchterm_name: string, searchterm_state: string, searchterm_zip: string, tight_search: bool, timestamp: float> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "zip" $zip "scalar") (serialize-qp "tight" $tight "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/ein-verification/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Checks validity of an IBAN number
#
# POST /api/v1/iban-verification/check-iban
# operationId: IbanBasic
export def "iban-verification-check-iban IbanBasic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ibanNumber: string # IBAN number to validate (e.g. AT483200000012345864)
]: any -> record<valid: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/iban-verification/check-iban")
  let body = {ibanNumber: $ibanNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Checks validity of an IBAN number
#
# POST /api/v1/iban-verification/comprehensive-check-iban
# operationId: IbanComprehensive
export def "iban-verification-comprehensive-check-iban IbanComprehensive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ibanNumber: string # IBAN number to validate (e.g. AT483200000012345864)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/iban-verification/comprehensive-check-iban")
  let body = {ibanNumber: $ibanNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Verifies a NIF number
#
# POST /api/v1/nif-verification/basic-check/{country}
# operationId: NifBasic
export def "nif-verification-basic-check NifBasic" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --companyAddress: string # company address lines
  --companyName: string # Company name
  nifNumber: string # NIF number to validate
]: any -> record<companyName: string, confidenceScore: float, nifNumber: float, validationStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/nif-verification/basic-check/($country)")
  let body = {companyAddress: $companyAddress, companyName: $companyName, nifNumber: $nifNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Verifies a NIF number and retrieves company data
#
# POST /api/v1/nif-verification/comprehensive-check/{country}
# operationId: NifComprehensive
export def "nif-verification-comprehensive-check NifComprehensive" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --companyAddress: string # company address lines
  --companyName: string # Company name
  nifNumber: string # NIF number to validate
]: any -> record<activity: record, address: string, capital: float, companyName: string, confidenceScore: float, currency: string, email: string, fax: string, geo: string, legalType: string, nifNumber: float, phone: string, status: record, validationStatus: bool, website: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/nif-verification/comprehensive-check/($country)")
  let body = {companyAddress: $companyAddress, companyName: $companyName, nifNumber: $nifNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieves a list of monitor entries
#
# GET /api/v1/pepsanction/monitor/list
# operationId: PepMonitorList
export def "pepsanction-monitor-list PepMonitorList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<active: bool, caseId: string, created: any, identifier: string, structured: string, updated: string, webhook: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/pepsanction/monitor/list")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deactive a pep sanction monitor
#
# POST /api/v1/pepsanction/monitor/unregister/{id}
# operationId: PepMonitorUnregister
export def "pepsanction-monitor-unregister PepMonitorUnregister" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pepsanction/monitor/unregister/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update details of active Pep Sanction monitor
#
# POST /api/v1/pepsanction/monitor/update/{id}
# operationId: PepMonitorUpdate
export def "pepsanction-monitor-update PepMonitorUpdate" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Webhook: string # If Monitoring is enabled this parameter is required. This is where updates will be sent to (e.g. null)
]: any -> record<active: bool, caseId: string, created: any, identifier: string, structured: string, updated: string, webhook: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pepsanction/monitor/update/($id)")
  let body = {Webhook: $Webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Orders a new Pep Sanction Check Report
#
# POST /api/v1/pepsanction/order/{type}/{search}
# operationId: PepOrder
export def "pepsanction-order PepOrder" [
  type: string
  search: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Aliases: string # Optional parameter for declaring alias names when doing a person search (seperated by commas) (e.g. null)
  --Country: string # Optional name of Country to assist in identifying matches based upon location/geography. (e.g. null)
  --DOB: string # Optional parameter for date of birth name when doing a person search (e.g. null)
  --FamilyName: string # Optional parameter for last name when doing a person search (e.g. null)
  --Filters: string # Optional parameter for restricting search when doing a person search (seperated by commas) (e.g. null)
  --GivenName: string # Optional parameter for first name when doing a person search (e.g. null)
  --LEI: string # Optional Legal Entity Identifier for additional business identifier verification. (e.g. null)
  --Locale: string # Optional name of City or Locale to assist in identifying matches based upon location/geography. (e.g. null)
  --Medialists: string # Optional parameter for selecting only specific media lists. By default all lists are queried (e.g. NMEDIA)
  --MiddleName: string # Optional parameter for middle name when doing a person search (e.g. null)
  --Monitoring: oneof<nothing, bool> # If this Pep Sanction Check should be continuesly monitored. (e.g. false)
  --Peplists: string # Optional parameter for selecting only specific pep lists. By default all lists are queried (e.g. GOV,PEPD,SOE)
  --Region: string # Optional name of Region or State to assist in identifying matches based upon location/geography. (e.g. null)
  --SmartMatch: oneof<nothing, bool> # Optional parameter for enabling SmartMatch to retrieve more results (e.g. false)
  --Watchlists: string # Optional parameter for selecting only specific watch lists. By default all lists are queried (e.g. SANCTIONS,FINANCE,TERRORISM,CRIME,SMAGOV,OFAC,MEDICAL)
  --Webhook: string # If Monitoring is enabled this parameter is required. This is where updates will be sent to (e.g. null)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pepsanction/order/($type)/($search)")
  let body = {Aliases: $Aliases, Country: $Country, DOB: $DOB, FamilyName: $FamilyName, Filters: $Filters, GivenName: $GivenName, LEI: $LEI, Locale: $Locale, Medialists: $Medialists, MiddleName: $MiddleName, Monitoring: $Monitoring, Peplists: $Peplists, Region: $Region, SmartMatch: $SmartMatch, Watchlists: $Watchlists, Webhook: $Webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns a json or pdf report
#
# GET /api/v1/pepsanction/retrieve/{id}
# operationId: PepRetrieve
export def "pepsanction-retrieve PepRetrieve" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hdr-accept: string@accept-completer # The type (pdf or json) in which the check should be returned
]: nothing -> record<listsChecked: string, results: record<Excerpts: string, ResultsURL: string, SearchType: string, SourceAgency: string, SourceEntity: string, SourceID: int, SourceName: string, SourceType: string>, search: string, status: string, timestamp: any, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/pepsanction/retrieve/($id)")
  let extra_headers = {"accept": $hdr_accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a document availability result
#
# GET /api/v1/product/availability/{sku}/{subjectId}
# operationId: ProductAvailability
export def "product-availability ProductAvailability" [
  sku: string
  subjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/availability/($sku)/($subjectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a catalog of products
#
# GET /api/v1/product/catalog/{country}
# operationId: ProductCatalog
export def "product-catalog ProductCatalog" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<countryCode: string, description: string, form: string, method: string, name: string, price: float, sku: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/catalog/($country)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata for a notifier
#
# GET /api/v1/product/notifier/{notifierId}
# operationId: ProductNotifier
export def "product-notifier ProductNotifier" [
  notifierId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/notifier/($notifierId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a notifier for an order
#
# POST /api/v1/product/notifier/{orderId}/{type}/{uri}
# operationId: ProductNotifierCreate
export def "product-notifier ProductNotifierCreate" [
  orderId: string
  type: string
  uri: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<callback: string, identity: string, lastCallTime: any, lastResponseCode: int, notifierType: string, productOrderIdentity: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/notifier/($orderId)/($type)/($uri)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Places a concierge order
#
# POST /api/v1/product/order/concierge
# operationId: ProductOrderConcierge
export def "product-order-concierge ProductOrderConcierge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --companyName: string # Name of the company for which a document should be ordered. (Not required if subjectId is given) (e.g. null)
  --contactEmail: string # Contact E-Mail, will be contacted if concierge costs are exceeding the threshhold configured on your plan (e.g. null)
  --contactPhone: string # Contact phone, will be contacted if concierge costs are exceeding the threshhold configured on your plan (e.g. null)
  --costConfirmation: oneof<nothing, bool> # If the concierge cost should require additional confirmation if a threshold is reached (configured on your plan) (e.g. false)
  --country: string # Two letter ISO code of the country of the company (e.g. null)
  --financialData: oneof<nothing, bool> # If you want financial data of the company to be retrieved (e.g. false)
  --historicInformation: oneof<nothing, bool> # If you want historical data of the company to be retrieved (e.g. false)
  --informationRequirements: string # Requirements on what document or information should be provided. Please be very precise (e.g. null)
  --locationInvestigation: oneof<nothing, bool> # If the companies residency should be investigated (e.g. false)
  --priority: string # Priority of order: standard/express are allowed (e.g. standard)
  --registerData: oneof<nothing, bool> # If you want register data of the company to be retrieved (e.g. false)
  --registerNumber: string # Registration number of the company for which a document should be ordered. (Not required if subjectId is given) (e.g. null)
  --subjectId: string # Kompanyid of the company you want to place the order for (e.g. null)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/product/order/concierge")
  let body = {companyName: $companyName, contactEmail: $contactEmail, contactPhone: $contactPhone, costConfirmation: $costConfirmation, country: $country, financialData: $financialData, historicInformation: $historicInformation, informationRequirements: $informationRequirements, locationInvestigation: $locationInvestigation, priority: $priority, registerData: $registerData, registerNumber: $registerNumber, subjectId: $subjectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Places a UBO order
#
# POST /api/v1/product/order/ubo
# operationId: ProductOrderUbo
export def "product-order-ubo ProductOrderUbo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callbackUrl: string # An optional callback URL to which updates about the order will be sent (for instance if credits are exceeded) (e.g. null)
  --credits: float # Specify a maximum amount of credits which should be used. To disable use -1 (e.g. -1)
  --includeDocs: oneof<nothing, bool> # Include purchase of register document to ubo report (e.g. false)
  --levels: string # Define a threshold for different levels of crawling (e.g. 25,50)
  --strategy: string # Choose a matching strategy. Available options (FULL,LEVELS) (e.g. FULL)
  subjectId: string # KYC API Id (32 byte hexid) of the company you want to place the order for (e.g. null)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/product/order/ubo")
  let body = {callbackUrl: $callbackUrl, credits: $credits, includeDocs: $includeDocs, levels: $levels, strategy: $strategy, subjectId: $subjectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Places a product order
#
# POST /api/v1/product/order/{sku}/{option}/{subjectId}
# operationId: ProductOrderWithOption
export def "product-order ProductOrderWithOption" [
  sku: string
  option: string
  subjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/order/($sku)/($option)/($subjectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Places a product order
#
# POST /api/v1/product/order/{sku}/{subjectId}
# operationId: ProductOrder
export def "product-order ProductOrder" [
  sku: string
  subjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identity: string, option: string, ordered: any, owner: string, price: float, sku: string, status: string, subjectId: string, subjectValue: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/order/($sku)/($subjectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of products
#
# GET /api/v1/product/search/{subjectId}
# operationId: ProductSearch
export def "product-search ProductSearch" [
  subjectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<availability: string, category: string, countryCode: string, description: string, hasOptions: bool, options: list<string>, price: float, provider: string, sku: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/search/($subjectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns metadata for a order
#
# GET /api/v1/product/status/{orderId}
# operationId: ProductStatus
export def "product-status ProductStatus" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/status/($orderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates metadata of an order
#
# POST /api/v1/product/update/{action}/{orderId}
# operationId: ProductUpdateAction
export def "product-update ProductUpdateAction" [
  action: string
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --credits: float # Specify an amount of credits which should be added to the order (e.g. 100)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/update/($action)/($orderId)")
  let body = {credits: $credits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieves the result of an order
#
# GET /api/v1/product/{orderId}
# operationId: ProductRetrieve
export def "product ProductRetrieve" [
  orderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/product/($orderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of countries
#
# GET /api/v1/system/countries
# operationId: SystemCountries
export def "system-countries SystemCountries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<country_code: string, country_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the health information for the official business registers based on usage.
#
# GET /api/v1/system/health
# operationId: HealthCheck
export def "system-health HealthCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a list of products with prices
#
# GET /api/v1/system/pricelist
# operationId: SystemPricelist
export def "system-pricelist SystemPricelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<cost_per_unit: string, max: string, metric_id: string, min: string, sku: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/system/pricelist")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verifies a TIN number
#
# GET /api/v1/tin-verification/basic-check
# operationId: TinVerificationBasicCheck
export def "tin-verification-basic-check TinVerificationBasicCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tin: string # Nine letter TIN number with or without hyphens (format: string)
  --name: string # Company Name (format: string)
]: nothing -> record<matchStatus: string, name: string, possibleMatch: string, tin: string, validationStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tin" $tin "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tin-verification/basic-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# EIN Name Lookup with TIN number and retrieves company data
#
# GET /api/v1/tin-verification/comprehensive-check
# operationId: TinVerificationComprehensiveCheck
export def "tin-verification-comprehensive-check TinVerificationComprehensiveCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tin: string # Nine letter TIN number with or without hyphens (format: string)
  --name: string # Company Name (format: string)
  --threshold: int # The percentage of minimum similarity threshold for company matching (optional, default: 70%) (format: int64)
]: nothing -> record<einResult: string, matchedCompanies: any, tinResult: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tin" $tin "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "threshold" $threshold "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tin-verification/comprehensive-check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# EIN Name Lookup with TIN number
#
# GET /api/v1/tin-verification/name-lookup
# operationId: TinVerificationNameLookup
export def "tin-verification-name-lookup TinVerificationNameLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tin: string # Nine letter TIN number with or without hyphens (format: string)
]: nothing -> record<matchStatus: string, possibleMatch: string, tin: string> {
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tin" $tin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/tin-verification/name-lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns a verification result
#
# POST /api/v1/vat-verification/basic-check/{country}
# operationId: VatBasic
export def "vat-verification-basic-check VatBasic" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --companyAddress: string # company address lines
  --companyName: string # Company name
  --companyNumber: string # official company number
  vatNumber: string # VAT number to validate
]: any -> record<candidate: list<any>, company: any, confidenceScore: float, validationStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/vat-verification/basic-check/($country)")
  let body = {companyAddress: $companyAddress, companyName: $companyName, companyNumber: $companyNumber, vatNumber: $vatNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns a verification result and company data
#
# POST /api/v1/vat-verification/comprehensive-check/{country}
# operationId: VatComprehensive
export def "vat-verification-comprehensive-check VatComprehensive" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --companyAddress: string # company address lines
  --companyName: string # Company name
  --companyNumber: string # official company number
  vatNumber: string # VAT number to validate
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/vat-verification/comprehensive-check/($country)")
  let body = {companyAddress: $companyAddress, companyName: $companyName, companyNumber: $companyNumber, vatNumber: $vatNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns a level two verification result
#
# POST /api/v1/vat-verification/leveltwo-check/{country}
# operationId: VatLevelTwo
export def "vat-verification-leveltwo-check VatLevelTwo" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --confirmation: oneof<nothing, bool> # If a confirmation document should be ordered
  vatNumber: string # VAT number to validate
]: any -> record<address: string, confirmation: string, level: string, name: string, validationStatus: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/vat-verification/leveltwo-check/($country)")
  let body = {confirmation: $confirmation, vatNumber: $vatNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Returns a list of vat numbers with additional data
#
# POST /api/v1/vat-verification/lookup/{country}
# operationId: VatLookup
export def "vat-verification-lookup VatLookup" [
  country: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --address: string # Company address (e.g. null)
  name: string # Company name (e.g. null)
]: any -> record<matches: table<company: any, vat: string>, searchterm_address: string, searchterm_country: string, searchterm_name: string, timestamp: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "user_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/vat-verification/lookup/($country)")
  let body = {address: $address, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}
