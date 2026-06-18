# Auto-generated client for api.video v1
# Source: https://api.apis.guru/v2/specs/api.video/1/openapi.json
# Auth: --token flag or $env.API_VIDEO_TOKEN

const BASE_URL = "https://ws.api.video"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_VIDEO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://ws.api.video"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-order-completer [] { ["asc" "desc"] }
def sort-by-completer [] { ["createdAt" "updatedAt"] }
def sort-by-completer-1 [] { ["createdAt" "ttl"] }

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

# Show account
#
# GET /account
# DEPRECATED
# operationId: GET_account
@deprecated
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
]: nothing -> record<environment: string, features: list<string>, quota: record<quotaRemaining: float, quotaTotal: float, quotaUsed: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List live stream player sessions
#
# GET /analytics/live-streams/{liveStreamId}
# operationId: GET_analytics-live-streams-liveStreamId
export def "analytics-live-streams get" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string # Period must have one of the following formats: - For a day : "2018-01-01", - For a week: "2018-W01", - For a month: "2018-01" - For a year: "2018" For a range period: - Date range: "2018-01-01/2018-01-15" (format: period, e.g. 2019-01-01)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<client: record, device: record, location: record, os: record, referrer: record, session: record>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar") (serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({live_stream_id: (encode-path-segment $live_stream_id)} | format pattern "/analytics/live-streams/{live_stream_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List player session events
#
# GET /analytics/sessions/{sessionId}/events
# operationId: GET_analytics-sessions-sessionId-events
export def "analytics-sessions-events get" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<at: int, emittedAt: string, from: int, to: int, type: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/analytics/sessions/{session_id}/events") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List video player sessions
#
# GET /analytics/videos/{videoId}
# operationId: GET_analytics-videos-videoId
export def "analytics-videos get" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string # Period must have one of the following formats: - For a day : 2018-01-01, - For a week: 2018-W01, - For a month: 2018-01 - For a year: 2018 For a range period: - Date range: 2018-01-01/2018-01-15 (format: period)
  --metadata: list<string> # Metadata and [Dynamic Metadata](https://api.video/blog/endpoints/dynamic-metadata) filter. Send an array of key value pairs you want to filter sessios with. (e.g. [{"key": "Author", "value": "John Doe"}, {"key": "Format", "value": "Tutorial"}])
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<client: record, device: record, location: record, os: record, referrer: record, session: record>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar") (serialize-qp "metadata" $metadata "multi") (serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/analytics/videos/{video_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Authenticate
#
# POST /auth/api-key
# operationId: POST_auth-api-key
export def "auth-api-key create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  api_key: string # Your account API key. You can use your sandbox API key, or you can use your production API key.
]: any -> record<access_token: string, expires_in: int, refresh_token: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/api-key")
  let req_body = {"apiKey": $api_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Refresh token
#
# POST /auth/refresh
# operationId: POST_auth-refresh
export def "auth-refresh create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  refresh_token: string # The refresh token is either the first refresh token you received when you authenticated with the auth/api-key endpoint, or it's the refresh token from the last time you used the auth/refresh endpoint. Place this in the body of your request to obtain a new access token (which is valid for an hour) and a new refresh token.
]: any -> record<access_token: string, expires_in: int, refresh_token: string, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/refresh")
  let req_body = {"refreshToken": $refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List all live streams
#
# GET /live-streams
# operationId: GET_live-streams
export def "live-streams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stream-key: string # The unique stream key that allows you to stream videos. (e.g. 30087931-229e-42cf-b5f9-e91bcc1f7332)
  --name: string # You can filter live streams by their name or a part of their name. (e.g. My Video)
  --sort-by: string # Allowed: createdAt, publishedAt, name. createdAt - the time a livestream was created using the specified streamKey. publishedAt - the time a livestream was published using the specified streamKey. name - the name of the livestream. If you choose one of the time based options, the time is presented in ISO-8601 format. (e.g. createdAt)
  --sort-order: string@sort-order-completer # Allowed: asc, desc. Ascending for date and time means that earlier values precede later ones. Descending means that later values preced earlier ones. For title, it is 0-9 and A-Z ascending and Z-A, 9-0 descending. (e.g. desc)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<assets: record, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "streamKey" $stream_key "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/live-streams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create live stream
#
# POST /live-streams
# operationId: POST_live-streams
export def "live-streams create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Add a name for your live stream here. (e.g. My Live Stream Video)
  --player-id: string # The unique identifier for the player. (e.g. pl4f4ferf5erfr5zed4fsdd)
  --public: oneof<nothing, bool> # BETA FEATURE Please limit all public = false ("private") livestreams to 3,000 users. Whether your video can be viewed by everyone, or requires authentication to see it. A setting of false will require a unique token for each view.
  --record: oneof<nothing, bool> # Whether you are recording or not. True for record, false for not record. (default: false, e.g. true)
]: any -> record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live-streams")
  let req_body = {"name": $name, "playerId": $player_id, "public": $public, "record": $record} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a live stream
#
# DELETE /live-streams/{liveStreamId}
# operationId: DELETE_live-streams-liveStreamId
export def "live-streams delete" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({live_stream_id: (encode-path-segment $live_stream_id)} | format pattern "/live-streams/{live_stream_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show live stream
#
# GET /live-streams/{liveStreamId}
# operationId: GET_live-streams-liveStreamId
export def "live-streams get" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({live_stream_id: (encode-path-segment $live_stream_id)} | format pattern "/live-streams/{live_stream_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a live stream
#
# PATCH /live-streams/{liveStreamId}
# operationId: PATCH_live-streams-liveStreamId
export def "live-streams update" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # The name you want to use for your live stream. (e.g. My Live Stream Video)
  --player-id: string # The unique ID for the player associated with a live stream that you want to update. (e.g. pl45KFKdlddgk654dspkze)
  --public: oneof<nothing, bool> # BETA FEATURE Please limit all public = false ("private") livestreams to 3,000 users. Whether your video can be viewed by everyone, or requires authentication to see it. A setting of false will require a unique token for each view.
  --record: oneof<nothing, bool> # Use this to indicate whether you want the recording on or off. On is true, off is false. (e.g. true)
]: any -> record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({live_stream_id: (encode-path-segment $live_stream_id)} | format pattern "/live-streams/{live_stream_id}"))
  let req_body = {"name": $name, "playerId": $player_id, "public": $public, "record": $record} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a thumbnail
#
# DELETE /live-streams/{liveStreamId}/thumbnail
# operationId: DELETE_live-streams-liveStreamId-thumbnail
export def "live-streams-thumbnail delete" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({live_stream_id: (encode-path-segment $live_stream_id)} | format pattern "/live-streams/{live_stream_id}/thumbnail"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upload a thumbnail
#
# POST /live-streams/{liveStreamId}/thumbnail
# operationId: POST_live-streams-liveStreamId-thumbnail
export def "live-streams-thumbnail create" [
  live_stream_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The image to be added as a thumbnail. (format: binary)
]: any -> record<assets: record<hls: string, iframe: string, player: string, thumbnail: string>, broadcasting: bool, liveStreamId: string, name: string, playerId: string, public: bool, record: bool, streamKey: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({live_stream_id: (encode-path-segment $live_stream_id)} | format pattern "/live-streams/{live_stream_id}/thumbnail"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List all players
#
# GET /players
# operationId: GET_players
export def "players list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer # createdAt is the time the player was created. updatedAt is the time the player was last updated. The time is presented in ISO-8601 format. (e.g. createdAt)
  --sort-order: string@sort-order-completer # Allowed: asc, desc. Ascending for date and time means that earlier values precede later ones. Descending means that later values preced earlier ones. (e.g. asc)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/players" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a player
#
# POST /players
# operationId: POST_players
export def "players create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background-bottom: string # RGBA color: bottom 50% of background. Default: rgba(0, 0, 0, .7)
  --background-text: string # RGBA color for title text. Default: rgba(255, 255, 255, 1)
  --background-top: string # RGBA color: top 50% of background. Default: rgba(0, 0, 0, .7)
  --enable-api: oneof<nothing, bool> # enable/disable player SDK access. Default: true (default: true)
  --enable-controls: oneof<nothing, bool> # enable/disable player controls. Default: true (default: true)
  --force-autoplay: oneof<nothing, bool> # enable/disable player autoplay. Default: false (default: false)
  --force-loop: oneof<nothing, bool> # enable/disable looping. Default: false (default: false)
  --hide-title: oneof<nothing, bool> # enable/disable title. Default: false (default: false)
  --link: string # RGBA color for all controls. Default: rgba(255, 255, 255, 1)
  --link-hover: string # RGBA color for all controls when hovered. Default: rgba(255, 255, 255, 1)
  --text: string # RGBA color for timer text. Default: rgba(255, 255, 255, 1)
  --track-background: string # RGBA color playback bar: background. Default: rgba(255, 255, 255, .2)
  --track-played: string # RGBA color playback bar: played content. Default: rgba(88, 131, 255, .95)
  --track-unplayed: string # RGBA color playback bar: downloaded but unplayed (buffered) content. Default: rgba(255, 255, 255, .35)
]: any -> record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/players")
  let req_body = {"backgroundBottom": $background_bottom, "backgroundText": $background_text, "backgroundTop": $background_top, "enableApi": $enable_api, "enableControls": $enable_controls, "forceAutoplay": $force_autoplay, "forceLoop": $force_loop, "hideTitle": $hide_title, "link": $link, "linkHover": $link_hover, "text": $text, "trackBackground": $track_background, "trackPlayed": $track_played, "trackUnplayed": $track_unplayed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a player
#
# DELETE /players/{playerId}
# operationId: DELETE_players-playerId
export def "players delete" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id)} | format pattern "/players/{player_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show a player
#
# GET /players/{playerId}
# operationId: GET_players-playerId
export def "players get" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id)} | format pattern "/players/{player_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a player
#
# PATCH /players/{playerId}
# operationId: PATCH_players-playerId
export def "players update" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --background-bottom: string # RGBA color: bottom 50% of background. Default: rgba(0, 0, 0, .7)
  --background-text: string # RGBA color for title text. Default: rgba(255, 255, 255, 1)
  --background-top: string # RGBA color: top 50% of background. Default: rgba(0, 0, 0, .7)
  --enable-api: oneof<nothing, bool> # enable/disable player SDK access. Default: true (default: true)
  --enable-controls: oneof<nothing, bool> # enable/disable player controls. Default: true (default: true)
  --force-autoplay: oneof<nothing, bool> # enable/disable player autoplay. Default: false (default: false)
  --force-loop: oneof<nothing, bool> # enable/disable looping. Default: false (default: false)
  --hide-title: oneof<nothing, bool> # enable/disable title. Default: false (default: false)
  --link: string # RGBA color for all controls. Default: rgba(255, 255, 255, 1)
  --link-hover: string # RGBA color for all controls when hovered. Default: rgba(255, 255, 255, 1)
  --text: string # RGBA color for timer text. Default: rgba(255, 255, 255, 1)
  --track-background: string # RGBA color playback bar: background. Default: rgba(255, 255, 255, .2)
  --track-played: string # RGBA color playback bar: played content. Default: rgba(88, 131, 255, .95)
  --track-unplayed: string # RGBA color playback bar: downloaded but unplayed (buffered) content. Default: rgba(255, 255, 255, .35)
]: any -> record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id)} | format pattern "/players/{player_id}"))
  let req_body = {"backgroundBottom": $background_bottom, "backgroundText": $background_text, "backgroundTop": $background_top, "enableApi": $enable_api, "enableControls": $enable_controls, "forceAutoplay": $force_autoplay, "forceLoop": $force_loop, "hideTitle": $hide_title, "link": $link, "linkHover": $link_hover, "text": $text, "trackBackground": $track_background, "trackPlayed": $track_played, "trackUnplayed": $track_unplayed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete logo
#
# DELETE /players/{playerId}/logo
# operationId: DELETE_players-playerId-logo
export def "players-logo delete" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id)} | format pattern "/players/{player_id}/logo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upload a logo
#
# POST /players/{playerId}/logo
# operationId: POST_players-playerId-logo
export def "players-logo create" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The name of the file you want to use for your logo. (format: binary, e.g. mylogo.jpg)
  link: string # The path to the file you want to upload and use as a logo. (format: string, e.g. path/to/my/logo/mylogo.jpg)
]: any -> record<backgroundBottom: string, backgroundText: string, backgroundTop: string, enableApi: bool, enableControls: bool, forceAutoplay: bool, forceLoop: bool, hideTitle: bool, link: string, linkHover: string, text: string, trackBackground: string, trackPlayed: string, trackUnplayed: string, assets: record<link: string, logo: string>, createdAt: string, linkActive: string, playerId: string, shapeAspect: string, shapeBackgroundBottom: string, shapeBackgroundTop: string, shapeMargin: int, shapeRadius: int, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player_id: (encode-path-segment $player_id)} | format pattern "/players/{player_id}/logo"))
  let req_body = {"file": $file, "link": $link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Upload with an upload token
#
# POST /upload
# operationId: POST_upload
export def "upload create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-token: string # The unique identifier for the token you want to use to upload a video. (e.g. to1tcmSFHeYY5KzyhOqVKMKb)
  --content-range: string # Content-Range represents the range of bytes that will be returned as a result of the request. Byte ranges are inclusive, meaning that bytes 0-999 represents the first 1000 bytes in a file or object. (e.g. Content-Range: bytes 200-100/5000)
  file: string # The path to the video you want to upload. (format: binary, e.g. path/to/video/video.mp4)
  --video-id: string # The video id returned by the first call to this endpoint in a large video upload scenario.
]: any -> record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/upload" $qp)
  let req_body = {"file": $file, "videoId": $video_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Range": $content_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List all active upload tokens.
#
# GET /upload-tokens
# operationId: GET_upload-tokens
export def "upload-tokens list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sort-by: string@sort-by-completer-1 # Allowed: createdAt, ttl. You can use these to sort by when a token was created, or how much longer the token will be active (ttl - time to live). Date and time is presented in ISO-8601 format. (e.g. ttl)
  --sort-order: string@sort-order-completer # Allowed: asc, desc. Ascending is 0-9 or A-Z. Descending is 9-0 or Z-A. (e.g. asc)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<createdAt: string, expiresAt: string, token: string, ttl: int>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/upload-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Generate an upload token
#
# POST /upload-tokens
# operationId: POST_upload-tokens
export def "upload-tokens create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ttl: int # Time in seconds that the token will be active. A value of 0 means that the token has no exipration date. The default is to have no expiration. (default: 0)
]: any -> record<createdAt: string, expiresAt: string, token: string, ttl: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/upload-tokens")
  let req_body = {"ttl": $ttl} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete an upload token
#
# DELETE /upload-tokens/{uploadToken}
# operationId: DELETE_upload-tokens-uploadToken
export def "upload-tokens delete" [
  upload_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upload_token: (encode-path-segment $upload_token)} | format pattern "/upload-tokens/{upload_token}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show upload token
#
# GET /upload-tokens/{uploadToken}
# operationId: GET_upload-tokens-uploadToken
export def "upload-tokens get" [
  upload_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, expiresAt: string, token: string, ttl: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upload_token: (encode-path-segment $upload_token)} | format pattern "/upload-tokens/{upload_token}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List all videos
#
# GET /videos
# operationId: LIST-videos
export def "videos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --title: string # The title of a specific video you want to find. The search will match exactly to what term you provide and return any videos that contain the same term as part of their titles. (e.g. My Video.mp4)
  --tags: list<string> # A tag is a category you create and apply to videos. You can search for videos with particular tags by listing one or more here. Only videos that have all the tags you list will be returned. (e.g. "tags": ["captions", "dialogue"])
  --metadata: list<string> # Videos can be tagged with metadata tags in key:value pairs. You can search for videos with specific key value pairs using this parameter. [Dynamic Metadata](https://api.video/blog/endpoints/dynamic-metadata) allows you to define a key that allows any value pair. (e.g. [{"key":"Author", "value":"John Doe"}, {"key":"Format", "value":"Tutorial"}])
  --description: string # If you described a video with a term or sentence, you can add it here to return videos containing this string. (e.g. New Zealand)
  --live-stream-id: string # If you know the ID for a live stream, you can retrieve the stream by adding the ID for it here. (e.g. li400mYKSgQ6xs7taUeSaEKr)
  --sort-by: string # Allowed: publishedAt, title. You can search by the time videos were published at, or by title. (e.g. publishedAt)
  --sort-order: string # Allowed: asc, desc. asc is ascending and sorts from A to Z. desc is descending and sorts from Z to A. (e.g. asc)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<assets: record, description: string, metadata: list, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record, tags: list, title: string, updatedAt: string, videoId: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "title" $title "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "metadata" $metadata "multi") (serialize-qp "description" $description "scalar") (serialize-qp "liveStreamId" $live_stream_id "scalar") (serialize-qp "sortBy" $sort_by "scalar") (serialize-qp "sortOrder" $sort_order "scalar") (serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a video
#
# POST /videos
# operationId: POST-video
# --metadata item shape: {key?: string, value?: string}
export def "videos create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A brief description of your video. (e.g. A video about string theory.)
  --metadata: list # A list of key value pairs that you use to provide metadata for your video. These pairs can be made dynamic, allowing you to segment your audience. Read more on [dynamic metadata](https://api.video/blog/endpoints/dynamic-metadata). (e.g. [{"key": "Author", "value": "John Doe"}]) — item shape: {key?: string, value?: string}
  --mp4-support: oneof<nothing, bool> # Enables mp4 version in addition to streamed version. (default: true, e.g. true)
  --panoramic: oneof<nothing, bool> # Indicates if your video is a 360/immersive video. (default: false, e.g. false)
  --player-id: string # The unique identification number for your video player. (e.g. pl45KFKdlddgk654dspkze)
  --public: oneof<nothing, bool> # Whether your video can be viewed by everyone, or requires authentication to see it. A setting of false will require a unique token for each view. Default is true. Tutorials on [private videos](https://api.video/blog/endpoints/private-videos). (default: true, e.g. true)
  --published-at: string # The API uses ISO-8601 format for time, and includes 3 places for milliseconds. (format: date-time, e.g. 2020-07-14T23:36:18.598Z)
  --body-source: string # If you add a video already on the web, this is where you enter the url for the video. (e.g. https://www.myvideo.url.com/video.mp4)
  --tags: list<string> # A list of tags you want to use to describe your video. (e.g. ["maths", "string theory", "video"])
  title: string # The title of your new video. (e.g. Maths video)
]: any -> record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/videos")
  let req_body = {"description": $description, "metadata": $metadata, "mp4Support": $mp4_support, "panoramic": $panoramic, "playerId": $player_id, "public": $public, "publishedAt": $published_at, "source": $body_source, "tags": $tags, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a video
#
# DELETE /videos/{videoId}
# operationId: DELETE-video
export def "videos delete" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show a video
#
# GET /videos/{videoId}
# operationId: GET-video
export def "videos get" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a video
#
# PATCH /videos/{videoId}
# operationId: PATCH-video
# --metadata item shape: {key?: string, value?: string}
export def "videos update" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # A brief description of the video. (e.g. A film about good books.)
  --metadata: list # A list (array) of dictionaries where each dictionary contains a key value pair that describes the video. As with tags, you must send the complete list of metadata you want as whatever you send here will overwrite the existing metadata for the video. [Dynamic Metadata](https://api.video/blog/endpoints/dynamic-metadata) allows you to define a key that allows any value pair. — item shape: {key?: string, value?: string}
  --mp4-support: oneof<nothing, bool> # Whether the player supports the mp4 format. (e.g. true)
  --panoramic: oneof<nothing, bool> # Whether the video is a 360 degree or immersive video. (e.g. false)
  --player-id: string # The unique ID for the player you want to associate with your video. (e.g. pl4k0jvEUuaTdRAEjQ4Jfrgz)
  --public: oneof<nothing, bool> # Whether the video is publicly available or not. False means it is set to private. Default is true. Tutorials on [private videos](https://api.video/blog/endpoints/private-videos). (e.g. true)
  --tags: list<string> # A list of terms or words you want to tag the video with. Make sure the list includes all the tags you want as whatever you send in this list will overwrite the existing list for the video. (e.g. ["maths", "string theory", "video"])
  --title: string # The title you want to use for your video.
]: any -> record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}"))
  let req_body = {"description": $description, "metadata": $metadata, "mp4Support": $mp4_support, "panoramic": $panoramic, "playerId": $player_id, "public": $public, "tags": $tags, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List video captions
#
# GET /videos/{videoId}/captions
# operationId: GET_videos-videoId-captions
export def "videos-captions list" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<default: bool, src: string, srclang: string, uri: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/captions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete a caption
#
# DELETE /videos/{videoId}/captions/{language}
# operationId: DELETE_videos-videoId-captions-language
export def "videos-captions delete" [
  video_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), language: (encode-path-segment $language)} | format pattern "/videos/{video_id}/captions/{language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show a caption
#
# GET /videos/{videoId}/captions/{language}
# operationId: GET_videos-videoId-captions-language
export def "videos-captions get" [
  video_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<default: bool, src: string, srclang: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), language: (encode-path-segment $language)} | format pattern "/videos/{video_id}/captions/{language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update caption
#
# PATCH /videos/{videoId}/captions/{language}
# operationId: PATCH_videos-videoId-captions-language
export def "videos-captions update" [
  video_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --default: oneof<nothing, bool>
]: any -> record<default: bool, src: string, srclang: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), language: (encode-path-segment $language)} | format pattern "/videos/{video_id}/captions/{language}"))
  let req_body = {"default": $default} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Upload a caption
#
# POST /videos/{videoId}/captions/{language}
# operationId: POST_videos-videoId-captions-language
export def "videos-captions create" [
  video_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The video text track (VTT) you want to upload. (format: binary, e.g. https://cdn.api.video/vod/vi3N6cDinStg3oBbN79GklWS/captions/en.vtt)
]: any -> record<default: bool, src: string, srclang: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), language: (encode-path-segment $language)} | format pattern "/videos/{video_id}/captions/{language}"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List video chapters
#
# GET /videos/{videoId}/chapters
# operationId: GET_videos-videoId-chapters
export def "videos-chapters list" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<language: string, src: string, uri: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/chapters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete a chapter
#
# DELETE /videos/{videoId}/chapters/{language}
# operationId: DELETE_videos-videoId-chapters-language
export def "videos-chapters delete" [
  video_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), language: (encode-path-segment $language)} | format pattern "/videos/{video_id}/chapters/{language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show a chapter
#
# GET /videos/{videoId}/chapters/{language}
# operationId: GET_videos-videoId-chapters-language
export def "videos-chapters get" [
  video_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<language: string, src: string, uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), language: (encode-path-segment $language)} | format pattern "/videos/{video_id}/chapters/{language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upload a chapter
#
# POST /videos/{videoId}/chapters/{language}
# operationId: POST_videos-videoId-chapters-language
export def "videos-chapters create" [
  video_id: string
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The VTT file describing the chapters you want to upload. (format: binary)
]: any -> record<language: string, src: string, uri: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id), language: (encode-path-segment $language)} | format pattern "/videos/{video_id}/chapters/{language}"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Upload a video
#
# POST /videos/{videoId}/source
# operationId: POST_videos-videoId-source
export def "videos-source create" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Content-Range represents the range of bytes that will be returned as a result of the request. Byte ranges are inclusive, meaning that bytes 0-999 represents the first 1000 bytes in a file or object. (e.g. Content-Range: bytes 200-100/5000)
  file: string # The path to the video you would like to upload. The path must be local. If you want to use a video from an online source, you must use the "/videos" endpoint and add the "source" parameter when you create a new video. (format: binary, e.g. @/path/to/video.mp4)
]: any -> record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/source"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Range": $content_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Show video status
#
# GET /videos/{videoId}/status
# operationId: GET-video-status
export def "videos-status get" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<encoding: record<metadata: record<aspectRatio: string, audioCodec: string, bitrate: float, duration: int, framerate: int, height: int, samplerate: int, videoCodec: string, width: int>, playable: bool, qualities: list<record>>, ingest: record<filesize: int, receivedBytes: list<record>, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Pick a thumbnail
#
# PATCH /videos/{videoId}/thumbnail
# operationId: PATCH_videos-videoId-thumbnail
export def "videos-thumbnail update" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  timecode: string # Frame in video to be used as a placeholder before the video plays. Example: '"00:01:00.000" for 1 minute into the video.' Valid Patterns: "hh:mm:ss.ms" "hh:mm:ss:frameNumber" "124" (integer value is reported as seconds) If selection is out of range, "00:00:00.00" will be chosen.
]: any -> record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/thumbnail"))
  let req_body = {"timecode": $timecode} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Upload a thumbnail
#
# POST /videos/{videoId}/thumbnail
# operationId: POST_videos-videoId-thumbnail
export def "videos-thumbnail create" [
  video_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # The image to be added as a thumbnail. (format: binary)
]: any -> record<assets: record<hls: string, iframe: string, mp4: string, player: string, thumbnail: string>, description: string, metadata: table<key: string, value: string>, mp4Support: bool, panoramic: bool, playerId: string, public: bool, publishedAt: string, source: record<liveStream: record<links: list, liveStreamId: string>, type: string, uri: string>, tags: list<any>, title: string, updatedAt: string, videoId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/videos/{video_id}/thumbnail"))
  let req_body = {"file": $file} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["file"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# List all webhooks
#
# GET /webhooks
# operationId: LIST-webhooks
export def "webhooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: string # The webhook event that you wish to filter on. (e.g. video.encoding.quality.completed)
  --current-page: int # Choose the number of search results to return per page. Minimum value: 1 (default: 1, e.g. 2)
  --page-size: int # Results per page. Allowed values 1-100, default is 25. (default: 25, e.g. 30)
]: nothing -> record<data: table<createdAt: string, events: list, url: string, webhookId: string>, pagination: record<currentPage: int, currentPageItems: int, itemsTotal: int, links: list<record>, pageSize: int, pagesTotal: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "events" $events "scalar") (serialize-qp "currentPage" $current_page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create Webhook
#
# POST /webhooks
# operationId: POST-webhooks
export def "webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  events: list<string> # A list of the webhooks that you are subscribing to. There are Currently four webhook options: * ```video.encoding.quality.completed``` When a new video is uploaded into your account, it will be encoded into several different HLS sizes/bitrates. When each version is encoded, your webhook will get a notification. It will look like ```{ \"type\": \"video.encoding.quality.completed\", \"emittedAt\": \"2021-01-29T16:46:25.217+01:00\", \"videoId\": \"viXXXXXXXX\", \"encoding\": \"hls\", \"quality\": \"720p\"} ```. This request says that the 720p HLS encoding was completed. * ```live-stream.broadcast.started``` When a livestream begins broadcasting, the broadcasting parameter changes from false to true, and this webhook fires. * ```live-stream.broadcast.ended``` This event fores when the livestream has finished broadcasting, and the broadcasting parameter flips from false to true. * ```video.source.recorded``` This event is similar to ```video.encoding.quality.completed```, but tells you if a livestream has been recorded as a VOD. (e.g. video.encoding.quality.completed)
  url: string # The the url to which HTTP notifications are sent. It could be any http or https URL. (e.g. https://example.com/webhooks)
]: any -> record<createdAt: string, events: list<string>, url: string, webhookId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/webhooks")
  let req_body = {"events": $events, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a Webhook
#
# DELETE /webhooks/{webhookId}
# operationId: DELETE-webhook
export def "webhooks delete" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Show Webhook details
#
# GET /webhooks/{webhookId}
# operationId: GET-Webhook
export def "webhooks get" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, events: list<string>, url: string, webhookId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: (encode-path-segment $webhook_id)} | format pattern "/webhooks/{webhook_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}
