# Auto-generated client for Call Control API v2015-11-01
# Source: https://api.apis.guru/v2/specs/callcontrol.com/2015-11-01/swagger.json
# Auth: --token flag or $env.CALL_CONTROL_API_TOKEN

const BASE_URL = "https://api.callcontrol.com"
const DEFAULT_AUTH = "apikey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CALL_CONTROL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "apikey" => { {headers: {apiKey: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.callcontrol.com"] }
def auth-scheme-completer [] { ["apikey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def BlockBehavior-completer [] { ["allow" "block" "voiceMail"] }
def CallerType-completer [] { ["Business" "Callback" "Collection_Agency" "Fax_Machine" "Fund_Raiser" "Junk_Fax" "NotSpam" "Other_Commercial" "Political" "Prank_Call" "Reminder_Notification_Call" "RoboCall" "Scam" "Spam_Text" "Surveyor" "Telemarketing" "Unknown" "VOIP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "2015-11-01-complaints Complaints" } } | get name | first)
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

# Complaints: Free service (with registration), providing community and government complaint lookup by phone number for up to 2,000 queries per month.  Details include number complaint rates from (FTC, FCC, IRS, Indiana Attorney  General) and key entity tag extractions from complaints.
#
# GET /api/2015-11-01/Complaints/{phoneNumber}
# operationId: Complaints_Complaints
export def "2015-11-01-complaints Complaints" [
  phoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<ComplaintsByEntity: record, LastComplaintDate: string, ReportedCallerName: string, Tags: list<string>, TotalNumberOfComplaints: int> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/2015-11-01/Complaints/($phoneNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enterprise  GET: GetUser Returns the current information from the user;  try 12066194123 as demo
#
# GET /api/2015-11-01/Enterprise/GetUser/{phoneNumber}
# operationId: EnterpriseApi_GetUser
export def "2015-11-01-enterprise-get-user GetUser" [
  phoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<Age: int, BlackList: list<string>, BlockBehavior: string, BreakThroughQhWithMultipleCalls: bool, Email: string, FirstName: string, Gender: string, LastName: string, MiddleName: string, PhoneNumbeRegion: string, PhoneNumber: string, QuietHourList: table<DayOfWeekList: list, DurationMin: int, StartHourLocal: int, StartMinLocal: int, TimeZoneName: string>, Salutation: string, Suffix: string, UseCommunityBlacklist: bool, WhiteList: list<string>, WhiteListBreaksQh: bool> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/2015-11-01/Enterprise/GetUser/($phoneNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enterprise  GET: ShouldBlock Simple Enteprise which returns a call block proceed decision.
#
# GET /api/2015-11-01/Enterprise/ShouldBlock/{phoneNumber}/{userPhoneNumber}
# operationId: EnterpriseApi_ShouldBlock
export def "2015-11-01-enterprise-should-block ShouldBlock" [
  phoneNumber: string
  userPhoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/2015-11-01/Enterprise/ShouldBlock/($phoneNumber)/($userPhoneNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# UpsertUser: insert or update all properties from a user PhoneNumber WhiteList (list of phone numbers to whitelist) BlackList (list of phone numbers to blacklist) QuietHourList (list of quiet hour objects) UseCommunityBlacklist (enable / disable community blacklist) default true BreakThroughQhWithMultipleCalls (break through quiet hours with two calls in 3 minutes) WhiteListBreaksQh (break through quiet hours for whitelist)
#
# POST /api/2015-11-01/Enterprise/UpsertUser
# operationId: EnterpriseApi_UpsertUser
# --QuietHourList item shape: {DayOfWeekList?: list, DurationMin?: int, StartHourLocal?: int, StartMinLocal?: int, TimeZoneName?: string}
export def "2015-11-01-enterprise-upsert-user UpsertUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Age: int # format: int32
  --BlackList: list
  --BlockBehavior: string@BlockBehavior-completer
  --BreakThroughQhWithMultipleCalls: oneof<nothing, bool>
  --Email: string
  --FirstName: string
  --Gender: string
  --LastName: string
  --MiddleName: string
  --PhoneNumbeRegion: string
  --PhoneNumber: string
  --QuietHourList: list # item shape: {DayOfWeekList?: list, DurationMin?: int, StartHourLocal?: int, StartMinLocal?: int, TimeZoneName?: string}
  --Salutation: string
  --Suffix: string
  --UseCommunityBlacklist: oneof<nothing, bool>
  --WhiteList: list
  --WhiteListBreaksQh: oneof<nothing, bool>
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/2015-11-01/Enterprise/UpsertUser")
  let body = {Age: $Age, BlackList: $BlackList, BlockBehavior: $BlockBehavior, BreakThroughQhWithMultipleCalls: $BreakThroughQhWithMultipleCalls, Email: $Email, FirstName: $FirstName, Gender: $Gender, LastName: $LastName, MiddleName: $MiddleName, PhoneNumbeRegion: $PhoneNumbeRegion, PhoneNumber: $PhoneNumber, QuietHourList: $QuietHourList, Salutation: $Salutation, Suffix: $Suffix, UseCommunityBlacklist: $UseCommunityBlacklist, WhiteList: $WhiteList, WhiteListBreaksQh: $WhiteListBreaksQh} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Report: report spam calls received to better tune our algorithms based upon spam calls you receive
#
# POST /api/2015-11-01/Report
# operationId: Reputation_Report
export def "2015-11-01-report Report" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --CallTime: string # format: date-time
  --CallerType: string@CallerType-completer
  --Comment: string
  --IpAddress: string
  --Latitude: float # format: double
  --Longitude: float # format: double
  --PhoneNumber: string
  --ReportedCallerId: string
  --ReportedCallerName: string
  --Reporter: string
  --UnwantedCall: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/2015-11-01/Report")
  let body = {CallTime: $CallTime, CallerType: $CallerType, Comment: $Comment, IpAddress: $IpAddress, Latitude: $Latitude, Longitude: $Longitude, PhoneNumber: $PhoneNumber, ReportedCallerId: $ReportedCallerId, ReportedCallerName: $ReportedCallerName, Reporter: $Reporter, UnwantedCall: $UnwantedCall} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reputation: Premium service which returns a reputation informaiton of a phone number via API.
#
# GET /api/2015-11-01/Reputation/{phoneNumber}
# operationId: Reputation_Reputation
export def "2015-11-01-reputation Reputation" [
  phoneNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<CallType: string, Confidence: int, IsSpam: bool, LastComplaintDate: string, ReportedCallerName: string, Tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "apikey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/2015-11-01/Reputation/($phoneNumber)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
