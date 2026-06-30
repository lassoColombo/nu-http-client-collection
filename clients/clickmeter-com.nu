# Auto-generated client for ClickMeter API vv2
# Source: https://api.apis.guru/v2/specs/clickmeter.com/v2/openapi.json
# Auth: --token flag or $env.CLICKMETER_API_TOKEN

const BASE_URL = "http://apiv2.clickmeter.com:80"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CLICKMETER_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-clickmeter-authkey" => { {scheme: $scheme, headers: {X-Clickmeter-AuthKey: $token_val}, query: "", location: "header"} }
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://apiv2.clickmeter.com:80" "https://apiv2.clickmeter.com:80"] }
def auth-scheme-completer [] { ["x-clickmeter-authkey"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def accept-completer-1 [] { ["application/json" "text/json"] }
def sort-direction-completer [] { ["asc" "desc"] }
def time-format-completer [] { ["AmPm" "H24"] }
def entity-type-completer [] { ["datapoint" "group"] }
def type-completer [] { ["r" "w"] }
def time-frame-completer [] { ["beginning" "currentmonth" "currentyear" "custom" "last120" "last12months" "last180" "last30" "last7" "last90" "lastmonth" "lastyear" "previousmonth" "today" "yesterday"] }
def group-by-completer [] { ["month" "week"] }
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
def group-by-completer-1 [] { ["active" "deleted"] }
def type-completer-5 [] { ["dp" "gr" "tl" "tp"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account get" } } | get name | first)
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
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update current account data
#
# POST /account
# operationId: Account_Post
export def "account create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --bo-go-val: string
  --bonus-clicks: int # format: int64
  --company-name: string
  --company-role: string
  --email: string
  --first-name: string
  --last-name: string
  --phone: string
  --redirect-only: oneof<nothing, bool>
  --registration-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --timeframe-min-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezone: int # format: int32
  --timezonename: string
]: any -> record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account" $auth.query)
  let req_body = {"boGoVal": $bo_go_val, "bonusClicks": $bonus_clicks, "companyName": $company_name, "companyRole": $company_role, "email": $email, "firstName": $first_name, "lastName": $last_name, "phone": $phone, "redirectOnly": $redirect_only, "registrationDate": $registration_date, "timeframeMinDate": $timeframe_min_date, "timezone": $timezone, "timezonename": $timezonename} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve list of a domains allowed to redirect in DDU mode
#
# GET /account/domainwhitelist
# operationId: Account_GetDomainWhitelist
export def "account-domainwhitelist get-domain-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
]: nothing -> record<entities: table<id: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/domainwhitelist" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an domain entry
#
# POST /account/domainwhitelist
# operationId: Account_PutDomainWhitelist
export def "account-domainwhitelist update-domain-whitelist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string
  --name: string
]: any -> record<id: string, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/domainwhitelist" $auth.query)
  let req_body = {"id": $id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an domain entry
#
# DELETE /account/domainwhitelist/{whitelistId}
# operationId: Account_DeleteDomainWhitelist
export def "account-domainwhitelist delete-domain-whitelist" [
  whitelist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($whitelist_id | is-empty) { error make --unspanned { msg: "path parameter 'whitelistId' must be non-empty" } }
  let full_url = (build-url $base ({whitelist_id: (encode-path-segment $whitelist_id)} | format pattern "/account/domainwhitelist/{whitelist_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve list of a guest
#
# GET /account/guests
# operationId: Account_GetGuests
export def "account-guests list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --text-search: string # Filter fields by this pattern
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "textSearch" $text_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/guests" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "sortBy": $sort_by, "sortDirection": $sort_direction, "textSearch": $text_search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a guest
#
# POST /account/guests
# operationId: Account_PutGuest
# --conversionOptions shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
# --currentGrant shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
# --extendedGrants shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
# --hitOptions shape: {hideReferrer?: bool}
export def "account-guests update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-key: string
  --conversion-options: record # shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --current-grant: record # shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
  --date-format: string
  --decimal-separator: string
  --email: string
  --extended-grants: record # shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
  --group-grants: int # format: int64
  --hit-options: record # shape: {hideReferrer?: bool}
  --id: int # format: int64
  --key: string
  --language: string
  --login-count: int # format: int32
  --name: string
  --notes: string
  --number-group-separator: string
  --password: string
  --time-format: string@time-format-completer
  --time-zone: int # format: int32
  --timeframe-min-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezonename: string
  --tl-grants: int # format: int64
  --tp-grants: int # format: int64
  --user-name: string
]: any -> record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/guests" $auth.query)
  let req_body = {"apiKey": $api_key, "conversionOptions": $conversion_options, "creationDate": $creation_date, "currentGrant": $current_grant, "dateFormat": $date_format, "decimalSeparator": $decimal_separator, "email": $email, "extendedGrants": $extended_grants, "groupGrants": $group_grants, "hitOptions": $hit_options, "id": $id, "key": $key, "language": $language, "loginCount": $login_count, "name": $name, "notes": $notes, "numberGroupSeparator": $number_group_separator, "password": $password, "timeFormat": $time_format, "timeZone": $time_zone, "timeframeMinDate": $timeframe_min_date, "timezonename": $timezonename, "tlGrants": $tl_grants, "tpGrants": $tp_grants, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve count of guests
#
# GET /account/guests/count
# operationId: Account_GetGuestsCount
export def "account-guests-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --text-search: string # Filter fields by this pattern
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "textSearch" $text_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/guests/count" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"textSearch": $text_search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a guest
#
# DELETE /account/guests/{guestId}
# operationId: Account_DeleteGuest
export def "account-guests delete" [
  guest_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($guest_id | is-empty) { error make --unspanned { msg: "path parameter 'guestId' must be non-empty" } }
  let full_url = (build-url $base ({guest_id: (encode-path-segment $guest_id)} | format pattern "/account/guests/{guest_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve a guest
#
# GET /account/guests/{guestId}
# operationId: Account_GetGuest
export def "account-guests get" [
  guest_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($guest_id | is-empty) { error make --unspanned { msg: "path parameter 'guestId' must be non-empty" } }
  let full_url = (build-url $base ({guest_id: (encode-path-segment $guest_id)} | format pattern "/account/guests/{guest_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a guest
#
# POST /account/guests/{guestId}
# operationId: Account_PostGuest
# --conversionOptions shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
# --currentGrant shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
# --extendedGrants shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
# --hitOptions shape: {hideReferrer?: bool}
export def "account-guests create" [
  guest_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-key: string
  --conversion-options: record # shape: {hideComCost?: bool, hideCost?: bool, hideCount?: bool, hideParams?: bool, hideValue?: bool, percentCommission?: int, percentValue?: int}
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --current-grant: record # shape: {DatapointType?: string, Entity?: record, EntityName?: string, EntityType?: string, Type?: string}
  --date-format: string
  --decimal-separator: string
  --email: string
  --extended-grants: record # shape: {allowAllGrants?: bool, allowGroupCreation?: bool}
  --group-grants: int # format: int64
  --hit-options: record # shape: {hideReferrer?: bool}
  --id: int # format: int64
  --key: string
  --language: string
  --login-count: int # format: int32
  --name: string
  --notes: string
  --number-group-separator: string
  --password: string
  --time-format: string@time-format-completer
  --time-zone: int # format: int32
  --timeframe-min-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --timezonename: string
  --tl-grants: int # format: int64
  --tp-grants: int # format: int64
  --user-name: string
]: any -> record<apiKey: string, conversionOptions: record<hideComCost: bool, hideCost: bool, hideCount: bool, hideParams: bool, hideValue: bool, percentCommission: int, percentValue: int>, creationDate: string, currentGrant: record<DatapointType: string, Entity: record<id: int, uri: string>, EntityName: string, EntityType: string, Type: string>, dateFormat: string, decimalSeparator: string, email: string, extendedGrants: record<allowAllGrants: bool, allowGroupCreation: bool>, groupGrants: int, hitOptions: record<hideReferrer: bool>, id: int, key: string, language: string, loginCount: int, name: string, notes: string, numberGroupSeparator: string, password: string, timeFormat: string, timeZone: int, timeframeMinDate: string, timezonename: string, tlGrants: int, tpGrants: int, userName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($guest_id | is-empty) { error make --unspanned { msg: "path parameter 'guestId' must be non-empty" } }
  let full_url = (build-url $base ({guest_id: (encode-path-segment $guest_id)} | format pattern "/account/guests/{guest_id}") $auth.query)
  let req_body = {"apiKey": $api_key, "conversionOptions": $conversion_options, "creationDate": $creation_date, "currentGrant": $current_grant, "dateFormat": $date_format, "decimalSeparator": $decimal_separator, "email": $email, "extendedGrants": $extended_grants, "groupGrants": $group_grants, "hitOptions": $hit_options, "id": $id, "key": $key, "language": $language, "loginCount": $login_count, "name": $name, "notes": $notes, "numberGroupSeparator": $number_group_separator, "password": $password, "timeFormat": $time_format, "timeZone": $time_zone, "timeframeMinDate": $timeframe_min_date, "timezonename": $timezonename, "tlGrants": $tl_grants, "tpGrants": $tp_grants, "userName": $user_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve permissions for a guest
#
# GET /account/guests/{guestId}/permissions
# operationId: Account_GetPermissions
export def "account-guests-permissions get" [
  guest_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --entity-type: string@entity-type-completer # Can be "datapoint" or "group"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --type: string@type-completer # Can be "w" or "r"
  --entity-id: int # Optional id of the datapoint/group entity to filter by (format: int64)
]: nothing -> record<entities: table<DatapointType: string, Entity: record, EntityName: string, EntityType: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($guest_id | is-empty) { error make --unspanned { msg: "path parameter 'guestId' must be non-empty" } }
  let qp = [(serialize-qp "entityType" $entity_type "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "entityId" $entity_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({guest_id: (encode-path-segment $guest_id)} | format pattern "/account/guests/{guest_id}/permissions") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"entityType": $entity_type, "offset": $offset, "limit": $limit, "type": $type, "entityId": $entity_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve count of the permissions for a guest
#
# GET /account/guests/{guestId}/permissions/count
# operationId: Account_GetPermissionsCount
export def "account-guests-permissions-count get" [
  guest_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --entity-type: string@entity-type-completer # Can be "datapoint" or "group"
  --type: string@type-completer # Can be "w" or "r"
  --entity-id: int # Optional id of the datapoint/group entity to filter by (format: int64)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($guest_id | is-empty) { error make --unspanned { msg: "path parameter 'guestId' must be non-empty" } }
  let qp = [(serialize-qp "entityType" $entity_type "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "entityId" $entity_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({guest_id: (encode-path-segment $guest_id)} | format pattern "/account/guests/{guest_id}/permissions/count") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"entityType": $entity_type, "type": $type, "entityId": $entity_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Change the permission on a shared object
#
# POST /account/guests/{guestId}/{type}/permissions/patch
export def "account-guests-permissions-patch create" [
  guest_id: int
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string
  --id: int # format: int64
  --verb: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($guest_id | is-empty) { error make --unspanned { msg: "path parameter 'guestId' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({guest_id: (encode-path-segment $guest_id), type: (encode-path-segment $type)} | format pattern "/account/guests/{guest_id}/{type}/permissions/patch") $auth.query)
  let req_body = {"Action": $action, "Id": $id, "Verb": $verb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Change the permission on a shared object
#
# PUT /account/guests/{guestId}/{type}/permissions/patch
# operationId: Account_PatchPermissions
export def "account-guests-permissions-patch update" [
  guest_id: int
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string
  --id: int # format: int64
  --verb: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($guest_id | is-empty) { error make --unspanned { msg: "path parameter 'guestId' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({guest_id: (encode-path-segment $guest_id), type: (encode-path-segment $type)} | format pattern "/account/guests/{guest_id}/{type}/permissions/patch") $auth.query)
  let req_body = {"Action": $action, "Id": $id, "Verb": $verb} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve list of a ip to exclude from event tracking
#
# GET /account/ipblacklist
# operationId: Account_GetIpBlacklist
export def "account-ipblacklist get-ip-blacklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
]: nothing -> record<entities: table<id: string, ip: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/account/ipblacklist" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create an ip blacklist entry
#
# POST /account/ipblacklist
# operationId: Account_PutIpBlacklist
export def "account-ipblacklist update-ip-blacklist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: string
  --ip: string
]: any -> record<id: string, ip: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/ipblacklist" $auth.query)
  let req_body = {"id": $id, "ip": $ip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete an ip blacklist entry
#
# DELETE /account/ipblacklist/{blacklistId}
# operationId: Account_DeleteIpBlacklist
export def "account-ipblacklist delete-ip-blacklist" [
  blacklist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: string, ip: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($blacklist_id | is-empty) { error make --unspanned { msg: "path parameter 'blacklistId' must be non-empty" } }
  let full_url = (build-url $base ({blacklist_id: (encode-path-segment $blacklist_id)} | format pattern "/account/ipblacklist/{blacklist_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve current account plan
#
# GET /account/plan
# operationId: Account_GetPlan
export def "account-plan get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<allowedPersonalDomains: int, allowedPersonalUrls: int, billingPeriodEnd: string, billingPeriodStart: string, bonusMonthlyEvents: int, maximumDatapoints: int, maximumGuests: int, monthlyEvents: int, name: string, price: float, profileId: int, recurring: bool, recurringPeriod: int, usedDatapoints: int, usedMonthlyEvents: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/plan" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this customer for a timeframe
#
# GET /aggregated
# operationId: Aggregated_GetStatisticsSingle
export def "aggregated get-statistics-single" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --only-favorites: string
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "hourly" $hourly "scalar") (serialize-qp "onlyFavorites" $only_favorites "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "hourly": $hourly, "onlyFavorites": $only_favorites} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /aggregated/list
# operationId: Aggregated_GetStatisticsList
export def "aggregated-list get-statistics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated/list" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "groupBy": $group_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about a subset of conversions for a timeframe with conversions data
#
# GET /aggregated/summary/conversions
# operationId: Aggregated_GetConversionsSummary
export def "aggregated-summary-conversions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --text-search: string # Filter fields by this pattern
]: nothing -> record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "textSearch" $text_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated/summary/conversions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "status": $status, "sortBy": $sort_by, "sortDirection": $sort_direction, "offset": $offset, "limit": $limit, "textSearch": $text_search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about a subset of datapoints for a timeframe with datapoints data
#
# GET /aggregated/summary/datapoints
# operationId: Aggregated_GetDatapointsSummary
export def "aggregated-summary-datapoints get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --group-id: int # Filter by this group id (format: int64)
  --text-search: string # Filter fields by this pattern
]: nothing -> record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "groupId" $group_id "scalar") (serialize-qp "textSearch" $text_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated/summary/datapoints" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "type": $type, "fromDay": $from_day, "toDay": $to_day, "status": $status, "tag": $tag, "favourite": $favourite, "sortBy": $sort_by, "sortDirection": $sort_direction, "offset": $offset, "limit": $limit, "groupId": $group_id, "textSearch": $text_search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about a subset of groups for a timeframe with groups data
#
# GET /aggregated/summary/groups
# operationId: Aggregated_GetGroupsSummary
export def "aggregated-summary-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group marked as favourite
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --text-search: string # Filter fields by this pattern
]: nothing -> record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "textSearch" $text_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/aggregated/summary/groups" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "status": $status, "tag": $tag, "favourite": $favourite, "sortBy": $sort_by, "sortDirection": $sort_direction, "offset": $offset, "limit": $limit, "textSearch": $text_search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve the latest list of events of this account. Limited to last 100.
#
# GET /clickstream
# operationId: ClickStream_Get
export def "clickstream get-click-stream" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --group: int # Filter by this group id (mutually exclusive with "datapoint" and "conversion") (format: int64)
  --datapoint: int # Filter by this datapoint id (mutually exclusive with "group" and "conversion") (format: int64)
  --conversion: int # Filter by this conversion id (mutually exclusive with "datapoint" and "group") (format: int64)
  --page-size: int # Limit results to this number (format: int32, default: 50)
  --filter: string@filter-completer # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<entities: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "group" $group "scalar") (serialize-qp "datapoint" $datapoint "scalar") (serialize-qp "conversion" $conversion "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/clickstream" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"group": $group, "datapoint": $datapoint, "conversion": $conversion, "pageSize": $page_size, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of conversions
#
# GET /conversions
# operationId: Conversions_Get
export def "conversions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude conversions created before this date (YYYYMMDD)
  --created-before: string # Exclude conversions created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversions" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "status": $status, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a conversion
#
# POST /conversions
# operationId: Conversions_Put
export def "conversions update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --code: string
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
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
  let full_url = (build-url $base "/conversions" $auth.query)
  let req_body = {"code": $code, "creationDate": $creation_date, "deleted": $deleted, "description": $description, "id": $id, "name": $name, "protocol": $protocol, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this customer for a timeframe related to a subset of conversions grouped by some temporal entity (day/week/month)
#
# GET /conversions/aggregated/list
# operationId: Conversions_GetStatisticsAllList
export def "conversions-aggregated-list get-statistics-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversions/aggregated/list" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "status": $status, "groupBy": $group_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a count of conversions
#
# GET /conversions/count
# operationId: Conversions_Count
export def "conversions-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # Status of conversion ("deleted"/"active")
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude conversions created before this date (YYYYMMDD)
  --created-before: string # Exclude conversions created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/conversions/count" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete conversion specified by id
#
# DELETE /conversions/{conversionId}
# operationId: Conversions_Delete
export def "conversions delete" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve conversion specified by id
#
# GET /conversions/{conversionId}
export def "conversions get" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<code: string, creationDate: string, deleted: bool, description: string, id: int, name: string, protocol: string, value: float> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update conversion specified by id
#
# POST /conversions/{conversionId}
# operationId: Conversions_Post
export def "conversions create" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --code: string
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
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
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}") $auth.query)
  let req_body = {"code": $code, "creationDate": $creation_date, "deleted": $deleted, "description": $description, "id": $id, "name": $name, "protocol": $protocol, "value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this conversion for a timeframe
#
# GET /conversions/{conversionId}/aggregated
# operationId: Conversions_GetStatisticsSingle
export def "conversions-aggregated get-statistics-single" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --tag: string # Filter by this tag name
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}/aggregated") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "tag": $tag, "favourite": $favourite, "hourly": $hourly} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this conversion for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /conversions/{conversionId}/aggregated/list
# operationId: Conversions_GetStatisticsList
export def "conversions-aggregated-list get-statistics" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}/aggregated/list") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "groupBy": $group_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of datapoints connected to this conversion
#
# GET /conversions/{conversionId}/datapoints
# operationId: Conversions_GetDatapoints
export def "conversions-datapoints get" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Offset where to start from (format: int32)
  --limit: int # Limit results to this number (format: int32)
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tags: string # Filter by this tag name
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}/datapoints") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "type": $type, "status": $status, "tags": $tags, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modify the association between a conversion and multiple datapoints
#
# PUT /conversions/{conversionId}/datapoints/batch/patch
# --PatchRequests item shape: {Action?: string, Id?: int}
export def "conversions-datapoints-batch-patch update" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --patch-requests: list # item shape: {Action?: string, Id?: int}
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}/datapoints/batch/patch") $auth.query)
  let req_body = {"PatchRequests": $patch_requests} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a count of datapoints connected to this conversion
#
# GET /conversions/{conversionId}/datapoints/count
# operationId: Conversions_GetDatapointsCount
export def "conversions-datapoints-count get" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string # Type of datapoint ("tl"/"tp")
  --status: string # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tags: string # Filter by this tag name
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}/datapoints/count") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "status": $status, "tags": $tags, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Modify the association between a conversion and a datapoint
#
# PUT /conversions/{conversionId}/datapoints/patch
# operationId: Conversions_Patch
export def "conversions-datapoints-patch update" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string
  --id: int # format: int64
  --replace-id: int # format: int64
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}/datapoints/patch") $auth.query)
  let req_body = {"Action": $action, "Id": $id, "ReplaceId": $replace_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve the list of events related to this conversion.
#
# GET /conversions/{conversionId}/hits
# operationId: Conversions_GetHits
export def "conversions-hits get" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let qp = [(serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}/hits") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeframe": $timeframe, "limit": $limit, "offset": $offset, "fromDay": $from_day, "toDay": $to_day, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fast patch the "notes" field of a conversion
#
# PUT /conversions/{conversionId}/notes
# operationId: Conversions_PatchNotes
export def "conversions-notes update" [
  conversion_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --text: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($conversion_id | is-empty) { error make --unspanned { msg: "path parameter 'conversionId' must be non-empty" } }
  let full_url = (build-url $base ({conversion_id: (encode-path-segment $conversion_id)} | format pattern "/conversions/{conversion_id}/notes") $auth.query)
  let req_body = {"Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# List of all the datapoints associated to the user
#
# GET /datapoints
# operationId: DataPoints_Get
export def "datapoints get-data-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "onlyFavorites" $only_favorites "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datapoints" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "type": $type, "status": $status, "tags": $tags, "textSearch": $text_search, "onlyFavorites": $only_favorites, "sortBy": $sort_by, "sortDirection": $sort_direction, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a datapoint
#
# POST /datapoints
# operationId: DataPoints_Put
# --tags item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
# --typeTL shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
# --typeTP shape: {parameterNote?: string}
export def "datapoints update-data-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --encode-ip: oneof<nothing, bool>
  --fifth-conversion-id: int # format: int64
  --fifth-conversion-name: string
  --first-conversion-id: int # format: int64
  --first-conversion-name: string
  --fourth-conversion-id: int # format: int64
  --fourth-conversion-name: string
  --group-id: int # format: int64
  --group-name: string
  --id: int # format: int64
  --is-public: oneof<nothing, bool>
  --is-secured: oneof<nothing, bool>
  --light-tracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --second-conversion-id: int # format: int64
  --second-conversion-name: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --third-conversion-id: int # format: int64
  --third-conversion-name: string
  --title: string
  --tracking-code: string
  --type: string@type-completer-2
  --type-tl: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
  --type-tp: record # shape: {parameterNote?: string}
  --write-permited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datapoints" $auth.query)
  let req_body = {"creationDate": $creation_date, "encodeIp": $encode_ip, "fifthConversionId": $fifth_conversion_id, "fifthConversionName": $fifth_conversion_name, "firstConversionId": $first_conversion_id, "firstConversionName": $first_conversion_name, "fourthConversionId": $fourth_conversion_id, "fourthConversionName": $fourth_conversion_name, "groupId": $group_id, "groupName": $group_name, "id": $id, "isPublic": $is_public, "isSecured": $is_secured, "lightTracking": $light_tracking, "name": $name, "notes": $notes, "preferred": $preferred, "redirectOnly": $redirect_only, "secondConversionId": $second_conversion_id, "secondConversionName": $second_conversion_name, "status": $status, "tags": $tags, "thirdConversionId": $third_conversion_id, "thirdConversionName": $third_conversion_name, "title": $title, "trackingCode": $tracking_code, "type": $type, "typeTL": $type_tl, "typeTP": $type_tp, "writePermited": $write_permited} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this customer for a timeframe by groups
#
# GET /datapoints/aggregated
# operationId: DataPoints_GetStatisticsAggregatedSingle
export def "datapoints-aggregated list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint is marked as favourite
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "hourly" $hourly "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datapoints/aggregated" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "type": $type, "fromDay": $from_day, "toDay": $to_day, "hourly": $hourly, "status": $status, "tag": $tag, "favourite": $favourite} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about all datapoints of this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /datapoints/aggregated/list
# operationId: DataPoints_GetStatisticsAllList
export def "datapoints-aggregated-list get-data-points-statistics-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer-1 # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint is marked as favourite
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datapoints/aggregated/list" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "status": $status, "tag": $tag, "favourite": $favourite, "groupBy": $group_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete multiple datapoints
#
# DELETE /datapoints/batch
# operationId: DataPoints_BatchDelete
# --Entities item shape: {id?: int, uri?: string}
export def "datapoints-batch delete-data-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --entities: list # item shape: {id?: int, uri?: string}
]: any -> record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datapoints/batch" $auth.query)
  let req_body = {"Entities": $entities} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req $req_body $insecure $raw $allow_errors $full [200]
}

# Update multiple datapoints
#
# POST /datapoints/batch
# operationId: DataPoints_BatchPost
# --List item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, ... (8 more fields)}
export def "datapoints-batch create-data-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --list: list # item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, ... (8 more fields)}
]: any -> record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datapoints/batch" $auth.query)
  let req_body = {"List": $list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Create multiple datapoints
#
# PUT /datapoints/batch
# operationId: DataPoints_BatchPut
# --List item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, ... (8 more fields)}
export def "datapoints-batch update-data-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --list: list # item shape: {creationDate?: string, encodeIp?: bool, fifthConversionId?: int, fifthConversionName?: string, firstConversionId?: int, firstConversionName?: string, fourthConversionId?: int, fourthConversionName?: string, groupId?: int, groupName?: string, id?: int, isPublic?: bool, isSecured?: bool, lightTracking?: bool, name?: string, notes?: string, preferred?: bool, redirectOnly?: bool, secondConversionId?: int, secondConversionName?: string, status?: "Active"|"Paused"|"Abuse"|"Deleted", tags?: list, ... (8 more fields)}
]: any -> record<entityData: record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: list<record>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list, redirectType: string, referrerClean: string, scripts: list, sequentialDestinationItems: list, spilloverDestinationItems: list, uniqueDestinationItem: record, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list, urlsByNation: list, weightedDestinationItems: list>, typeTP: record<parameterNote: string>, writePermited: bool>, errors: table<code: record, errorMessage: string, errorValue: record, property: string>, result: record<id: int, uri: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/datapoints/batch" $auth.query)
  let req_body = {"List": $list} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Count the datapoints associated to the user
#
# GET /datapoints/count
# operationId: DataPoints_Count
export def "datapoints-count get-data-points" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "onlyFavorites" $only_favorites "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/datapoints/count" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "status": $status, "tags": $tags, "textSearch": $text_search, "onlyFavorites": $only_favorites, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a datapoint
#
# DELETE /datapoints/{id}
# operationId: DataPoints_Delete
export def "datapoints delete-data-points" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/datapoints/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<creationDate: string, encodeIp: bool, fifthConversionId: int, fifthConversionName: string, firstConversionId: int, firstConversionName: string, fourthConversionId: int, fourthConversionName: string, groupId: int, groupName: string, id: int, isPublic: bool, isSecured: bool, lightTracking: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, secondConversionId: int, secondConversionName: string, status: string, tags: table<datapoints: list, groups: list, id: int, name: string>, thirdConversionId: int, thirdConversionName: string, title: string, trackingCode: string, type: string, typeTL: record<appendQuery: bool, browserDestinationItem: record<emailDestinationUrl: string, mobileDestinationUrl: string, spidersDestinationUrl: string>, destinationMode: string, domainId: int, encodeUrl: bool, expirationClicks: int, expirationDate: string, firstUrl: string, goDomainId: int, hideUrl: bool, hideUrlTitle: string, isABTest: bool, password: string, pauseAfterClicksExpiration: bool, pauseAfterDateExpiration: bool, randomDestinationItems: list<record>, redirectType: string, referrerClean: string, scripts: list<record>, sequentialDestinationItems: list<record>, spilloverDestinationItems: list<record>, uniqueDestinationItem: record<firstDestinationUrl: string>, url: string, urlAfterClicksExpiration: string, urlAfterDateExpiration: string, urlsByLanguage: list<record>, urlsByNation: list<record>, weightedDestinationItems: list<record>>, typeTP: record<parameterNote: string>, writePermited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/datapoints/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a datapoint
#
# POST /datapoints/{id}
# operationId: DataPoints_Post
# --tags item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
# --typeTL shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
# --typeTP shape: {parameterNote?: string}
export def "datapoints create-data-points" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --encode-ip: oneof<nothing, bool>
  --fifth-conversion-id: int # format: int64
  --fifth-conversion-name: string
  --first-conversion-id: int # format: int64
  --first-conversion-name: string
  --fourth-conversion-id: int # format: int64
  --fourth-conversion-name: string
  --group-id: int # format: int64
  --group-name: string
  --body-id: int # format: int64
  --is-public: oneof<nothing, bool>
  --is-secured: oneof<nothing, bool>
  --light-tracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --second-conversion-id: int # format: int64
  --second-conversion-name: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --third-conversion-id: int # format: int64
  --third-conversion-name: string
  --title: string
  --tracking-code: string
  --type: string@type-completer-2
  --type-tl: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
  --type-tp: record # shape: {parameterNote?: string}
  --write-permited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/datapoints/{id}") $auth.query)
  let req_body = {"creationDate": $creation_date, "encodeIp": $encode_ip, "fifthConversionId": $fifth_conversion_id, "fifthConversionName": $fifth_conversion_name, "firstConversionId": $first_conversion_id, "firstConversionName": $first_conversion_name, "fourthConversionId": $fourth_conversion_id, "fourthConversionName": $fourth_conversion_name, "groupId": $group_id, "groupName": $group_name, "id": $body_id, "isPublic": $is_public, "isSecured": $is_secured, "lightTracking": $light_tracking, "name": $name, "notes": $notes, "preferred": $preferred, "redirectOnly": $redirect_only, "secondConversionId": $second_conversion_id, "secondConversionName": $second_conversion_name, "status": $status, "tags": $tags, "thirdConversionId": $third_conversion_id, "thirdConversionName": $third_conversion_name, "title": $title, "trackingCode": $tracking_code, "type": $type, "typeTL": $type_tl, "typeTP": $type_tp, "writePermited": $write_permited} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this datapoint for a timeframe
#
# GET /datapoints/{id}/aggregated
# operationId: DataPoints_GetStatisticsSingle
export def "datapoints-aggregated get-data-points-statistics-single" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/datapoints/{id}/aggregated") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "hourly": $hourly} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this datapoint for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /datapoints/{id}/aggregated/list
# operationId: DataPoints_GetStatisticsList
export def "datapoints-aggregated-list get-data-points-statistics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/datapoints/{id}/aggregated/list") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "groupBy": $group_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fast switch the "favourite" field of a datapoint
#
# PUT /datapoints/{id}/favourite
# operationId: DataPoints_PatchFavourite
export def "datapoints-favourite update-data-points" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/datapoints/{id}/favourite") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve the list of events related to this datapoint.
#
# GET /datapoints/{id}/hits
# operationId: DataPoints_GetHits
export def "datapoints-hits get-data-points" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/datapoints/{id}/hits") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeframe": $timeframe, "limit": $limit, "offset": $offset, "fromDay": $from_day, "toDay": $to_day, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fast patch the "notes" field of a datapoint
#
# PUT /datapoints/{id}/notes
# operationId: DataPoints_PatchNotes
export def "datapoints-notes update-data-points" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --text: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/datapoints/{id}/notes") $auth.query)
  let req_body = {"Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve a list of domains
#
# GET /domains
# operationId: Domains_Get
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/domains" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "type": $type, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a domain
#
# POST /domains
# operationId: Domains_Put
export def "domains update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom404: string
  --custom-homepage: string
  --id: int # format: int64
  --name: string
  --type: string@type-completer-4
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/domains" $auth.query)
  let req_body = {"custom404": $custom404, "customHomepage": $custom_homepage, "id": $id, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve count of domains
#
# GET /domains/count
# operationId: Domains_Count
export def "domains-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-3 # Type of domain ("system"/"go"/"personal"/"dedicated"). If not specified default is "system" (default: system)
  --name: string # Filter domains with this anmen
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/domains/count" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "name": $name} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a domain
#
# DELETE /domains/{id}
# operationId: Domains_Delete
export def "domains delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/domains/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<custom404: string, customHomepage: string, id: int, name: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/domains/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a domain
#
# POST /domains/{id}
# operationId: Domains_Update
export def "domains update-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --custom404: string
  --custom-homepage: string
  --body-id: int # format: int64
  --name: string
  --type: string@type-completer-4
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/domains/{id}") $auth.query)
  let req_body = {"custom404": $custom404, "customHomepage": $custom_homepage, "id": $body_id, "name": $name, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List of all the groups associated to the user.
#
# GET /groups
# operationId: Groups_Get
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer # Status of the group
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude groups created before this date (YYYYMMDD)
  --created-before: string # Exclude groups created after this date (YYYYMMDD)
  --write: oneof<nothing, bool> # Write permission
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "write" $write "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "status": $status, "tags": $tags, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before, "write": $write} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a group
#
# POST /groups
# operationId: Groups_Put
# --tags item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
export def "groups update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --id: int # format: int64
  --is-public: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --write-permited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/groups" $auth.query)
  let req_body = {"creationDate": $creation_date, "deleted": $deleted, "id": $id, "isPublic": $is_public, "name": $name, "notes": $notes, "preferred": $preferred, "redirectOnly": $redirect_only, "tags": $tags, "writePermited": $write_permited} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this customer for a timeframe by groups
#
# GET /groups/aggregated
# operationId: Groups_GetStatisticsAggregatedSingle
export def "groups-aggregated list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
  --status: string@status-completer # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group is marked as favourite
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "hourly" $hourly "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/aggregated" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "hourly": $hourly, "status": $status, "tag": $tag, "favourite": $favourite} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about all groups of this customer for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /groups/aggregated/list
# operationId: Groups_GetStatisticsAllList
export def "groups-aggregated-list get-statistics-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string # Status of group ("deleted"/"active")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the group is marked as favourite
  --group-by: string@group-by-completer-1 # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/aggregated/list" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "status": $status, "tag": $tag, "favourite": $favourite, "groupBy": $group_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Count the groups associated to the user.
#
# GET /groups/count
# operationId: Groups_Count
export def "groups-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude groups created before this date (YYYYMMDD)
  --created-before: string # Exclude groups created after this date (YYYYMMDD)
  --write: oneof<nothing, bool> # Write permission
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar") (serialize-qp "write" $write "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/count" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "tags": $tags, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before, "write": $write} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete group specified by id
#
# DELETE /groups/{id}
# operationId: Groups_Delete
export def "groups delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<creationDate: string, deleted: bool, id: int, isPublic: bool, name: string, notes: string, preferred: bool, redirectOnly: bool, tags: table<datapoints: list, groups: list, id: int, name: string>, writePermited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Update a group
#
# POST /groups/{id}
# operationId: Groups_Post
# --tags item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
export def "groups create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --deleted: oneof<nothing, bool>
  --body-id: int # format: int64
  --is-public: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --write-permited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}") $auth.query)
  let req_body = {"creationDate": $creation_date, "deleted": $deleted, "id": $body_id, "isPublic": $is_public, "name": $name, "notes": $notes, "preferred": $preferred, "redirectOnly": $redirect_only, "tags": $tags, "writePermited": $write_permited} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this group for a timeframe
#
# GET /groups/{id}/aggregated
# operationId: Groups_GetStatisticsSingle
export def "groups-aggregated get-statistics-single" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --hourly: oneof<nothing, bool> # If using "yesterday" or "today" timeframe you can ask for the hourly detail
]: nothing -> record<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "hourly" $hourly "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/aggregated") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "hourly": $hourly} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about this group for a timeframe grouped by some temporal entity (day/week/month)
#
# GET /groups/{id}/aggregated/list
# operationId: Groups_GetStatisticsList
export def "groups-aggregated-list get-statistics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --group-by: string@group-by-completer # The temporal entity you want to group by ("week"/"month"). If unspecified is "day".
]: nothing -> record<entities: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "groupBy" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/aggregated/list") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "fromDay": $from_day, "toDay": $to_day, "groupBy": $group_by} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve statistics about a subset of datapoints for a timeframe with datapoints data
#
# GET /groups/{id}/aggregated/summary
# operationId: Groups_GetDatapointsSummary
export def "groups-aggregated-summary get-datapoints" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --time-frame: string@time-frame-completer # Timeframe of the request. See list at $timeframeList
  --type: string@type-completer-1 # Type of datapoint ("tl"/"tp")
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --status: string@status-completer # Status of datapoint ("deleted"/"active"/"paused"/"spam")
  --tag: string # A comma separated list of tags you want to filter with.
  --favourite: oneof<nothing, bool> # Is the datapoint marked as favourite
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --offset: int # Offset where to start from (format: int32, default: 0)
  --limit: int # Limit results to this number (format: int32, default: 20)
  --text-search: string # Filter fields by this pattern
]: nothing -> record<count: int, limit: int, offset: int, result: table<activityDay: string, commissionsCost: float, conversionsCost: float, conversionsValue: float, convertedClicks: int, entityData: record, entityId: string, fromDay: string, hourlyBreakDown: record, lastHitDate: string, spiderHitsCount: int, toDay: string, totalClicks: int, totalViews: int, uniqueClicks: int, uniqueConversions: int, uniqueViews: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timeFrame" $time_frame "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "favourite" $favourite "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "textSearch" $text_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/aggregated/summary") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeFrame": $time_frame, "type": $type, "fromDay": $from_day, "toDay": $to_day, "status": $status, "tag": $tag, "favourite": $favourite, "sortBy": $sort_by, "sortDirection": $sort_direction, "offset": $offset, "limit": $limit, "textSearch": $text_search} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List of all the datapoints associated to the user in this group.
#
# GET /groups/{id}/datapoints
# operationId: Groups_GetDatapoints
export def "groups-datapoints get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "onlyFavorites" $only_favorites "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/datapoints") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "type": $type, "status": $status, "tags": $tags, "textSearch": $text_search, "onlyFavorites": $only_favorites, "sortBy": $sort_by, "sortDirection": $sort_direction, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a datapoint in this group
#
# POST /groups/{id}/datapoints
# operationId: Groups_PutDatapoint
# --tags item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
# --typeTL shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
# --typeTP shape: {parameterNote?: string}
export def "groups-datapoints update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --creation-date: string # (A date in "YmdHis" format) (e.g. 20120203120530)
  --encode-ip: oneof<nothing, bool>
  --fifth-conversion-id: int # format: int64
  --fifth-conversion-name: string
  --first-conversion-id: int # format: int64
  --first-conversion-name: string
  --fourth-conversion-id: int # format: int64
  --fourth-conversion-name: string
  --group-id: int # format: int64
  --group-name: string
  --body-id: int # format: int64
  --is-public: oneof<nothing, bool>
  --is-secured: oneof<nothing, bool>
  --light-tracking: oneof<nothing, bool>
  --name: string
  --notes: string
  --preferred: oneof<nothing, bool>
  --redirect-only: oneof<nothing, bool>
  --second-conversion-id: int # format: int64
  --second-conversion-name: string
  --status: string@status-completer-2
  --tags: list # item shape: {datapoints?: list<int>, groups?: list<int>, id?: int, name?: string}
  --third-conversion-id: int # format: int64
  --third-conversion-name: string
  --title: string
  --tracking-code: string
  --type: string@type-completer-2
  --type-tl: record # shape: {appendQuery?: bool, browserDestinationItem?: record, destinationMode?: "Simple"|"RandomDestination"|"DestinationByLanguage"|"SpilloverDestination"|"DynamicUrl"|"BrowserDestination"|"DestinationByNation"|"UniqueDestination"|"SequentialDestination"|"WeightedDestination", domainId?: int, encodeUrl?: bool, expirationClicks?: int, expirationDate?: string, firstUrl?: string, goDomainId?: int, hideUrl?: bool, hideUrlTitle?: string, isABTest?: bool, password?: string, pauseAfterClicksExpiration?: bool, ... (14 more fields)}
  --type-tp: record # shape: {parameterNote?: string}
  --write-permited: oneof<nothing, bool>
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/datapoints") $auth.query)
  let req_body = {"creationDate": $creation_date, "encodeIp": $encode_ip, "fifthConversionId": $fifth_conversion_id, "fifthConversionName": $fifth_conversion_name, "firstConversionId": $first_conversion_id, "firstConversionName": $first_conversion_name, "fourthConversionId": $fourth_conversion_id, "fourthConversionName": $fourth_conversion_name, "groupId": $group_id, "groupName": $group_name, "id": $body_id, "isPublic": $is_public, "isSecured": $is_secured, "lightTracking": $light_tracking, "name": $name, "notes": $notes, "preferred": $preferred, "redirectOnly": $redirect_only, "secondConversionId": $second_conversion_id, "secondConversionName": $second_conversion_name, "status": $status, "tags": $tags, "thirdConversionId": $third_conversion_id, "thirdConversionName": $third_conversion_name, "title": $title, "trackingCode": $tracking_code, "type": $type, "typeTL": $type_tl, "typeTP": $type_tp, "writePermited": $write_permited} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Count the datapoints associated to the user in this group.
#
# GET /groups/{id}/datapoints/count
# operationId: Groups_GetDatapointsCount
export def "groups-datapoints-count get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "onlyFavorites" $only_favorites "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/datapoints/count") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "status": $status, "tags": $tags, "textSearch": $text_search, "onlyFavorites": $only_favorites, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fast switch the "favourite" field of a group
#
# PUT /groups/{id}/favourite
# operationId: Groups_PatchFavourite
export def "groups-favourite update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/favourite") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve the list of events related to this group.
#
# GET /groups/{id}/hits
# operationId: Groups_GetHits
export def "groups-hits get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/hits") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeframe": $timeframe, "limit": $limit, "offset": $offset, "fromDay": $from_day, "toDay": $to_day, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Fast patch the "notes" field of a group
#
# PUT /groups/{id}/notes
# operationId: Groups_PatchNotes
export def "groups-notes update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --text: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/groups/{id}/notes") $auth.query)
  let req_body = {"Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve the list of events related to this account.
#
# GET /hits
# operationId: Hits_GetHits
export def "hits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --timeframe: string@timeframe-completer # Timeframe of the request. See list at $timeframeList
  --limit: int # Limit results to this number (format: int32)
  --offset: string # Offset where to start from (it's the lastKey field in the response object)
  --from-day: string # If using a "custom" timeFrame you can specify the starting day (YYYYMMDD)
  --to-day: string # If using a "custom" timeFrame you can specify the ending day (YYYYMMDD)
  --filter: string@filter-completer-1 # Filter event type ("spiders"/"uniques"/"nonuniques"/"conversions")
]: nothing -> record<hits: table<accessTime: string, browser: record, clientLanguage: string, conversion1: record, conversion2: record, conversion3: record, conversion4: record, conversion5: record, conversions: list, entity: record, ip: string, isProxy: string, isSpider: string, isUnique: string, location: record, org: string, os: record, queryParams: string, realDestinationUrl: string, referer: string, source: record, type: string>, lastKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "timeframe" $timeframe "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fromDay" $from_day "scalar") (serialize-qp "toDay" $to_day "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hits" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"timeframe": $timeframe, "limit": $limit, "offset": $offset, "fromDay": $from_day, "toDay": $to_day, "filter": $filter} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve current account data
#
# GET /me
# operationId: Me_GetMe
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<boGoVal: string, bonusClicks: int, companyName: string, companyRole: string, email: string, firstName: string, lastName: string, phone: string, redirectOnly: bool, registrationDate: string, timeframeMinDate: string, timezone: int, timezonename: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieve current account plan
#
# GET /me/plan
# operationId: Me_GetMePlan
export def "me-plan get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<allowedPersonalDomains: int, allowedPersonalUrls: int, billingPeriodEnd: string, billingPeriodStart: string, bonusMonthlyEvents: int, maximumDatapoints: int, maximumGuests: int, monthlyEvents: int, name: string, price: float, profileId: int, recurring: bool, recurringPeriod: int, usedDatapoints: int, usedMonthlyEvents: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me/plan" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List of all the retargeting scripts associated to the user
#
# GET /retargeting
# operationId: Retargeting_Get
export def "retargeting list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/retargeting" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Creates a retargeting script
#
# POST /retargeting
# operationId: Retargeting_Put
export def "retargeting update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --id: int # format: int64
  --name: string
  --script: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retargeting" $auth.query)
  let req_body = {"id": $id, "name": $name, "script": $script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Retrieve count of retargeting scripts
#
# GET /retargeting/count
# operationId: Retargeting_Count
export def "retargeting-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/retargeting/count" $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Deletes a retargeting script (and remove associations)
#
# DELETE /retargeting/{id}
# operationId: Retargeting_Delete
export def "retargeting delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/retargeting/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, name: string, script: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/retargeting/{id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Updates a retargeting script
#
# POST /retargeting/{id}
# operationId: Retargeting_Post
export def "retargeting create" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --body-id: int # format: int64
  --name: string
  --script: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/retargeting/{id}") $auth.query)
  let req_body = {"id": $body_id, "name": $name, "script": $script} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List of all the datapoints associated to the retargeting script.
#
# GET /retargeting/{id}/datapoints
# operationId: Retargeting_GetDatapoints
export def "retargeting-datapoints get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --sort-by: string # Field to sort by
  --sort-direction: string@sort-direction-completer # Direction of sort "asc" or "desc"
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "onlyFavorites" $only_favorites "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortDirection" $sort_direction "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/retargeting/{id}/datapoints") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "status": $status, "tags": $tags, "textSearch": $text_search, "onlyFavorites": $only_favorites, "sortBy": $sort_by, "sortDirection": $sort_direction, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Count the datapoints associated to the retargeting script.
#
# GET /retargeting/{id}/datapoints/count
# operationId: Retargeting_GetDatapointsCount
export def "retargeting-datapoints-count get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer-1 # Status of the datapoint
  --tags: string # A comma separated list of tags you want to filter with.
  --text-search: string # Filter fields by this pattern
  --only-favorites: oneof<nothing, bool> # Filter fields by favourite status
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "tags" $tags "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "onlyFavorites" $only_favorites "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/retargeting/{id}/datapoints/count") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "tags": $tags, "textSearch": $text_search, "onlyFavorites": $only_favorites, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags
# operationId: Tags_Get
export def "tags list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/tags" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "name": $name, "datapoints": $datapoints, "groups": $groups, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create a tag
#
# POST /tags
# operationId: Tags_Put
export def "tags update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --datapoints: list<int>
  --groups: list<int>
  --id: int # format: int64
  --name: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tags" $auth.query)
  let req_body = {"datapoints": $datapoints, "groups": $groups, "id": $id, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags/count
# operationId: Tags_Count
export def "tags-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/tags/count" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "datapoints": $datapoints, "groups": $groups, "type": $type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a tag
#
# DELETE /tags/{tagId}
# operationId: Tags_Delete
export def "tags delete" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# Retrieve a tag
#
# GET /tags/{tagId}
export def "tags get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
]: nothing -> record<datapoints: list<int>, groups: list<int>, id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete the association of this tag with all datapoints
#
# DELETE /tags/{tagId}/datapoints
# operationId: Tags_DeleteRelatedDatapoints
export def "tags-datapoints delete-related" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/datapoints") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# List of all the datapoints associated to the user filtered by this tag
#
# GET /tags/{tagId}/datapoints
# operationId: Tags_GetDatapoints
export def "tags-datapoints get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/datapoints") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "type": $type, "status": $status, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Count the datapoints associated to the user filtered by this tag
#
# GET /tags/{tagId}/datapoints/count
# operationId: Tags_GetDatapointsCount
export def "tags-datapoints-count get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --type: string@type-completer-1 # Type of the datapoint ("tp"/"tl")
  --status: string@status-completer-1 # Status of the datapoint
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude datapoints created before this date (YYYYMMDD)
  --created-before: string # Exclude datapoints created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/datapoints/count") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "status": $status, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Associate/Deassociate a tag with a datapoint
#
# PUT /tags/{tagId}/datapoints/patch
# operationId: Tags_PatchDataPoint
export def "tags-datapoints-patch update-data-point" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string
  --id: int # format: int64
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/datapoints/patch") $auth.query)
  let req_body = {"Action": $action, "Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Delete the association of this tag with all groups
#
# DELETE /tags/{tagId}/groups
# operationId: Tags_DeleteRelatedGroups
export def "tags-groups delete-related" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
]: nothing -> record<id: int, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/groups") $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [200]
}

# List of all the groups associated to the user filtered by this tag.
#
# GET /tags/{tagId}/groups
# operationId: Tags_GetGroups
export def "tags-groups get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --offset: int # Where to start when retrieving elements. Default is 0 if not specified. (format: int32, default: 0)
  --limit: int # Maximum elements to retrieve. Default to 20 if not specified. (format: int32, default: 20)
  --status: string@status-completer # Status of the datapoint
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude groups created before this date (YYYYMMDD)
  --created-before: string # Exclude groups created after this date (YYYYMMDD)
]: nothing -> record<entities: table<id: int, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/groups") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"offset": $offset, "limit": $limit, "status": $status, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Count the groups associated to the user filtered by this tag
#
# GET /tags/{tagId}/groups/count
# operationId: Tags_GetGroupsCount
export def "tags-groups-count get" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --status: string@status-completer # Status of the datapoint
  --text-search: string # Filter fields by this pattern
  --created-after: string # Exclude groups created before this date (YYYYMMDD)
  --created-before: string # Exclude groups created after this date (YYYYMMDD)
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "textSearch" $text_search "scalar") (serialize-qp "createdAfter" $created_after "scalar") (serialize-qp "createdBefore" $created_before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/groups/count") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"status": $status, "textSearch": $text_search, "createdAfter": $created_after, "createdBefore": $created_before} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Associate/Deassociate a tag with a group
#
# PUT /tags/{tagId}/groups/patch
# operationId: Tags_PatchGroup
export def "tags-groups-patch update" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --action: string
  --id: int # format: int64
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/groups/patch") $auth.query)
  let req_body = {"Action": $action, "Id": $id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Fast patch a tag name
#
# PUT /tags/{tagId}/name
# operationId: Tags_PatchTagName
export def "tags-name update" [
  tag_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --text: string
]: any -> record<id: int, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-clickmeter-authkey"))
  let base = ($base_url | default $BASE_URL)
  if ($tag_id | is-empty) { error make --unspanned { msg: "path parameter 'tagId' must be non-empty" } }
  let full_url = (build-url $base ({tag_id: (encode-path-segment $tag_id)} | format pattern "/tags/{tag_id}/name") $auth.query)
  let req_body = {"Text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}
