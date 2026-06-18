# Auto-generated client for LetMC Api V2, Free (Tier 1) vv2-free-tier
# Source: https://api.apis.guru/v2/specs/letmc.com/free-tier/v2-free-tier/swagger.json
# Auth: --token flag or $env.LETMC_API_V2_FREE__TIER_1_TOKEN

const BASE_URL = "https://live-api.letmc.com"
const DEFAULT_AUTH = "apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LETMC_API_V2_FREE__TIER_1_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "apikey" => { {headers: {ApiKey: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://live-api.letmc.com"] }
def auth-scheme-completer [] { ["apikey" "basic" "basic-credentials"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "tier1-area-areas list" } } | get name | first)
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

# A collection of all the areas for a company
#
# GET /v2/tier1/{shortName}/area/areas
export def "tier1-area-areas list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Branch: string, ETag: string, Name: string, OID: string, ShowOnSites: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/area/areas") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific area given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/area/areas/{areaID}
export def "tier1-area-areas get" [
  short_name: string
  area_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Branch: string, ETag: string, Name: string, OID: string, ShowOnSites: bool> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), area_id: (encode-path-segment $area_id)} | format pattern "/v2/tier1/{short_name}/area/areas/{area_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# All branches defined for a company
#
# GET /v2/tier1/{shortName}/branch/branches
export def "tier1-branch-branches list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/branch/branches") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific branch given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/branch/branches/{branchID}
export def "tier1-branch-branches get" [
  short_name: string
  branch_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), branch_id: (encode-path-segment $branch_id)} | format pattern "/v2/tier1/{short_name}/branch/branches/{branch_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about a specific company
#
# GET /v2/tier1/{shortName}/company
# operationId: CompanyController_GetCompany
export def "tier1-company get-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<CompanyName: string, CompanyRegistration: string, ETag: string, MarketingCompanyName: string, OID: string, ShortName: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/company"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all counties available for a company
#
# GET /v2/tier1/{shortName}/county/counties
export def "tier1-county-counties list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, Name: string, OID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/county/counties") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific county given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/county/counties/{countyID}
export def "tier1-county-counties get" [
  short_name: string
  county_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ETag: string, Name: string, OID: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), county_id: (encode-path-segment $county_id)} | format pattern "/v2/tier1/{short_name}/county/counties/{county_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of branches that manage a specific county
#
# GET /v2/tier1/{shortName}/county/counties/{countyID}/branches
# operationId: CountyController_GetCountiesBranches
export def "tier1-county-counties-branches get-controller" [
  short_name: string
  county_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, CompanyName: string, County: string, EMailAddress: string, ETag: string, FaxPhone: string, LandPhone: string, Name: string, OID: string, Postcode: string, WebAddress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), county_id: (encode-path-segment $county_id)} | format pattern "/v2/tier1/{short_name}/county/counties/{county_id}/branches") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all diary allocations
#
# GET /v2/tier1/{shortName}/diary/allocations
export def "tier1-diary-allocations list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<AppointmentType: string, ETag: string, End: string, OID: string, Staff: string, Start: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/diary/allocations") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific diary allocation given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/diary/allocations/{diaryAllocationID}
export def "tier1-diary-allocations get" [
  short_name: string
  diary_allocation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AppointmentType: string, ETag: string, End: string, OID: string, Staff: string, Start: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), diary_allocation_id: (encode-path-segment $diary_allocation_id)} | format pattern "/v2/tier1/{short_name}/diary/allocations/{diary_allocation_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all diary appointments
#
# GET /v2/tier1/{shortName}/diary/appointments
export def "tier1-diary-appointments list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, OID: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/diary/appointments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific diary appointment given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/diary/appointments/{diaryAppointmentID}
export def "tier1-diary-appointments get" [
  short_name: string
  diary_appointment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AppointmentType: string, Cancelled: bool, Comment: string, CreatedAt: string, CreatedBy: string, ETag: string, End: string, OID: string, RemindAt: string, RemindBefore: string, Staff: string, Start: string, Subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), diary_appointment_id: (encode-path-segment $diary_appointment_id)} | format pattern "/v2/tier1/{short_name}/diary/appointments/{diary_appointment_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all diary appointment types
#
# GET /v2/tier1/{shortName}/diary/appointmenttypes
export def "tier1-diary-appointmenttypes list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, Name: string, OID: string, SystemType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/diary/appointmenttypes") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific diary appointment type given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/diary/appointmenttypes/{diaryAppointmentTypeID}
export def "tier1-diary-appointmenttypes get" [
  short_name: string
  diary_appointment_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ETag: string, Name: string, OID: string, SystemType: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), diary_appointment_type_id: (encode-path-segment $diary_appointment_type_id)} | format pattern "/v2/tier1/{short_name}/diary/appointmenttypes/{diary_appointment_type_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search all properties available for rent given a range of search criteria.
#
# GET /v2/tier1/{shortName}/lettings/advertised
# operationId: LettingsController_GetAdvertised
export def "tier1-lettings-advertised get-controller" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --branch-id: string # The unique ID of the Branch
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
  --area-id: string # The unique ID of the Area
  --rent-minimum: float # The minimum advertised rent to search for (format: double)
  --rent-maximum: float # The maximum advertised rent to search for (format: double)
  --maximum-tenants: int # The maximum number of tenants a property can accommodate (format: int32)
  --want-shared-properties: oneof<nothing, bool> # Search for shared properties?
  --want-student-properties: oneof<nothing, bool> # Search for student properties?
]: nothing -> record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branchID" $branch_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "areaID" $area_id "scalar") (serialize-qp "rentMinimum" $rent_minimum "scalar") (serialize-qp "rentMaximum" $rent_maximum "scalar") (serialize-qp "maximumTenants" $maximum_tenants "scalar") (serialize-qp "wantSharedProperties" $want_shared_properties "scalar") (serialize-qp "wantStudentProperties" $want_student_properties "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/lettings/advertised") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search all properties available for rent given a range of search criteria and dates.
#
# GET /v2/tier1/{shortName}/lettings/advertisedbetweendates
# operationId: LettingsController_GetAdvertisedBetweenDates
export def "tier1-lettings-advertisedbetweendates get-controller-advertised-between-dates" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --branch-id: string # The unique ID of the Branch
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
  --range-start-date: string # The date to search from (format: date-time)
  --range-end-date: string # The date to search to (format: date-time)
  --area-id: string # The unique ID of the Area
  --rent-minimum: float # The minimum advertised rent to search for (format: double)
  --rent-maximum: float # The maximum advertised rent to search for (format: double)
  --maximum-tenants: int # The maximum number of tenants a property can accommodate (format: int32)
  --want-shared-properties: oneof<nothing, bool> # Search for shared properties?
  --want-student-properties: oneof<nothing, bool> # Search for student properties?
]: nothing -> record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branchID" $branch_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "rangeStartDate" $range_start_date "scalar") (serialize-qp "rangeEndDate" $range_end_date "scalar") (serialize-qp "areaID" $area_id "scalar") (serialize-qp "rentMinimum" $rent_minimum "scalar") (serialize-qp "rentMaximum" $rent_maximum "scalar") (serialize-qp "maximumTenants" $maximum_tenants "scalar") (serialize-qp "wantSharedProperties" $want_shared_properties "scalar") (serialize-qp "wantStudentProperties" $want_student_properties "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/lettings/advertisedbetweendates") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all the company's tenancies
#
# GET /v2/tier1/{shortName}/lettings/tenancies
export def "tier1-lettings-tenancies list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/lettings/tenancies") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific tenancy given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/lettings/tenancies/{tenancyID}
export def "tier1-lettings-tenancies get" [
  short_name: string
  tenancy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list<string>, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), tenancy_id: (encode-path-segment $tenancy_id)} | format pattern "/v2/tier1/{short_name}/lettings/tenancies/{tenancy_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the brochure relating to the latest advertised rental of a property
#
# GET /v2/tier1/{shortName}/lettings/tenancies/{tenancyID}/brochure
# operationId: LettingsController_GetTenancyBrochure
export def "tier1-lettings-tenancies-brochure get-controller-tenancy" [
  short_name: string
  tenancy_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), tenancy_id: (encode-path-segment $tenancy_id)} | format pattern "/v2/tier1/{short_name}/lettings/tenancies/{tenancy_id}/brochure"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all photos in the company
#
# GET /v2/tier1/{shortName}/photo/photos
export def "tier1-photo-photos list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/photo/photos") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific photo given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/photo/photos/{photoID}
export def "tier1-photo-photos get" [
  short_name: string
  photo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), photo_id: (encode-path-segment $photo_id)} | format pattern "/v2/tier1/{short_name}/photo/photos/{photo_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the photo of a property given the property and photo ID.
#
# GET /v2/tier1/{shortName}/photos/photo/{photoID}/download
# operationId: PhotoController_GetPhotoDownload
export def "tier1-photos-photo-download get-controller" [
  short_name: string
  photo_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --width: int # An optional parameter specifying the image width (format: int32)
  --height: int # An optional parameter specifying the image height (format: int32)
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), photo_id: (encode-path-segment $photo_id)} | format pattern "/v2/tier1/{short_name}/photos/photo/{photo_id}/download") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all properties within a company
#
# GET /v2/tier1/{shortName}/property/properties
export def "tier1-property-properties list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, PropertyType: string, RoomName: string, VideoURL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/property/properties") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific property given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}
export def "tier1-property-properties get" [
  short_name: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, PropertyType: string, RoomName: string, VideoURL: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), property_id: (encode-path-segment $property_id)} | format pattern "/v2/tier1/{short_name}/property/properties/{property_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of facilities linked to a block, property or room
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}/facilities
# operationId: PropertyController_GetPropertiesFacilities
export def "tier1-property-properties-facilities get-controller" [
  short_name: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, Name: string, OID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), property_id: (encode-path-segment $property_id)} | format pattern "/v2/tier1/{short_name}/property/properties/{property_id}/facilities") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection showing all the photos linked to a specific block, property or room
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}/photos
# operationId: PropertyController_GetPropertiesPhotos
export def "tier1-property-properties-photos get-controller" [
  short_name: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), property_id: (encode-path-segment $property_id)} | format pattern "/v2/tier1/{short_name}/property/properties/{property_id}/photos") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of the rooms that belong to this property or block
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}/rooms
# operationId: PropertyController_GetPropertiesRooms
export def "tier1-property-properties-rooms get-controller" [
  short_name: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, HeightCentimeters: int, HeightMeters: int, LengthCentimeters: int, LengthMeters: int, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, RoomFloor: string, RoomName: string, WidthCentiMeters: int, WidthMeters: int>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), property_id: (encode-path-segment $property_id)} | format pattern "/v2/tier1/{short_name}/property/properties/{property_id}/rooms") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all tenancies associated with this block, property or room
#
# GET /v2/tier1/{shortName}/property/properties/{propertyID}/tenancies
# operationId: PropertyController_GetPropertiesTenancies
export def "tier1-property-properties-tenancies get-controller" [
  short_name: string
  property_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<AdvertiseFrom: string, Area: string, BondRequired: float, Branch: string, ETag: string, Furnished: string, GlobalReference: string, IsShareProperty: bool, IsStudentProperty: bool, IsTenancyAdvertised: bool, IsTenancyProposed: bool, MaximumTenants: int, MinimumTenants: int, OID: string, RentAdvertised: float, RentRecurrence: int, RentSchedule: string, TenancyProperty: string, TenantSystemTypes: list, TermMaximum: int, TermMinimum: int, TermStart: string, UtilityCouncilTax: string, UtilityElectricity: string, UtilityGas: string, UtilityTelephone: string, UtilityWater: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), property_id: (encode-path-segment $property_id)} | format pattern "/v2/tier1/{short_name}/property/properties/{property_id}/tenancies") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the energy efficiency report (EER) graph for a property
#
# GET /v2/tier1/{shortName}/property/structures/{propertyStructureID}/reports/eer
# operationId: PropertyController_GetPropertyEERDownload
export def "tier1-property-structures-reports-eer get-controller-download" [
  short_name: string
  property_structure_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), property_structure_id: (encode-path-segment $property_structure_id)} | format pattern "/v2/tier1/{short_name}/property/structures/{property_structure_id}/reports/eer"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the environmental impact report (EIR) graph for a property
#
# GET /v2/tier1/{shortName}/property/structures/{propertyStructureID}/reports/eir
# operationId: PropertyController_GetPropertyEIRDownload
export def "tier1-property-structures-reports-eir get-controller-download" [
  short_name: string
  property_structure_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), property_structure_id: (encode-path-segment $property_structure_id)} | format pattern "/v2/tier1/{short_name}/property/structures/{property_structure_id}/reports/eir"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search all sales properties available given a range of search criteria
#
# GET /v2/tier1/{shortName}/sales/advertisedsales
# operationId: SalesController_GetAdvertisedSales
export def "tier1-sales-advertisedsales get-controller-advertised" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --branch-id: string # The unique ID of the Branch
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
  --only-developement: oneof<nothing, bool> # Show only development properties?
  --only-investements: oneof<nothing, bool> # Show only investment properties?
  --minimum-price: float # The minimum price to search for (format: double)
  --maximum-price: float # The maximum price to search for (format: double)
  --minimum-beds: int # The minimum beds to search for (format: int32)
  --minimum-bathrooms: int # The minimum bathrooms to search for (format: int32)
  --minimum-ensuites: int # The minimum ensuite bathrooms to search for (format: int32)
  --minimum-toilets: int # The minimum toilets to search for (format: int32)
  --minimum-reception: int # The minimum reception rooms to search for (format: int32)
]: nothing -> record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "branchID" $branch_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "onlyDevelopement" $only_developement "scalar") (serialize-qp "onlyInvestements" $only_investements "scalar") (serialize-qp "minimumPrice" $minimum_price "scalar") (serialize-qp "maximumPrice" $maximum_price "scalar") (serialize-qp "minimumBeds" $minimum_beds "scalar") (serialize-qp "minimumBathrooms" $minimum_bathrooms "scalar") (serialize-qp "minimumEnsuites" $minimum_ensuites "scalar") (serialize-qp "minimumToilets" $minimum_toilets "scalar") (serialize-qp "minimumReception" $minimum_reception "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/sales/advertisedsales") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the energy efficiency report (EER) graph for a sales instruction
#
# GET /v2/tier1/{shortName}/sales/reports/eer/{salesInstructionID}
# operationId: SalesController_GetEER
export def "tier1-sales-reports-eer get-controller" [
  short_name: string
  sales_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), sales_instruction_id: (encode-path-segment $sales_instruction_id)} | format pattern "/v2/tier1/{short_name}/sales/reports/eer/{sales_instruction_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Downloads the energy efficiency report (EIR) graph for a sales instruction
#
# GET /v2/tier1/{shortName}/sales/reports/eir/{salesInstructionID}
# operationId: SalesController_GetEIR
export def "tier1-sales-reports-eir get-controller" [
  short_name: string
  sales_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), sales_instruction_id: (encode-path-segment $sales_instruction_id)} | format pattern "/v2/tier1/{short_name}/sales/reports/eir/{sales_instruction_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all sales feature types linked to a company
#
# GET /v2/tier1/{shortName}/sales/salesfeaturetypes
export def "tier1-sales-salesfeaturetypes list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, Name: string, OID: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/sales/salesfeaturetypes") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific sales feature type given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/sales/salesfeaturetypes/{salesFeatureTypeID}
export def "tier1-sales-salesfeaturetypes get" [
  short_name: string
  sales_feature_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ETag: string, Name: string, OID: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), sales_feature_type_id: (encode-path-segment $sales_feature_type_id)} | format pattern "/v2/tier1/{short_name}/sales/salesfeaturetypes/{sales_feature_type_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all sales instructions linked to a company
#
# GET /v2/tier1/{shortName}/sales/salesinstructions
export def "tier1-sales-salesinstructions list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/sales/salesinstructions") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific sales instruction given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}
export def "tier1-sales-salesinstructions get" [
  short_name: string
  sales_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Address1: string, Address2: string, Address3: string, Address4: string, AddressNumber: string, Area: string, Bathrooms: int, BathroomsEnsuite: int, Bedrooms: int, ContractType: string, Country: string, Description: string, DevelopmentOpp: bool, Directions: string, EPCCurrentEER: int, EPCCurrentEI: int, EPCPotentialEER: int, EPCPotentialEI: int, ETag: string, HasElectricitySupply: bool, HasGasSupply: bool, HasWaterMeter: bool, InvestmentOpp: bool, Kitchens: int, OID: string, OutsideSpaceBalcony: bool, OutsideSpaceCommunalGarden: bool, OutsideSpaceConservatory: bool, OutsideSpaceGarden: bool, OutsideSpaceLargeGarden: bool, OutsideSpacePatio: bool, OutsideSpaceRoofTerrace: bool, OutsideSpaceSouthFacingGarden: bool, ParkingAllocated: bool, ParkingCarport: bool, ParkingDoubleGarage: bool, ParkingGarage: bool, ParkingOffRoad: bool, ParkingOnRoad: bool, ParkingPermit: bool, ParkingSecureGated: bool, ParkingTripleGarage: bool, Postcode: string, Price: float, PropertyOwnableType: string, ReceptionRooms: int, State: string, Tenure: string, VideoURL: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), sales_instruction_id: (encode-path-segment $sales_instruction_id)} | format pattern "/v2/tier1/{short_name}/sales/salesinstructions/{sales_instruction_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all features linked to a sales instruction
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/features
# operationId: SalesController_GetSalesInstructionsFeatures
export def "tier1-sales-salesinstructions-features get-controller-instructions" [
  short_name: string
  sales_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Comment: string, ETag: string, OID: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), sales_instruction_id: (encode-path-segment $sales_instruction_id)} | format pattern "/v2/tier1/{short_name}/sales/salesinstructions/{sales_instruction_id}/features") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of floor plans linked to an instruction
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/floorplans
# operationId: SalesController_GetSalesInstructionsFloorPlans
export def "tier1-sales-salesinstructions-floorplans get-controller-instructions-floor-plans" [
  short_name: string
  sales_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), sales_instruction_id: (encode-path-segment $sales_instruction_id)} | format pattern "/v2/tier1/{short_name}/sales/salesinstructions/{sales_instruction_id}/floorplans") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of photos linked to an instruction
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/photos
# operationId: SalesController_GetSalesInstructionsPhotos
export def "tier1-sales-salesinstructions-photos get-controller-instructions" [
  short_name: string
  sales_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, FileName: string, InspectionItem: string, InterimInspection: string, InventoryItem: string, Name: string, OID: string, PhotoNumber: int, PhotoType: string, Property: string, Room: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), sales_instruction_id: (encode-path-segment $sales_instruction_id)} | format pattern "/v2/tier1/{short_name}/sales/salesinstructions/{sales_instruction_id}/photos") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of rooms linked to an instruction
#
# GET /v2/tier1/{shortName}/sales/salesinstructions/{salesInstructionID}/rooms
# operationId: SalesController_GetSalesInstructionsRooms
export def "tier1-sales-salesinstructions-rooms get-controller-instructions" [
  short_name: string
  sales_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<Area: string, Branch: string, Description: string, ETag: string, FullAddress: string, GlobalReference: string, HeightCentimeters: int, HeightMeters: int, LengthCentimeters: int, LengthMeters: int, MainPhoto: string, ManagedByStaff: string, OID: string, PropertySource: string, RoomFloor: string, RoomName: string, WidthCentiMeters: int, WidthMeters: int>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), sales_instruction_id: (encode-path-segment $sales_instruction_id)} | format pattern "/v2/tier1/{short_name}/sales/salesinstructions/{sales_instruction_id}/rooms") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# A collection of all the staff members linked to a specific company
#
# GET /v2/tier1/{shortName}/staff/staff
export def "tier1-staff-staff list" [
  short_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --offset: int # The index of the first item to return (format: int32)
  --count: int # The maximum number of items to return (up to 1000 per request) (format: int32)
]: nothing -> record<Count: int, Data: table<ETag: string, Forename: string, GlobalReference: string, IsEnabled: bool, ManagedBy: string, Middlename: string, OID: string, Surname: string, Title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name)} | format pattern "/v2/tier1/{short_name}/staff/staff") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a specific application staff given its unique Object ID (OID)
#
# GET /v2/tier1/{shortName}/staff/staff/{applicationStaffID}
export def "tier1-staff-staff get" [
  short_name: string
  application_staff_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ETag: string, Forename: string, GlobalReference: string, IsEnabled: bool, ManagedBy: string, Middlename: string, OID: string, Surname: string, Title: string> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({short_name: (encode-path-segment $short_name), application_staff_id: (encode-path-segment $application_staff_id)} | format pattern "/v2/tier1/{short_name}/staff/staff/{application_staff_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
