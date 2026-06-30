# Auto-generated client for Visual Crossing Weather API v4.6
# Source: https://api.apis.guru/v2/specs/visualcrossing.com/weather/4.6/openapi.json
# Auth: --token flag or $env.VISUAL_CROSSING_WEATHER_API_TOKEN

const BASE_URL = "https://weather.visualcrossing.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o VISUAL_CROSSING_WEATHER_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://weather.visualcrossing.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "visual-crossing-web-services-rest-services-timeline get-by-location" } } | get name | first)
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

# Historical and Forecast Weather API
#
# GET /VisualCrossingWebServices/rest/services/timeline/{location}
export def "visual-crossing-web-services-rest-services-timeline get-by-location" [
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # data format of the output either json or CSV (e.g. json)
  --unit-group: string # e.g. us
  --include: string # data to include in the output (required for CSV format - days,hours,alerts,current,events ) (e.g. days)
  --lang: string # Language to use for weather descriptions (e.g. us)
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  let qp = [(serialize-qp "contentType" $content_type "scalar") (serialize-qp "unitGroup" $unit_group "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: (encode-path-segment $location)} | format pattern "/VisualCrossingWebServices/rest/services/timeline/{location}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"contentType": $content_type, "unitGroup": $unit_group, "include": $include, "lang": $lang, "key": $key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Historical and Forecast Weather API
#
# GET /VisualCrossingWebServices/rest/services/timeline/{location}/{startdate}
export def "visual-crossing-web-services-rest-services-timeline get-by-location-startdate" [
  location: string
  startdate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # data format of the output either json or CSV (e.g. json)
  --unit-group: string # e.g. us
  --include: string # data to include in the output (required for CSV format - days,hours,alerts,current,events ) (e.g. days)
  --lang: string # Language to use for weather descriptions (e.g. us)
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($startdate | is-empty) { error make --unspanned { msg: "path parameter 'startdate' must be non-empty" } }
  let qp = [(serialize-qp "contentType" $content_type "scalar") (serialize-qp "unitGroup" $unit_group "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: (encode-path-segment $location), startdate: (encode-path-segment $startdate)} | format pattern "/VisualCrossingWebServices/rest/services/timeline/{location}/{startdate}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"contentType": $content_type, "unitGroup": $unit_group, "include": $include, "lang": $lang, "key": $key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Historical and Forecast Weather API
#
# GET /VisualCrossingWebServices/rest/services/timeline/{location}/{startdate}/{enddate}
export def "visual-crossing-web-services-rest-services-timeline get-by-location-startdate-enddate" [
  location: string
  startdate: string
  enddate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-type: string # data format of the output either json or CSV (e.g. json)
  --unit-group: string # e.g. us
  --include: string # data to include in the output (required for CSV format - days,hours,alerts,current,events ) (e.g. days)
  --lang: string # Language to use for weather descriptions (e.g. us)
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  if ($location | is-empty) { error make --unspanned { msg: "path parameter 'location' must be non-empty" } }
  if ($startdate | is-empty) { error make --unspanned { msg: "path parameter 'startdate' must be non-empty" } }
  if ($enddate | is-empty) { error make --unspanned { msg: "path parameter 'enddate' must be non-empty" } }
  let qp = [(serialize-qp "contentType" $content_type "scalar") (serialize-qp "unitGroup" $unit_group "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({location: (encode-path-segment $location), startdate: (encode-path-segment $startdate), enddate: (encode-path-segment $enddate)} | format pattern "/VisualCrossingWebServices/rest/services/timeline/{location}/{startdate}/{enddate}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"contentType": $content_type, "unitGroup": $unit_group, "include": $include, "lang": $lang, "key": $key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Weather Forecast API
#
# GET /VisualCrossingWebServices/rest/services/weatherdata/forecast
export def "visual-crossing-web-services-rest-services-weatherdata-forecast get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --send-as-datasource: oneof<nothing, bool> # e.g. false
  --allow-asynch: oneof<nothing, bool> # e.g. false
  --short-column-names: oneof<nothing, bool> # e.g. false
  --locations: string # e.g. Sterling%2C%20VA%2C%20US
  --aggregate-hours: string # e.g. 24
  --content-type: string # e.g. json
  --unit-group: string # e.g. us
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  let qp = [(serialize-qp "sendAsDatasource" $send_as_datasource "scalar") (serialize-qp "allowAsynch" $allow_asynch "scalar") (serialize-qp "shortColumnNames" $short_column_names "scalar") (serialize-qp "locations" $locations "scalar") (serialize-qp "aggregateHours" $aggregate_hours "scalar") (serialize-qp "contentType" $content_type "scalar") (serialize-qp "unitGroup" $unit_group "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/VisualCrossingWebServices/rest/services/weatherdata/forecast" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sendAsDatasource": $send_as_datasource, "allowAsynch": $allow_asynch, "shortColumnNames": $short_column_names, "locations": $locations, "aggregateHours": $aggregate_hours, "contentType": $content_type, "unitGroup": $unit_group, "key": $key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Retrieves hourly or daily historical weather records.
#
# GET /VisualCrossingWebServices/rest/services/weatherdata/history
export def "visual-crossing-web-services-rest-services-weatherdata-history get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --max-distance: string # e.g. -1
  --short-column-names: oneof<nothing, bool> # e.g. false
  --end-date-time: string # e.g. 2020-02-04T00%3A00%3A00
  --aggregate-hours: string # e.g. 24
  --collect-station-contributions: oneof<nothing, bool> # e.g. false
  --start-date-time: string # e.g. 2020-01-28T00%3A00%3A00
  --max-stations: string # e.g. -1
  --allow-asynch: oneof<nothing, bool> # e.g. false
  --locations: string # e.g. Sterling%2C%20VA%2C%20US
  --include-normals: oneof<nothing, bool> # e.g. false
  --content-type: string # e.g. json
  --unit-group: string # e.g. us
  --key: string # e.g. INSERT_YOUR_KEY
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default "https://weather.visualcrossing.com")
  let qp = [(serialize-qp "maxDistance" $max_distance "scalar") (serialize-qp "shortColumnNames" $short_column_names "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "aggregateHours" $aggregate_hours "scalar") (serialize-qp "collectStationContributions" $collect_station_contributions "scalar") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "maxStations" $max_stations "scalar") (serialize-qp "allowAsynch" $allow_asynch "scalar") (serialize-qp "locations" $locations "scalar") (serialize-qp "includeNormals" $include_normals "scalar") (serialize-qp "contentType" $content_type "scalar") (serialize-qp "unitGroup" $unit_group "scalar") (serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/VisualCrossingWebServices/rest/services/weatherdata/history" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"maxDistance": $max_distance, "shortColumnNames": $short_column_names, "endDateTime": $end_date_time, "aggregateHours": $aggregate_hours, "collectStationContributions": $collect_station_contributions, "startDateTime": $start_date_time, "maxStations": $max_stations, "allowAsynch": $allow_asynch, "locations": $locations, "includeNormals": $include_normals, "contentType": $content_type, "unitGroup": $unit_group, "key": $key} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
