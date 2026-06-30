# Auto-generated client for Highways England API vv1
# Source: https://api.apis.guru/v2/specs/highwaysengland.co.uk/v1/openapi.json
# Auth: --token flag or $env.HIGHWAYS_ENGLAND_API_TOKEN

const BASE_URL = "https://webtris.highwaysengland.co.uk/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o HIGHWAYS_ENGLAND_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
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

def base-url-completer [] { ["https://webtris.highwaysengland.co.uk/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "vversion-areas list" } } | get name | first)
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

# Returns list of areas
#
# GET /v{version}/areas
# operationId: Areas_Get
export def "vversion-areas list" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<areas: table<Description: string, Id: string, Name: string, XLatitude: string, XLongitude: string, YLatitude: string, YLongitude: string>, row_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({version: (encode-path-segment $version)} | format pattern "/v{version}/areas") $auth.query)
  let accept_val = "application/json"
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

# Returns details of selected area
#
# GET /v{version}/areas/{area_Ids}
export def "vversion-areas get" [
  version: string
  area_ids: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<areas: table<Description: string, Id: string, Name: string, XLatitude: string, XLongitude: string, YLatitude: string, YLongitude: string>, row_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  if ($area_ids | is-empty) { error make --unspanned { msg: "path parameter 'area_Ids' must be non-empty" } }
  let full_url = (build-url $base ({version: (encode-path-segment $version), area_ids: (encode-path-segment $area_ids)} | format pattern "/v{version}/areas/{area_ids}") $auth.query)
  let accept_val = "application/json"
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

# Get Site DailyQuality
#
# GET /v{version}/quality/daily
# operationId: Quality_GetDailyDataQualityForSite
export def "vversion-quality-daily get-data-for-site" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --site-id: string
  --start-date: string # The start date of the report in the format ddmmyyyy (i.e 31012016)
  --end-date: string # The end date of the report in the format ddmmyyyy (i.e 31012016)
]: nothing -> record<Qualities: table<Date: string, Quality: int>, row_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let qp = [(serialize-qp "siteId" $site_id "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version: (encode-path-segment $version)} | format pattern "/v{version}/quality/daily") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"siteId": $site_id, "start_date": $start_date, "end_date": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Site OverallQuality
#
# GET /v{version}/quality/overall
# operationId: Quality_GetOverallDataQualityForSites
export def "vversion-quality-overall get-data-for-sites" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sites: string # Get site quality by site id delimited by ,
  --start-date: string # The start date of the report in the format ddmmyyyy (i.e 31012016)
  --end-date: string # The end date of the report in the format ddmmyyyy (i.e 31012016)
]: nothing -> record<data_quality: int, end_date: string, row_count: int, sites: string, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let qp = [(serialize-qp "sites" $sites "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version: (encode-path-segment $version)} | format pattern "/v{version}/quality/overall") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sites": $sites, "start_date": $start_date, "end_date": $end_date} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the daily report.
#
# GET /v{version}/reports/{report_type}
# operationId: Reports_Index
export def "vversion-reports get-index" [
  version: string
  report_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sites: string # Comma separated list of site Ids.
  --start-date: string # The start date of the report in the format ddmmyyyy (i.e 31012016)
  --end-date: string # The end date of the report in the format ddmmyyyy (i.e 31012016)
  --page: int # The page offset to return. (format: int32)
  --page-size: int # The number of rows to return. (format: int32)
  --report-sub-type-id: int # format: int32
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  if ($report_type | is-empty) { error make --unspanned { msg: "path parameter 'report_type' must be non-empty" } }
  let qp = [(serialize-qp "sites" $sites "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "reportSubTypeId" $report_sub_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version: (encode-path-segment $version), report_type: (encode-path-segment $report_type)} | format pattern "/v{version}/reports/{report_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sites": $sites, "start_date": $start_date, "end_date": $end_date, "page": $page, "page_size": $page_size, "reportSubTypeId": $report_sub_type_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Gets the daily report.
#
# GET /v{version}/reports/{start_date}/to/{end_date}/{report_type}
export def "vversion-reports-to get" [
  version: string
  start_date: string
  end_date: string
  report_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sites: string # Comma separated list of site Ids.
  --page: int # The page offset to return. (format: int32)
  --page-size: int # The number of rows to return. (format: int32)
  --report-sub-type-id: int # format: int32
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  if ($start_date | is-empty) { error make --unspanned { msg: "path parameter 'start_date' must be non-empty" } }
  if ($end_date | is-empty) { error make --unspanned { msg: "path parameter 'end_date' must be non-empty" } }
  if ($report_type | is-empty) { error make --unspanned { msg: "path parameter 'report_type' must be non-empty" } }
  let qp = [(serialize-qp "sites" $sites "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "reportSubTypeId" $report_sub_type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({version: (encode-path-segment $version), start_date: (encode-path-segment $start_date), end_date: (encode-path-segment $end_date), report_type: (encode-path-segment $report_type)} | format pattern "/v{version}/reports/{start_date}/to/{end_date}/{report_type}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sites": $sites, "page": $page, "page_size": $page_size, "reportSubTypeId": $report_sub_type_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a list of sites
#
# GET /v{version}/sites
# operationId: Sites_Index
export def "vversion-sites get-index" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<row_count: int, sites: table<Description: string, Id: string, Latitude: float, Longitude: float, Name: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({version: (encode-path-segment $version)} | format pattern "/v{version}/sites") $auth.query)
  let accept_val = "application/json"
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

# Get selected sites
#
# GET /v{version}/sites/{site_Ids}
export def "vversion-sites get" [
  version: string
  site_ids: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<row_count: int, sites: table<Description: string, Id: string, Latitude: float, Longitude: float, Name: string, Status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  if ($site_ids | is-empty) { error make --unspanned { msg: "path parameter 'site_Ids' must be non-empty" } }
  let full_url = (build-url $base ({version: (encode-path-segment $version), site_ids: (encode-path-segment $site_ids)} | format pattern "/v{version}/sites/{site_ids}") $auth.query)
  let accept_val = "application/json"
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

# Return list of site types
#
# GET /v{version}/sitetypes
# operationId: SiteTypes_Index
export def "vversion-sitetypes get-site-types-index" [
  version: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<row_count: int, sitetypes: table<Description: string, Id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  let full_url = (build-url $base ({version: (encode-path-segment $version)} | format pattern "/v{version}/sitetypes") $auth.query)
  let accept_val = "application/json"
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

# Returns the layer metadata for the LayerId specified.
#
# GET /v{version}/sitetypes/{siteType_Id}/sites
# operationId: SiteTypes_GetSitesForPublicFacingAPI
export def "vversion-sitetypes-sites get-types-for-public-facing" [
  version: string
  site_type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<Sites: table<Active: list, Description: list, Id: list, Lattitude: list, Longitude: list, SiteId: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($version | is-empty) { error make --unspanned { msg: "path parameter 'version' must be non-empty" } }
  if ($site_type_id | is-empty) { error make --unspanned { msg: "path parameter 'siteType_Id' must be non-empty" } }
  let full_url = (build-url $base ({version: (encode-path-segment $version), site_type_id: (encode-path-segment $site_type_id)} | format pattern "/v{version}/sitetypes/{site_type_id}/sites") $auth.query)
  let accept_val = "application/json"
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
