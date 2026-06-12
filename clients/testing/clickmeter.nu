# Auto-generated client for ClickMeter API vv2
# Source: https://api.apis.guru/v2/specs/clickmeter.com/v2/openapi.json
# Auth: --token flag or $env.CLICKMETER_API_TOKEN

const BASE_URL = "http://apiv2.clickmeter.com:80"
const DEFAULT_AUTH = "x-clickmeter-authkey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLICKMETER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-clickmeter-authkey" => { {headers: {X-Clickmeter-AuthKey: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://apiv2.clickmeter.com:80" "https://apiv2.clickmeter.com:80"] }
def auth-scheme-completer [] { ["x-clickmeter-authkey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def sortDirection-completer [] { ["asc" "desc"] }
def timeFormat-completer [] { ["AmPm" "H24"] }
def entityType-completer [] { ["datapoint" "group"] }
def type-completer [] { ["r" "w"] }
def timeFrame-completer [] { ["beginning" "currentmonth" "currentyear" "custom" "last120" "last12months" "last180" "last30" "last7" "last90" "lastmonth" "lastyear" "previousmonth" "today" "yesterday"] }
def groupBy-completer [] { ["month" "week"] }
def status-completer [] { ["active" "deleted"] }
def type-completer-1 [] { ["tl" "tp"] }
def status-completer-1 [] { ["active" "deleted" "paused" "spam"] }
def filter-completer [] { ["" "conversions" "nonuniques" "spiders" "uniques"] }
def protocol-completer [] { ["Http" "Https"] }
def timeframe-completer [] { ["currentmonth" "custom" "last120" "last180" "last30" "last7" "last90" "lastmonth" "previousmonth" "yesterday"] }
def filter-completer-1 [] { ["conversions" "nonuniques" "spiders" "uniques"] }
def status-completer-2 [] { ["Abuse" "Active" "Deleted" "Paused"] }
def type-completer-2 [] { ["TrackingLink" "TrackingPixel"] }
def type-completer-3 [] { ["dedicated" "go" "personal" "system"] }
def type-completer-4 [] { ["Dedicated" "Go" "Personal" "System"] }
def groupBy-completer-1 [] { ["active" "deleted"] }
def type-completer-5 [] { ["dp" "gr" "tl" "tp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account Get" } } | get name | first)
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

# Retrieve current account data
#
# GET /account
# operationId: Account_Get
export def "account Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update current account data
#
# POST /account
# operationId: Account_Post
export def "account Post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --boGoVal: string
  --bonusClicks: int # format: int64
  --companyName: string
  --companyRole: string
  --email: string
  --firstName: string
  --lastName: string
  --phone: string
  --redirectOnly: oneof<nothing, bool>
  --registrationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --timeframeMinDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezone: int # format: int32
  --timezonename: string
]: any -> record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let body = {boGoVal: $boGoVal, bonusClicks: $bonusClicks, companyName: $companyName, companyRole: $companyRole, email: $email, firstName: $firstName, lastName: $lastName, phone: $phone, redirectOnly: $redirectOnly, registrationDate: $registrationDate, timeframeMinDate: $timeframeMinDate, timezone: $timezone, timezonename: $timezonename} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve list of a domains allowed to redirect in DDU mode
#
# GET /account/domainwhitelist
# operationId: Account_GetDomainWhitelist
export def "account-domainwhitelist GetDomainWhitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
]: nothing -> record<entities: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/domainwhitelist" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an domain entry
#
# POST /account/domainwhitelist
# operationId: Account_PutDomainWhitelist
export def "account-domainwhitelist PutDomainWhitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string
  --name: string
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/domainwhitelist")
  let body = {id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an domain entry
#
# DELETE /account/domainwhitelist/{whitelistId}
# operationId: Account_DeleteDomainWhitelist
export def "account-domainwhitelist DeleteDomainWhitelist" [
  whitelistId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/domainwhitelist/($whitelistId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve list of a guest
#
# GET /account/guests
# operationId: Account_GetGuests
export def "account-guests GetGuests" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --sortBy: string # Field to sort by
  --sortDirection: string@sortDirection-completer # Direction of sort "asc" or "desc"
  --textSearch: string # Filter fields by this pattern
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "textSearch" $textSearch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/guests" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a guest
#
# POST /account/guests
# operationId: Account_PutGuest
# --conversionOptions shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
# --currentGrant shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
# --extendedGrants shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
# --hitOptions shape: {hideReferrer?: bool}
export def "account-guests PutGuest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apiKey: string
  --conversionOptions: record # shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --currentGrant: record # shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
  --dateFormat: string
  --decimalSeparator: string
  --email: string
  --extendedGrants: record # shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
  --groupGrants: int # format: int64
  --hitOptions: record # shape: {hideReferrer?: bool}
  --id: int # format: int64
  --key: string
  --language: string
  --loginCount: int # format: int32
  --name: string
  --notes: string
  --numberGroupSeparator: string
  --password: string
  --timeFormat: string@timeFormat-completer
  --timeZone: int # format: int32
  --timeframeMinDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezonename: string
  --tlGrants: int # format: int64
  --tpGrants: int # format: int64
  --userName: string
]: any -> record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/guests")
  let body = {apiKey: $apiKey, conversionOptions: $conversionOptions, creationDate: $creationDate, currentGrant: $currentGrant, dateFormat: $dateFormat, decimalSeparator: $decimalSeparator, email: $email, extendedGrants: $extendedGrants, groupGrants: $groupGrants, hitOptions: $hitOptions, id: $id, key: $key, language: $language, loginCount: $loginCount, name: $name, notes: $notes, numberGroupSeparator: $numberGroupSeparator, password: $password, timeFormat: $timeFormat, timeZone: $timeZone, timeframeMinDate: $timeframeMinDate, timezonename: $timezonename, tlGrants: $tlGrants, tpGrants: $tpGrants, userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve count of guests
#
# GET /account/guests/count
# operationId: Account_GetGuestsCount
export def "account-guests-count GetGuestsCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --textSearch: string # Filter fields by this pattern
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "textSearch" $textSearch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/guests/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a guest
#
# DELETE /account/guests/{guestId}
# operationId: Account_DeleteGuest
export def "account-guests DeleteGuest" [
  guestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/guests/($guestId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a guest
#
# GET /account/guests/{guestId}
# operationId: Account_GetGuest
export def "account-guests GetGuest" [
  guestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/guests/($guestId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a guest
#
# POST /account/guests/{guestId}
# operationId: Account_PostGuest
# --conversionOptions shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
# --currentGrant shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
# --extendedGrants shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
# --hitOptions shape: {hideReferrer?: bool}
export def "account-guests PostGuest" [
  guestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apiKey: string
  --conversionOptions: record # shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --currentGrant: record # shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
  --dateFormat: string
  --decimalSeparator: string
  --email: string
  --extendedGrants: record # shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
  --groupGrants: int # format: int64
  --hitOptions: record # shape: {hideReferrer?: bool}
  --id: int # format: int64
  --key: string
  --language: string
  --loginCount: int # format: int32
  --name: string
  --notes: string
  --numberGroupSeparator: string
  --password: string
  --timeFormat: string@timeFormat-completer
  --timeZone: int # format: int32
  --timeframeMinDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezonename: string
  --tlGrants: int # format: int64
  --tpGrants: int # format: int64
  --userName: string
]: any -> record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/guests/($guestId)")
  let body = {apiKey: $apiKey, conversionOptions: $conversionOptions, creationDate: $creationDate, currentGrant: $currentGrant, dateFormat: $dateFormat, decimalSeparator: $decimalSeparator, email: $email, extendedGrants: $extendedGrants, groupGrants: $groupGrants, hitOptions: $hitOptions, id: $id, key: $key, language: $language, loginCount: $loginCount, name: $name, notes: $notes, numberGroupSeparator: $numberGroupSeparator, password: $password, timeFormat: $timeFormat, timeZone: $timeZone, timeframeMinDate: $timeframeMinDate, timezonename: $timezonename, tlGrants: $tlGrants, tpGrants: $tpGrants, userName: $userName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve permissions for a guest
#
# GET /account/guests/{guestId}/permissions
# operationId: Account_GetPermissions
export def "account-guests-permissions GetPermissions" [
  guestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --entityType: string@entityType-completer # Can be "datapoint" or "group"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --type: string@type-completer # Can be "w" or "r"
  --entityId: int # Optional id of the datapoint/group entity to filter by (format: int64)
]: nothing -> record<entities: table<DatapointType: string, Entity: record, EntityName: string, EntityType: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entityType" $entityType "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "entityId" $entityId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/account/guests/($guestId)/permissions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve count of the permissions for a guest
#
# GET /account/guests/{guestId}/permissions/count
# operationId: Account_GetPermissionsCount
export def "account-guests-permissions-count GetPermissionsCount" [
  guestId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --entityType: string@entityType-completer # Can be "datapoint" or "group"
  --type: string@type-completer # Can be "w" or "r"
  --entityId: int # Optional id of the datapoint/group entity to filter by (format: int64)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "entityType" $entityType "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "entityId" $entityId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/account/guests/($guestId)/permissions/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change the permission on a shared object
#
# POST /account/guests/{guestId}/{type}/permissions/patch
export def "account-guests-permissions-patch post" [
  guestId: int
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Action: string
  --Id: int # format: int64
  --Verb: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/guests/($guestId)/($type)/permissions/patch")
  let body = {Action: $Action, Id: $Id, Verb: $Verb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change the permission on a shared object
#
# PUT /account/guests/{guestId}/{type}/permissions/patch
# operationId: Account_PatchPermissions
export def "account-guests-permissions-patch PatchPermissions" [
  guestId: int
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Action: string
  --Id: int # format: int64
  --Verb: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/guests/($guestId)/($type)/permissions/patch")
  let body = {Action: $Action, Id: $Id, Verb: $Verb} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve list of a ip to exclude from event tracking
#
# GET /account/ipblacklist
# operationId: Account_GetIpBlacklist
export def "account-ipblacklist GetIpBlacklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
]: nothing -> record<entities: table<id: string, ip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/ipblacklist" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an ip blacklist entry
#
# POST /account/ipblacklist
# operationId: Account_PutIpBlacklist
export def "account-ipblacklist PutIpBlacklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string
  --ip: string
]: any -> record<id: string, ip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/ipblacklist")
  let body = {id: $id, ip: $ip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an ip blacklist entry
#
# DELETE /account/ipblacklist/{blacklistId}
# operationId: Account_DeleteIpBlacklist
export def "account-ipblacklist DeleteIpBlacklist" [
  blacklistId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, ip: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/ipblacklist/($blacklistId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve current account plan
#
# GET /account/plan
# operationId: Account_GetPlan
export def "account-plan GetPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<allowedPersonalDomains: int, allowedPersonalUrls: int, billingPeriodEnd: string, billingPeriodStart: string, bonusMonthlyEvents: int, maximumDatapoints: int, maximumGuests: int, monthlyEvents: int, name: string, price: float, profileId: int, recurring: bool, recurringPeriod: int, usedDatapoints: int, usedMonthlyEvents: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/plan")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about this customer for a timeframe
#
# GET /aggregated
# operationId: Aggregated_GetStatisticsSingle
export def "aggregated GetStatisticsSingle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --onlyFavorites: string
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "hourly" $hourly "scalar") (serialize-qp "onlyFavorites" $onlyFavorites "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /aggregated/list
# operationId: Aggregated_GetStatisticsList
export def "aggregated-list GetStatisticsList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --groupBy: string@groupBy-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "groupBy" $groupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about a subset of conversions for a timeframe with conversions data
#
# GET /aggregated/summary/conversions
# operationId: Aggregated_GetConversionsSummary
export def "aggregated-summary-conversions GetConversionsSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --sortBy: string # Field to sort by
  --sortDirection: string@sortDirection-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --textSearch: string # Filter fields by this pattern
]: nothing -> record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "textSearch" $textSearch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated/summary/conversions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about a subset of datapoints for a timeframe with datapoints data
#
# GET /aggregated/summary/datapoints
# operationId: Aggregated_GetDatapointsSummary
export def "aggregated-summary-datapoints GetDatapointsSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --sortBy: string # Field to sort by
  --sortDirection: string@sortDirection-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --groupId: int # Filter by this group id (format: int64)
  --textSearch: string # Filter fields by this pattern
]: nothing -> record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "groupId" $groupId "scalar") (serialize-qp "textSearch" $textSearch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated/summary/datapoints" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about a subset of groups for a timeframe with groups data
#
# GET /aggregated/summary/groups
# operationId: Aggregated_GetGroupsSummary
export def "aggregated-summary-groups GetGroupsSummary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group marked as favourite
  --sortBy: string # Field to sort by
  --sortDirection: string@sortDirection-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --textSearch: string # Filter fields by this pattern
]: nothing -> record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "textSearch" $textSearch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated/summary/groups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the latest list of events of this account. Limited to last 100.
#
# GET /clickstream
# operationId: ClickStream_Get
export def "clickstream Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --group: int # Filter by this group id (mutually exclusive with "datapoint" and "conversion") (format: int64)
  --datapoint: int # Filter by this datapoint id (mutually exclusive with "group" and "conversion") (format: int64)
  --conversion: int # Filter by this conversion id (mutually exclusive with "datapoint" and "group") (format: int64)
  --pageSize: int # Limit results to this number (format: int32, default: 50)
  --filter: string@filter-completer # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<entities: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group" $group "scalar") (serialize-qp "datapoint" $datapoint "scalar") (serialize-qp "conversion" $conversion "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clickstream" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of conversions
#
# GET /conversions
# operationId: Conversions_Get
export def "conversions Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude conversions created before this date (YYYYMMDD)
  --createdBefore: string # Exclude conversions created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversions" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a conversion
#
# POST /conversions
# operationId: Conversions_Put
export def "conversions Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --code: string
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --description: string
  --id: int # format: int64
  --name: string
  --protocol: string@protocol-completer
  --value: float # format: double
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/conversions")
  let body = {code: $code, creationDate: $creationDate, deleted: $deleted, description: $description, id: $id, name: $name, protocol: $protocol, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve statistics about this customer for a timeframe related to a subset of conversions grouped by some temporal entity (day/week/month)
#
# GET /conversions/aggregated/list
# operationId: Conversions_GetStatisticsAllList
export def "conversions-aggregated-list GetStatisticsAllList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --groupBy: string@groupBy-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "groupBy" $groupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversions/aggregated/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a count of conversions
#
# GET /conversions/count
# operationId: Conversions_Count
export def "conversions-count Count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude conversions created before this date (YYYYMMDD)
  --createdBefore: string # Exclude conversions created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversions/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete conversion specified by id
#
# DELETE /conversions/{conversionId}
# operationId: Conversions_Delete
export def "conversions Delete" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversions/($conversionId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve conversion specified by id
#
# GET /conversions/{conversionId}
export def "conversions get" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, creationDate: string, deleted: bool, description: string, id: int, name: string, protocol: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversions/($conversionId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update conversion specified by id
#
# POST /conversions/{conversionId}
# operationId: Conversions_Post
export def "conversions Post" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --code: string
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --description: string
  --id: int # format: int64
  --name: string
  --protocol: string@protocol-completer
  --value: float # format: double
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversions/($conversionId)")
  let body = {code: $code, creationDate: $creationDate, deleted: $deleted, description: $description, id: $id, name: $name, protocol: $protocol, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve statistics about this conversion for a timeframe
#
# GET /conversions/{conversionId}/aggregated
# operationId: Conversions_GetStatisticsSingle
export def "conversions-aggregated GetStatisticsSingle" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --tag: string # Filter by this tag name
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversions/($conversionId)/aggregated" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about this conversion for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /conversions/{conversionId}/aggregated/list
# operationId: Conversions_GetStatisticsList
export def "conversions-aggregated-list GetStatisticsList" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --groupBy: string@groupBy-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "groupBy" $groupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversions/($conversionId)/aggregated/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of datapoints connected to this conversion
#
# GET /conversions/{conversionId}/datapoints
# operationId: Conversions_GetDatapoints
export def "conversions-datapoints GetDatapoints" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tags: string # Filter by this tag name
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversions/($conversionId)/datapoints" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the association between a conversion and multiple datapoints
#
# PUT /conversions/{conversionId}/datapoints/batch/patch
# --PatchRequests item shape: {Action?: string, Id?: int}
export def "conversions-datapoints-batch-patch put" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --PatchRequests: list # item shape: {Action?: string, Id?: int}
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversions/($conversionId)/datapoints/batch/patch")
  let body = {PatchRequests: $PatchRequests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a count of datapoints connected to this conversion
#
# GET /conversions/{conversionId}/datapoints/count
# operationId: Conversions_GetDatapointsCount
export def "conversions-datapoints-count GetDatapointsCount" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string # Type of datapoint ("tl"/"tp")
  --status: string # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tags: string # Filter by this tag name
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversions/($conversionId)/datapoints/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify the association between a conversion and a datapoint
#
# PUT /conversions/{conversionId}/datapoints/patch
# operationId: Conversions_Patch
export def "conversions-datapoints-patch Patch" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Action: string
  --Id: int # format: int64
  --ReplaceId: int # format: int64
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversions/($conversionId)/datapoints/patch")
  let body = {Action: $Action, Id: $Id, ReplaceId: $ReplaceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the list of events related to this conversion.
#
# GET /conversions/{conversionId}/hits
# operationId: Conversions_GetHits
export def "conversions-hits GetHits" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/conversions/($conversionId)/hits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fast patch the "notes" field of a conversion
#
# PUT /conversions/{conversionId}/notes
# operationId: Conversions_PatchNotes
export def "conversions-notes PatchNotes" [
  conversionId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Text: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/conversions/($conversionId)/notes")
  let body = {Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of all the datapoints associated to the user
#
# GET /datapoints
# operationId: DataPoints_Get
export def "datapoints Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --textSearch: string # Filter fields by this pattern
  --onlyFavorites: oneof<nothing, bool> # Filter fields by favourite status
  --sortBy: string # Field to sort by
  --sortDirection: string@sortDirection-completer # Direction of sort "asc" or "desc"
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "onlyFavorites" $onlyFavorites "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datapoints" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a datapoint
#
# POST /datapoints
# operationId: DataPoints_Put
# --tags item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
# --typeTL shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, pauseAfterDateExpiration?: bool, randomDestinationItems?: list, redirectType?: "PermanentRedirect"|"TemporaryRedirect", referrerClean?: "None"|"Clean"|"Myself", scripts?: list, sequentialDestinationItems?: list, spilloverDestinationItems?: list, uniqueDestinationItem?: record, url?: string, urlAfterClicksExpiration?: string, urlAfterDateExpiration?: string, urlsByLanguage?: list, urlsByNation?: list, weightedDestinationItems?: list}
# --typeTP shape: {parameterNote?: string}
export def "datapoints Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --encodeIp: oneof<nothing, bool>
  --fifthConversionId: int # format: int64
  --fifthConversionName: string
  --firstConversionId: int # format: int64
  --firstConversionName: string
  --fourthConversionId: int # format: int64
  --fourthConversionName: string
  --groupId: int # format: int64
  --groupName: string
  --id: int # format: int64
  --isPublic: oneof<nothing, bool>
  --isSecured: oneof<nothing, bool>
  --lightTracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirectOnly: oneof<nothing, bool>
  --secondConversionId: int # format: int64
  --secondConversionName: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
  --thirdConversionId: int # format: int64
  --thirdConversionName: string
  --title: string
  --trackingCode: string
  --type: string@type-completer-2
  --typeTL: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, pauseAfterDateExpiration?: bool, randomDestinationItems?: list, redirectType?: "PermanentRedirect"|"TemporaryRedirect", referrerClean?: "None"|"Clean"|"Myself", scripts?: list, sequentialDestinationItems?: list, spilloverDestinationItems?: list, uniqueDestinationItem?: record, url?: string, urlAfterClicksExpiration?: string, urlAfterDateExpiration?: string, urlsByLanguage?: list, urlsByNation?: list, weightedDestinationItems?: list}
  --typeTP: record # shape: {parameterNote?: string}
  --writePermited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datapoints")
  let body = {creationDate: $creationDate, encodeIp: $encodeIp, fifthConversionId: $fifthConversionId, fifthConversionName: $fifthConversionName, firstConversionId: $firstConversionId, firstConversionName: $firstConversionName, fourthConversionId: $fourthConversionId, fourthConversionName: $fourthConversionName, groupId: $groupId, groupName: $groupName, id: $id, isPublic: $isPublic, isSecured: $isSecured, lightTracking: $lightTracking, name: $name, notes: $notes, preferred: $preferred, redirectOnly: $redirectOnly, secondConversionId: $secondConversionId, secondConversionName: $secondConversionName, status: $status, tags: $tags, thirdConversionId: $thirdConversionId, thirdConversionName: $thirdConversionName, title: $title, trackingCode: $trackingCode, type: $type, typeTL: $typeTL, typeTP: $typeTP, writePermited: $writePermited} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve statistics about this customer for a timeframe by groups
#
# GET /datapoints/aggregated
# operationId: DataPoints_GetStatisticsAggregatedSingle
export def "datapoints-aggregated GetStatisticsAggregatedSingle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint is marked as favourite
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "hourly" $hourly "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datapoints/aggregated" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about all datapoints of this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /datapoints/aggregated/list
# operationId: DataPoints_GetStatisticsAllList
export def "datapoints-aggregated-list GetStatisticsAllList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint is marked as favourite
  --groupBy: string@groupBy-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "groupBy" $groupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datapoints/aggregated/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete multiple datapoints
#
# DELETE /datapoints/batch
# operationId: DataPoints_BatchDelete
# --Entities item shape: {id?: int, uri?: string}
export def "datapoints-batch BatchDelete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --Entities: list # item shape: {id?: int, uri?: string}
]: any -> record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datapoints/batch")
  let body = {Entities: $Entities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update multiple datapoints
#
# POST /datapoints/batch
# operationId: DataPoints_BatchPost
# --List item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, thirdConversionId?: int, thirdConversionName?: string, title?: string, trackingCode?: string, type?: "TrackingLink"|"TrackingPixel", typeTL?: record, typeTP?: record, writePermited?: bool}
export def "datapoints-batch BatchPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --List: list # item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, thirdConversionId?: int, thirdConversionName?: string, title?: string, trackingCode?: string, type?: "TrackingLink"|"TrackingPixel", typeTL?: record, typeTP?: record, writePermited?: bool}
]: any -> record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datapoints/batch")
  let body = {List: $List} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create multiple datapoints
#
# PUT /datapoints/batch
# operationId: DataPoints_BatchPut
# --List item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, thirdConversionId?: int, thirdConversionName?: string, title?: string, trackingCode?: string, type?: "TrackingLink"|"TrackingPixel", typeTL?: record, typeTP?: record, writePermited?: bool}
export def "datapoints-batch BatchPut" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --List: list # item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, thirdConversionId?: int, thirdConversionName?: string, title?: string, trackingCode?: string, type?: "TrackingLink"|"TrackingPixel", typeTL?: record, typeTP?: record, writePermited?: bool}
]: any -> record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datapoints/batch")
  let body = {List: $List} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count the datapoints associated to the user
#
# GET /datapoints/count
# operationId: DataPoints_Count
export def "datapoints-count Count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --textSearch: string # Filter fields by this pattern
  --onlyFavorites: oneof<nothing, bool> # Filter fields by favourite status
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "onlyFavorites" $onlyFavorites "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datapoints/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a datapoint
#
# DELETE /datapoints/{id}
# operationId: DataPoints_Delete
export def "datapoints Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datapoints/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a datapoint
#
# GET /datapoints/{id}
export def "datapoints get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: table<datapoints: list, groups: list, id: int, name: string>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record<emailDestinationUrl: string, mobileDestinationUrl: string, spidersDestinationUrl: string>, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list<record>, redirectType: string, referrerClean: string, scripts: list<record>, sequentialDestinationItems: list<record>, spilloverDestinationItems: list<record>, uniqueDestinationItem: record<firstDestinationUrl: string>, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list<record>, urlsByNation: list<record>, weightedDestinationItems: list<record>>, typeTP: record<parameterNote: string>, writePermited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datapoints/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a datapoint
#
# POST /datapoints/{id}
# operationId: DataPoints_Post
# --tags item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
# --typeTL shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, pauseAfterDateExpiration?: bool, randomDestinationItems?: list, redirectType?: "PermanentRedirect"|"TemporaryRedirect", referrerClean?: "None"|"Clean"|"Myself", scripts?: list, sequentialDestinationItems?: list, spilloverDestinationItems?: list, uniqueDestinationItem?: record, url?: string, urlAfterClicksExpiration?: string, urlAfterDateExpiration?: string, urlsByLanguage?: list, urlsByNation?: list, weightedDestinationItems?: list}
# --typeTP shape: {parameterNote?: string}
export def "datapoints Post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --encodeIp: oneof<nothing, bool>
  --fifthConversionId: int # format: int64
  --fifthConversionName: string
  --firstConversionId: int # format: int64
  --firstConversionName: string
  --fourthConversionId: int # format: int64
  --fourthConversionName: string
  --groupId: int # format: int64
  --groupName: string
  --body-id: int # format: int64
  --isPublic: oneof<nothing, bool>
  --isSecured: oneof<nothing, bool>
  --lightTracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirectOnly: oneof<nothing, bool>
  --secondConversionId: int # format: int64
  --secondConversionName: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
  --thirdConversionId: int # format: int64
  --thirdConversionName: string
  --title: string
  --trackingCode: string
  --type: string@type-completer-2
  --typeTL: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, pauseAfterDateExpiration?: bool, randomDestinationItems?: list, redirectType?: "PermanentRedirect"|"TemporaryRedirect", referrerClean?: "None"|"Clean"|"Myself", scripts?: list, sequentialDestinationItems?: list, spilloverDestinationItems?: list, uniqueDestinationItem?: record, url?: string, urlAfterClicksExpiration?: string, urlAfterDateExpiration?: string, urlsByLanguage?: list, urlsByNation?: list, weightedDestinationItems?: list}
  --typeTP: record # shape: {parameterNote?: string}
  --writePermited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datapoints/($id)")
  let body = {creationDate: $creationDate, encodeIp: $encodeIp, fifthConversionId: $fifthConversionId, fifthConversionName: $fifthConversionName, firstConversionId: $firstConversionId, firstConversionName: $firstConversionName, fourthConversionId: $fourthConversionId, fourthConversionName: $fourthConversionName, groupId: $groupId, groupName: $groupName, id: $body_id, isPublic: $isPublic, isSecured: $isSecured, lightTracking: $lightTracking, name: $name, notes: $notes, preferred: $preferred, redirectOnly: $redirectOnly, secondConversionId: $secondConversionId, secondConversionName: $secondConversionName, status: $status, tags: $tags, thirdConversionId: $thirdConversionId, thirdConversionName: $thirdConversionName, title: $title, trackingCode: $trackingCode, type: $type, typeTL: $typeTL, typeTP: $typeTP, writePermited: $writePermited} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve statistics about this datapoint for a timeframe
#
# GET /datapoints/{id}/aggregated
# operationId: DataPoints_GetStatisticsSingle
export def "datapoints-aggregated GetStatisticsSingle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/datapoints/($id)/aggregated" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about this datapoint for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /datapoints/{id}/aggregated/list
# operationId: DataPoints_GetStatisticsList
export def "datapoints-aggregated-list GetStatisticsList" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --groupBy: string@groupBy-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "groupBy" $groupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/datapoints/($id)/aggregated/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fast switch the "favourite" field of a datapoint
#
# PUT /datapoints/{id}/favourite
# operationId: DataPoints_PatchFavourite
export def "datapoints-favourite PatchFavourite" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datapoints/($id)/favourite")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the list of events related to this datapoint.
#
# GET /datapoints/{id}/hits
# operationId: DataPoints_GetHits
export def "datapoints-hits GetHits" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/datapoints/($id)/hits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fast patch the "notes" field of a datapoint
#
# PUT /datapoints/{id}/notes
# operationId: DataPoints_PatchNotes
export def "datapoints-notes PatchNotes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Text: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/datapoints/($id)/notes")
  let body = {Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a list of domains
#
# GET /domains
# operationId: Domains_Get
export def "domains Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --type: string@type-completer-3 # Type of domain ("system"/"go"/"personal"/"dedicated"). If not specified default is "system" (default: system)
  --name: string # Filter domains with this anmen
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a domain
#
# POST /domains
# operationId: Domains_Put
export def "domains Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom404: string
  --customHomepage: string
  --id: int # format: int64
  --name: string
  --type: string@type-completer-4
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains")
  let body = {custom404: $custom404, customHomepage: $customHomepage, id: $id, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve count of domains
#
# GET /domains/count
# operationId: Domains_Count
export def "domains-count Count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # Type of domain ("system"/"go"/"personal"/"dedicated"). If not specified default is "system" (default: system)
  --name: string # Filter domains with this anmen
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a domain
#
# DELETE /domains/{id}
# operationId: Domains_Delete
export def "domains Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a domain
#
# GET /domains/{id}
export def "domains get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom404: string, customHomepage: string, id: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a domain
#
# POST /domains/{id}
# operationId: Domains_Update
export def "domains Update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom404: string
  --customHomepage: string
  --body-id: int # format: int64
  --name: string
  --type: string@type-completer-4
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/domains/($id)")
  let body = {custom404: $custom404, customHomepage: $customHomepage, id: $body_id, name: $name, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of all the groups associated to the user.
#
# GET /groups
# operationId: Groups_Get
export def "groups Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer # Status of the group
  --tags: string # A comma separated list of tags you want to filter with.
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude groups created before this date (YYYYMMDD)
  --createdBefore: string # Exclude groups created after this date (YYYYMMDD)
  --write: oneof<nothing, bool> # Write permission
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "write" $write "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a group
#
# POST /groups
# operationId: Groups_Put
# --tags item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
export def "groups Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --id: int # format: int64
  --isPublic: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirectOnly: oneof<nothing, bool>
  --tags: list # item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
  --writePermited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups")
  let body = {creationDate: $creationDate, deleted: $deleted, id: $id, isPublic: $isPublic, name: $name, notes: $notes, preferred: $preferred, redirectOnly: $redirectOnly, tags: $tags, writePermited: $writePermited} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve statistics about this customer for a timeframe by groups
#
# GET /groups/aggregated
# operationId: Groups_GetStatisticsAggregatedSingle
export def "groups-aggregated GetStatisticsAggregatedSingle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --status: string@status-completer # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group is marked as favourite
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "hourly" $hourly "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/aggregated" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about all groups of this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /groups/aggregated/list
# operationId: Groups_GetStatisticsAllList
export def "groups-aggregated-list GetStatisticsAllList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group is marked as favourite
  --groupBy: string@groupBy-completer-1 # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "groupBy" $groupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/aggregated/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count the groups associated to the user.
#
# GET /groups/count
# operationId: Groups_Count
export def "groups-count Count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude groups created before this date (YYYYMMDD)
  --createdBefore: string # Exclude groups created after this date (YYYYMMDD)
  --write: oneof<nothing, bool> # Write permission
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar") (serialize-qp "write" $write "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete group specified by id
#
# DELETE /groups/{id}
# operationId: Groups_Delete
export def "groups Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a group
#
# GET /groups/{id}
export def "groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<creationDate: string, deleted: bool, id: int, isPublic: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, tags: table<datapoints: list, groups: list, id: int, name: string>, writePermited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a group
#
# POST /groups/{id}
# operationId: Groups_Post
# --tags item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
export def "groups Post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --body-id: int # format: int64
  --isPublic: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirectOnly: oneof<nothing, bool>
  --tags: list # item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
  --writePermited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)")
  let body = {creationDate: $creationDate, deleted: $deleted, id: $body_id, isPublic: $isPublic, name: $name, notes: $notes, preferred: $preferred, redirectOnly: $redirectOnly, tags: $tags, writePermited: $writePermited} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve statistics about this group for a timeframe
#
# GET /groups/{id}/aggregated
# operationId: Groups_GetStatisticsSingle
export def "groups-aggregated GetStatisticsSingle" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($id)/aggregated" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about this group for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /groups/{id}/aggregated/list
# operationId: Groups_GetStatisticsList
export def "groups-aggregated-list GetStatisticsList" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --groupBy: string@groupBy-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "groupBy" $groupBy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($id)/aggregated/list" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve statistics about a subset of datapoints for a timeframe with datapoints data
#
# GET /groups/{id}/aggregated/summary
# operationId: Groups_GetDatapointsSummary
export def "groups-aggregated-summary GetDatapointsSummary" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeFrame: string@timeFrame-completer # Timeframe of the request. See list at $timeframeList
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --sortBy: string # Field to sort by
  --sortDirection: string@sortDirection-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32, default: 0)
  --limit: int # Limit results to this number (format: int32, default: 20)
  --textSearch: string # Filter fields by this pattern
]: nothing -> record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $timeFrame "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "textSearch" $textSearch "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($id)/aggregated/summary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all the datapoints associated to the user in this group.
#
# GET /groups/{id}/datapoints
# operationId: Groups_GetDatapoints
export def "groups-datapoints GetDatapoints" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --textSearch: string # Filter fields by this pattern
  --onlyFavorites: oneof<nothing, bool> # Filter fields by favourite status
  --sortBy: string # Field to sort by
  --sortDirection: string@sortDirection-completer # Direction of sort "asc" or "desc"
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "onlyFavorites" $onlyFavorites "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($id)/datapoints" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a datapoint in this group
#
# POST /groups/{id}/datapoints
# operationId: Groups_PutDatapoint
# --tags item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
# --typeTL shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, pauseAfterDateExpiration?: bool, randomDestinationItems?: list, redirectType?: "PermanentRedirect"|"TemporaryRedirect", referrerClean?: "None"|"Clean"|"Myself", scripts?: list, sequentialDestinationItems?: list, spilloverDestinationItems?: list, uniqueDestinationItem?: record, url?: string, urlAfterClicksExpiration?: string, urlAfterDateExpiration?: string, urlsByLanguage?: list, urlsByNation?: list, weightedDestinationItems?: list}
# --typeTP shape: {parameterNote?: string}
export def "groups-datapoints PutDatapoint" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creationDate: string #  (A date in "YmdHis" format) (e.g. 20120203120530)
  --encodeIp: oneof<nothing, bool>
  --fifthConversionId: int # format: int64
  --fifthConversionName: string
  --firstConversionId: int # format: int64
  --firstConversionName: string
  --fourthConversionId: int # format: int64
  --fourthConversionName: string
  --groupId: int # format: int64
  --groupName: string
  --body-id: int # format: int64
  --isPublic: oneof<nothing, bool>
  --isSecured: oneof<nothing, bool>
  --lightTracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirectOnly: oneof<nothing, bool>
  --secondConversionId: int # format: int64
  --secondConversionName: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list, groups?: list, id?: int, name?: string}
  --thirdConversionId: int # format: int64
  --thirdConversionName: string
  --title: string
  --trackingCode: string
  --type: string@type-completer-2
  --typeTL: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, pauseAfterDateExpiration?: bool, randomDestinationItems?: list, redirectType?: "PermanentRedirect"|"TemporaryRedirect", referrerClean?: "None"|"Clean"|"Myself", scripts?: list, sequentialDestinationItems?: list, spilloverDestinationItems?: list, uniqueDestinationItem?: record, url?: string, urlAfterClicksExpiration?: string, urlAfterDateExpiration?: string, urlsByLanguage?: list, urlsByNation?: list, weightedDestinationItems?: list}
  --typeTP: record # shape: {parameterNote?: string}
  --writePermited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)/datapoints")
  let body = {creationDate: $creationDate, encodeIp: $encodeIp, fifthConversionId: $fifthConversionId, fifthConversionName: $fifthConversionName, firstConversionId: $firstConversionId, firstConversionName: $firstConversionName, fourthConversionId: $fourthConversionId, fourthConversionName: $fourthConversionName, groupId: $groupId, groupName: $groupName, id: $body_id, isPublic: $isPublic, isSecured: $isSecured, lightTracking: $lightTracking, name: $name, notes: $notes, preferred: $preferred, redirectOnly: $redirectOnly, secondConversionId: $secondConversionId, secondConversionName: $secondConversionName, status: $status, tags: $tags, thirdConversionId: $thirdConversionId, thirdConversionName: $thirdConversionName, title: $title, trackingCode: $trackingCode, type: $type, typeTL: $typeTL, typeTP: $typeTP, writePermited: $writePermited} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Count the datapoints associated to the user in this group.
#
# GET /groups/{id}/datapoints/count
# operationId: Groups_GetDatapointsCount
export def "groups-datapoints-count GetDatapointsCount" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --textSearch: string # Filter fields by this pattern
  --onlyFavorites: oneof<nothing, bool> # Filter fields by favourite status
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "onlyFavorites" $onlyFavorites "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($id)/datapoints/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fast switch the "favourite" field of a group
#
# PUT /groups/{id}/favourite
# operationId: Groups_PatchFavourite
export def "groups-favourite PatchFavourite" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)/favourite")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the list of events related to this group.
#
# GET /groups/{id}/hits
# operationId: Groups_GetHits
export def "groups-hits GetHits" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/groups/($id)/hits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fast patch the "notes" field of a group
#
# PUT /groups/{id}/notes
# operationId: Groups_PatchNotes
export def "groups-notes PatchNotes" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Text: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/groups/($id)/notes")
  let body = {Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the list of events related to this account.
#
# GET /hits
# operationId: Hits_GetHits
export def "hits GetHits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --fromDay: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --toDay: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fromDay" $fromDay "scalar") (serialize-qp "toDay" $toDay "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve current account data
#
# GET /me
# operationId: Me_GetMe
export def "me GetMe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve current account plan
#
# GET /me/plan
# operationId: Me_GetMePlan
export def "me-plan GetMePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<allowedPersonalDomains: int, allowedPersonalUrls: int, billingPeriodEnd: string, billingPeriodStart: string, bonusMonthlyEvents: int, maximumDatapoints: int, maximumGuests: int, monthlyEvents: int, name: string, price: float, profileId: int, recurring: bool, recurringPeriod: int, usedDatapoints: int, usedMonthlyEvents: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/plan")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all the retargeting scripts associated to the user
#
# GET /retargeting
# operationId: Retargeting_Get
export def "retargeting Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/retargeting" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a retargeting script
#
# POST /retargeting
# operationId: Retargeting_Put
export def "retargeting Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int64
  --name: string
  --script: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retargeting")
  let body = {id: $id, name: $name, script: $script} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve count of retargeting scripts
#
# GET /retargeting/count
# operationId: Retargeting_Count
export def "retargeting-count Count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retargeting/count")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a retargeting script (and remove associations)
#
# DELETE /retargeting/{id}
# operationId: Retargeting_Delete
export def "retargeting Delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retargeting/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a retargeting script object
#
# GET /retargeting/{id}
export def "retargeting get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, name: string, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retargeting/($id)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a retargeting script
#
# POST /retargeting/{id}
# operationId: Retargeting_Post
export def "retargeting Post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int64
  --name: string
  --script: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/retargeting/($id)")
  let body = {id: $body_id, name: $name, script: $script} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of all the datapoints associated to the retargeting script.
#
# GET /retargeting/{id}/datapoints
# operationId: Retargeting_GetDatapoints
export def "retargeting-datapoints GetDatapoints" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --textSearch: string # Filter fields by this pattern
  --onlyFavorites: oneof<nothing, bool> # Filter fields by favourite status
  --sortBy: string # Field to sort by
  --sortDirection: string@sortDirection-completer # Direction of sort "asc" or "desc"
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "onlyFavorites" $onlyFavorites "scalar") (serialize-qp "sortBy" $sortBy "scalar") (serialize-qp "sortDirection" $sortDirection "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/retargeting/($id)/datapoints" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count the datapoints associated to the retargeting script.
#
# GET /retargeting/{id}/datapoints/count
# operationId: Retargeting_GetDatapointsCount
export def "retargeting-datapoints-count GetDatapointsCount" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --textSearch: string # Filter fields by this pattern
  --onlyFavorites: oneof<nothing, bool> # Filter fields by favourite status
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "onlyFavorites" $onlyFavorites "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/retargeting/($id)/datapoints/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags
# operationId: Tags_Get
export def "tags Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --name: string # Name of the tag
  --datapoints: string # Comma separated list of datapoints id to filter by
  --groups: string # Comma separated list of groups id to filter by
  --type: string@type-completer-5 # Type of entity related to the tag
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "datapoints" $datapoints "scalar") (serialize-qp "groups" $groups "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a tag
#
# POST /tags
# operationId: Tags_Put
export def "tags Put" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --datapoints: list
  --groups: list
  --id: int # format: int64
  --name: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags")
  let body = {datapoints: $datapoints, groups: $groups, id: $id, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags/count
# operationId: Tags_Count
export def "tags-count Count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --name: string # Name of the tag
  --datapoints: string # Comma separated list of datapoints id to filter by
  --groups: string # Comma separated list of groups id to filter by
  --type: string@type-completer-5 # Type of entity related to the tag
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "datapoints" $datapoints "scalar") (serialize-qp "groups" $groups "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tags/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a tag
#
# DELETE /tags/{tagId}
# operationId: Tags_Delete
export def "tags Delete" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tagId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a tag
#
# GET /tags/{tagId}
export def "tags get" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<datapoints: list<int>, groups: list<int>, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tagId)")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the association of this tag with all datapoints
#
# DELETE /tags/{tagId}/datapoints
# operationId: Tags_DeleteRelatedDatapoints
export def "tags-datapoints DeleteRelatedDatapoints" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tagId)/datapoints")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all the datapoints associated to the user filtered by this tag
#
# GET /tags/{tagId}/datapoints
# operationId: Tags_GetDatapoints
export def "tags-datapoints GetDatapoints" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tagId)/datapoints" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count the datapoints associated to the user filtered by this tag
#
# GET /tags/{tagId}/datapoints/count
# operationId: Tags_GetDatapointsCount
export def "tags-datapoints-count GetDatapointsCount" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude datapoints created before this date (YYYYMMDD)
  --createdBefore: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tagId)/datapoints/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate/Deassociate a tag with a datapoint
#
# PUT /tags/{tagId}/datapoints/patch
# operationId: Tags_PatchDataPoint
export def "tags-datapoints-patch PatchDataPoint" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Action: string
  --Id: int # format: int64
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tagId)/datapoints/patch")
  let body = {Action: $Action, Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the association of this tag with all groups
#
# DELETE /tags/{tagId}/groups
# operationId: Tags_DeleteRelatedGroups
export def "tags-groups DeleteRelatedGroups" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tagId)/groups")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags/{tagId}/groups
# operationId: Tags_GetGroups
export def "tags-groups GetGroups" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer # Status of the datapoint
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude groups created before this date (YYYYMMDD)
  --createdBefore: string # Exclude groups created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tagId)/groups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Count the groups associated to the user filtered by this tag
#
# GET /tags/{tagId}/groups/count
# operationId: Tags_GetGroupsCount
export def "tags-groups-count GetGroupsCount" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # Status of the datapoint
  --textSearch: string # Filter fields by this pattern
  --createdAfter: string # Exclude groups created before this date (YYYYMMDD)
  --createdBefore: string # Exclude groups created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "createdAfter" $createdAfter "scalar") (serialize-qp "createdBefore" $createdBefore "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tags/($tagId)/groups/count" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Associate/Deassociate a tag with a group
#
# PUT /tags/{tagId}/groups/patch
# operationId: Tags_PatchGroup
export def "tags-groups-patch PatchGroup" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Action: string
  --Id: int # format: int64
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tagId)/groups/patch")
  let body = {Action: $Action, Id: $Id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Fast patch a tag name
#
# PUT /tags/{tagId}/name
# operationId: Tags_PatchTagName
export def "tags-name PatchTagName" [
  tagId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --Text: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tags/($tagId)/name")
  let body = {Text: $Text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
