# Auto-generated client for PeerTube v5.1.0
# Source: https://api.apis.guru/v2/specs/cpy.re/peertube/5.1.0/openapi.json
# Auth: --token flag or $env.PEERTUBE_TOKEN

const BASE_URL = "https://peertube2.cpy.re"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PEERTUBE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
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

def base-url-completer [] { ["https://peertube2.cpy.re" "https://peertube3.cpy.re" "https://peertube.cpy.re"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["1" "2" "3"] }
def video-is-completer [] { ["blacklisted" "deleted"] }
def filter-completer [] { ["account" "comment" "video"] }
def sort-completer [] { ["-createdAt" "-id" "-state"] }
def sort-completer-1 [] { ["createdAt"] }
def rating-completer [] { ["dislike" "like"] }
def playlist-type-completer [] { ["1" "2"] }
def nsfw-completer [] { ["false" "true"] }
def include-completer [] { ["0" "1" "2" "4" "8"] }
def privacy-one-of-completer [] { ["1" "2" "3" "4"] }
def skip-count-completer [] { ["false" "true"] }
def sort-completer-2 [] { ["-best" "-createdAt" "-duration" "-hot" "-likes" "-publishedAt" "-trending" "-views" "name"] }
def job-type-completer [] { ["activitypub-follow" "activitypub-http-broadcast" "activitypub-http-fetcher" "activitypub-http-unicast" "activitypub-refresher" "email" "video-channel-import" "video-file-import" "video-import" "video-live-ending" "video-redundancy" "video-transcoding" "videos-views-stats"] }
def player-mode-completer [] { ["p2p-media-loader" "webtorrent"] }
def search-target-completer [] { ["local" "search-index"] }
def sort-completer-3 [] { ["-createdAt" "-duration" "-likes" "-match" "-publishedAt" "-views" "name"] }
def state-completer-1 [] { ["accepted" "pending"] }
def actor-type-completer [] { ["Application" "Group" "Organization" "Person" "Service"] }
def level-completer [] { ["error" "warn"] }
def target-completer [] { ["my-videos" "remote-videos"] }
def sort-completer-4 [] { ["name"] }
def sort-completer-5 [] { ["-createdAt" "-id" "-username"] }
def admin-flags-completer [] { ["0" "1"] }
def role-completer [] { ["0" "1" "2"] }
def display-nsfw-completer [] { ["both" "false" "true"] }
def sort-completer-6 [] { ["-createdAt" "-state" "createdAt" "state"] }
def privacy-completer [] { ["1" "2" "3"] }
def type-completer [] { ["1" "2"] }
def sort-completer-7 [] { ["-createdAt" "-dislikes" "-duration" "-id" "-likes" "-uuid" "-views" "name"] }
def privacy-completer-1 [] { ["1" "2" "3" "4"] }
def latency-mode-completer [] { ["1" "2" "3"] }
def sort-completer-8 [] { ["-createdAt" "-totalReplies"] }
def transcoding-type-completer [] { ["hls" "webtorrent"] }
def view-event-completer [] { ["seek"] }
def accept-completer [] { ["application/atom+xml" "application/json" "application/rss+xml" "application/xml" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "abuses get" } } | get name | first)
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

# List abuses
#
# GET /api/v1/abuses
# operationId: getAbuses
export def "abuses get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # only list the report with this id
  --predefined-reason: list<string> # predefined reason the listed reports should contain
  --search: string # plain search that will match with video titles, reporter names and more
  --state: int@state-completer
  --search-reporter: string # only list reports of a specific reporter
  --search-reportee: string # only list reports of a specific reportee
  --search-video: string # only list reports of a specific video
  --search-video-channel: string # only list reports of a specific video channel
  --video-is: string@video-is-completer # only list deleted or blocklisted videos
  --filter: string@filter-completer # only list account, comment or video reports
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer # Sort abuses by criteria
]: nothing -> record<data: table<createdAt: string, id: int, moderationComment: string, predefinedReasons: list, reason: string, reporterAccount: record, state: record, video: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "predefinedReason" $predefined_reason "multi") (serialize-qp "search" $search "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "searchReporter" $search_reporter "scalar") (serialize-qp "searchReportee" $search_reportee "scalar") (serialize-qp "searchVideo" $search_video "scalar") (serialize-qp "searchVideoChannel" $search_video_channel "scalar") (serialize-qp "videoIs" $video_is "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/abuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "predefinedReason": $predefined_reason, "search": $search, "state": $state, "searchReporter": $search_reporter, "searchReportee": $search_reportee, "searchVideo": $search_video, "searchVideoChannel": $search_video_channel, "videoIs": $video_is, "filter": $filter, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Report an abuse
#
# POST /api/v1/abuses
# --account shape: {id?: int}
# --comment shape: {id?: any}
# --video shape: {endAt?: int, id?: any, startAt?: int}
export def "abuses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account: record # shape: {id?: int}
  --comment: record # shape: {id?: any}
  --predefined-reasons: list<string> # Reason categories that help triage reports
  reason: string # Reason why the user reports this video
  --video: record # shape: {endAt?: int, id?: any, startAt?: int}
]: any -> record<abuse: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/abuses")
  let req_body = {"account": $account, "comment": $comment, "predefinedReasons": $predefined_reasons, "reason": $reason, "video": $video} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an abuse
#
# DELETE /api/v1/abuses/{abuseId}
export def "abuses delete" [
  abuse_id: int
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
  if ($abuse_id | is-empty) { error make --unspanned { msg: "path parameter 'abuseId' must be non-empty" } }
  let full_url = (build-url $base ({abuse_id: (encode-path-segment $abuse_id)} | format pattern "/api/v1/abuses/{abuse_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update an abuse
#
# PUT /api/v1/abuses/{abuseId}
export def "abuses update" [
  abuse_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --moderation-comment: string # Update the report comment visible only to the moderation team
  --state: int@state-completer # The abuse state (Pending = `1`, Rejected = `2`, Accepted = `3`)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($abuse_id | is-empty) { error make --unspanned { msg: "path parameter 'abuseId' must be non-empty" } }
  let full_url = (build-url $base ({abuse_id: (encode-path-segment $abuse_id)} | format pattern "/api/v1/abuses/{abuse_id}"))
  let req_body = {"moderationComment": $moderation_comment, "state": $state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List messages of an abuse
#
# GET /api/v1/abuses/{abuseId}/messages
export def "abuses-messages get" [
  abuse_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<account: record, byModerator: bool, createdAt: string, id: int, message: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($abuse_id | is-empty) { error make --unspanned { msg: "path parameter 'abuseId' must be non-empty" } }
  let full_url = (build-url $base ({abuse_id: (encode-path-segment $abuse_id)} | format pattern "/api/v1/abuses/{abuse_id}/messages"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add message to an abuse
#
# POST /api/v1/abuses/{abuseId}/messages
export def "abuses-messages create" [
  abuse_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: string # Message to send
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($abuse_id | is-empty) { error make --unspanned { msg: "path parameter 'abuseId' must be non-empty" } }
  let full_url = (build-url $base ({abuse_id: (encode-path-segment $abuse_id)} | format pattern "/api/v1/abuses/{abuse_id}/messages"))
  let req_body = {"message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an abuse message
#
# DELETE /api/v1/abuses/{abuseId}/messages/{abuseMessageId}
export def "abuses-messages delete" [
  abuse_id: int
  abuse_message_id: int
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
  if ($abuse_id | is-empty) { error make --unspanned { msg: "path parameter 'abuseId' must be non-empty" } }
  if ($abuse_message_id | is-empty) { error make --unspanned { msg: "path parameter 'abuseMessageId' must be non-empty" } }
  let full_url = (build-url $base ({abuse_id: (encode-path-segment $abuse_id), abuse_message_id: (encode-path-segment $abuse_message_id)} | format pattern "/api/v1/abuses/{abuse_id}/messages/{abuse_message_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List accounts
#
# GET /api/v1/accounts
# operationId: getAccounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Get an account
#
# GET /api/v1/accounts/{name}
# operationId: getAccount
export def "accounts get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/api/v1/accounts/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List followers of an account
#
# GET /api/v1/accounts/{name}/followers
# operationId: getAccountFollowers
export def "accounts-followers get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-1 # Sort followers by criteria
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/api/v1/accounts/{name}/followers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort, "search": $search} | compact), body: null}
}

# List ratings of an account
#
# GET /api/v1/accounts/{name}/ratings
export def "accounts-ratings get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --rating: string@rating-completer # Optionally filter which ratings to retrieve
]: nothing -> table<rating: string, video: record<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "rating" $rating "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/api/v1/accounts/{name}/ratings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort, "rating": $rating} | compact), body: null}
}

# List the synchronizations of video channels of an account
#
# GET /api/v1/accounts/{name}/video-channel-syncs
export def "accounts-video-channel-syncs get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<channel: record, createdAt: string, externalChannelUrl: string, id: int, lastSyncAt: string, state: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/api/v1/accounts/{name}/video-channel-syncs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# List video channels of an account
#
# GET /api/v1/accounts/{name}/video-channels
export def "accounts-video-channels get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-stats: oneof<nothing, bool> # include daily view statistics for the last 30 days and total views (only if authentified as the account user)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "withStats" $with_stats "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/api/v1/accounts/{name}/video-channels") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"withStats": $with_stats, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# List playlists of an account
#
# GET /api/v1/accounts/{name}/video-playlists
export def "accounts-video-playlists get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
  --playlist-type: int@playlist-type-completer
]: nothing -> record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: record, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "playlistType" $playlist_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/api/v1/accounts/{name}/video-playlists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort, "search": $search, "playlistType": $playlist_type} | compact), body: null}
}

# List videos of an account
#
# GET /api/v1/accounts/{name}/videos
# operationId: getAccountVideos
export def "accounts-videos get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "categoryOneOf" $category_one_of "scalar") (serialize-qp "isLive" $is_live "scalar") (serialize-qp "tagsOneOf" $tags_one_of "scalar") (serialize-qp "tagsAllOf" $tags_all_of "scalar") (serialize-qp "licenceOneOf" $licence_one_of "scalar") (serialize-qp "languageOneOf" $language_one_of "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $is_local "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacy_one_of "scalar") (serialize-qp "hasHLSFiles" $has_hls_files "scalar") (serialize-qp "hasWebtorrentFiles" $has_webtorrent_files "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/api/v1/accounts/{name}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"categoryOneOf": $category_one_of, "isLive": $is_live, "tagsOneOf": $tags_one_of, "tagsAllOf": $tags_all_of, "licenceOneOf": $licence_one_of, "languageOneOf": $language_one_of, "nsfw": $nsfw, "isLocal": $is_local, "include": $include, "privacyOneOf": $privacy_one_of, "hasHLSFiles": $has_hls_files, "hasWebtorrentFiles": $has_webtorrent_files, "skipCount": $skip_count, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Get block status of accounts/hosts
#
# GET /api/v1/blocklist/status
export def "blocklist-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounts: list<string> # Check if these accounts are blocked (e.g. [goofy@example.com, donald@example.com])
  --hosts: list<string> # Check if these hosts are blocked (e.g. [example.com])
]: nothing -> record<accounts: record, hosts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accounts" $accounts "multi") (serialize-qp "hosts" $hosts "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/blocklist/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accounts": $accounts, "hosts": $hosts} | compact), body: null}
}

# Get instance public configuration
#
# GET /api/v1/config
# operationId: getConfig
export def "config get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<autoBlacklist: record<videos: record<ofUsers: record>>, avatar: record<extensions: list<string>, file: record<size: record>>, contactForm: record<enabled: bool>, email: record<enabled: bool>, followings: record<instance: record<autoFollowIndex: record>>, homepage: record<enabled: bool>, import: record<videoChannelSynchronization: record<enabled: bool>, videos: record<http: record, torrent: record>>, instance: record<customizations: record<css: string, javascript: string>, defaultClientRoute: string, defaultNSFWPolicy: string, isNSFW: bool, name: string, shortDescription: string>, plugin: record<registered: list<string>>, search: record<remoteUri: record<anonymous: bool, users: bool>>, serverCommit: string, serverVersion: string, signup: record<allowed: bool, allowedForCurrentIP: bool, requiresEmailVerification: bool>, theme: record<registered: list<string>>, tracker: record<enabled: bool>, transcoding: record<enabledResolutions: list<int>, hls: record<enabled: bool>, webtorrent: record<enabled: bool>>, trending: record<videos: record<intervalDays: int>>, user: record<videoQuota: int, videoQuotaDaily: int>, video: record<file: record<extensions: list>, image: record<extensions: list, size: record>>, videoCaption: record<file: record<extensions: list, size: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get instance "About" information
#
# GET /api/v1/config/about
# operationId: getAbout
export def "config-about get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<instance: record<description: string, name: string, shortDescription: string, terms: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/about")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete instance runtime configuration
#
# DELETE /api/v1/config/custom
# operationId: delCustomConfig
export def "config-custom delete" [
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
  let full_url = (build-url $base "/api/v1/config/custom")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get instance runtime configuration
#
# GET /api/v1/config/custom
# operationId: getCustomConfig
export def "config-custom get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin: record<email: string>, autoBlacklist: record<videos: record<ofUsers: record>>, cache: record<captions: record<size: int>, previews: record<size: int>>, contactForm: record<enabled: bool>, followers: record<instance: record<enabled: bool, manualApproval: bool>>, import: record<video_channel_synchronization: record<enabled: bool>, videos: record<http: record, torrent: record>>, instance: record<customizations: record<css: string, javascript: string>, defaultClientRoute: string, defaultNSFWPolicy: string, description: string, isNSFW: bool, name: string, shortDescription: string, terms: string>, services: record<twitter: record<username: string, whitelisted: bool>>, signup: record<enabled: bool, limit: int, requiresEmailVerification: bool>, theme: record<default: string>, transcoding: record<allowAdditionalExtensions: bool, allowAudioFiles: bool, concurrency: float, enabled: bool, hls: record<enabled: bool>, profile: string, resolutions: record<0p: bool, 1080p: bool, 1440p: bool, 144p: bool, 2160p: bool, 240p: bool, 360p: bool, 480p: bool, 720p: bool>, threads: int, webtorrent: record<enabled: bool>>, user: record<videoQuota: int, videoQuotaDaily: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/config/custom")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set instance runtime configuration
#
# PUT /api/v1/config/custom
# operationId: putCustomConfig
export def "config-custom update" [
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
  let full_url = (build-url $base "/api/v1/config/custom")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get instance custom homepage
#
# GET /api/v1/custom-pages/homepage/instance
export def "custom-pages-homepage-instance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/custom-pages/homepage/instance")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set instance custom homepage
#
# PUT /api/v1/custom-pages/homepage/instance
export def "custom-pages-homepage-instance update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --content: string # content of the homepage, that will be injected in the client
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/custom-pages/homepage/instance")
  let req_body = {"content": $content} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Pause job queue
#
# POST /api/v1/jobs/pause
export def "jobs-pause create" [
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
  let full_url = (build-url $base "/api/v1/jobs/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Resume job queue
#
# POST /api/v1/jobs/resume
export def "jobs-resume create" [
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
  let full_url = (build-url $base "/api/v1/jobs/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List instance jobs
#
# GET /api/v1/jobs/{state}
# operationId: getJobs
export def "jobs get" [
  state: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --job-type: string@job-type-completer # job type
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, data: record, error: record, finishedOn: string, id: int, processedOn: string, state: string, type: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($state | is-empty) { error make --unspanned { msg: "path parameter 'state' must be non-empty" } }
  let qp = [(serialize-qp "jobType" $job_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({state: (encode-path-segment $state)} | format pattern "/api/v1/jobs/{state}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"jobType": $job_type, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Create playback metrics
#
# POST /api/v1/metrics/playback
export def "metrics-playback create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  downloaded_bytes_http: float # How many bytes were downloaded with HTTP since the last metric creation
  downloaded_bytes_p2p: float # How many bytes were downloaded with P2P since the last metric creation
  errors: float # How many errors occured since the last metric creation
  --fps: float # Current player video fps
  player_mode: string@player-mode-completer
  --resolution: float # Current player video resolution
  resolution_changes: float # How many resolution changes occured since the last metric creation
  uploaded_bytes_p2p: float # How many bytes were uploaded with P2P since the last metric creation
  video_id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/metrics/playback")
  let req_body = {"downloadedBytesHTTP": $downloaded_bytes_http, "downloadedBytesP2P": $downloaded_bytes_p2p, "errors": $errors, "fps": $fps, "playerMode": $player_mode, "resolution": $resolution, "resolutionChanges": $resolution_changes, "uploadedBytesP2P": $uploaded_bytes_p2p, "videoId": $video_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Login prerequisite
#
# GET /api/v1/oauth-clients/local
# operationId: getOAuthClient
export def "oauth-clients-local get-o-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client_id: string, client_secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/oauth-clients/local")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List plugins
#
# GET /api/v1/plugins
# operationId: getPlugins
export def "plugins list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --plugin-type: int
  --uninstalled: oneof<nothing, bool>
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pluginType" $plugin_type "scalar") (serialize-qp "uninstalled" $uninstalled "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/plugins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pluginType": $plugin_type, "uninstalled": $uninstalled, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# List available plugins
#
# GET /api/v1/plugins/available
# operationId: getAvailablePlugins
export def "plugins-available get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string
  --plugin-type: int
  --current-peer-tube-engine: string
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "pluginType" $plugin_type "scalar") (serialize-qp "currentPeerTubeEngine" $current_peer_tube_engine "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/plugins/available" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "pluginType": $plugin_type, "currentPeerTubeEngine": $current_peer_tube_engine, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Install a plugin
#
# POST /api/v1/plugins/install
# operationId: addPlugin
export def "plugins-install create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --npm-name: string # e.g. peertube-plugin-auth-ldap
  --path: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/install")
  let req_body = {"npmName": $npm_name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Uninstall a plugin
#
# POST /api/v1/plugins/uninstall
# operationId: uninstallPlugin
export def "plugins-uninstall create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  npm_name: string # name of the plugin/theme in its package.json (e.g. peertube-plugin-auth-ldap)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/uninstall")
  let req_body = {"npmName": $npm_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update a plugin
#
# POST /api/v1/plugins/update
# operationId: updatePlugin
export def "plugins-update update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --npm-name: string # e.g. peertube-plugin-auth-ldap
  --path: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/plugins/update")
  let req_body = {"npmName": $npm_name, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a plugin
#
# GET /api/v1/plugins/{npmName}
# operationId: getPlugin
export def "plugins get" [
  npm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, description: string, enabled: bool, homepage: string, latestVersion: string, name: string, peertubeEngine: string, settings: record, type: int, uninstalled: bool, updatedAt: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($npm_name | is-empty) { error make --unspanned { msg: "path parameter 'npmName' must be non-empty" } }
  let full_url = (build-url $base ({npm_name: (encode-path-segment $npm_name)} | format pattern "/api/v1/plugins/{npm_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a plugin's public settings
#
# GET /api/v1/plugins/{npmName}/public-settings
export def "plugins-public-settings get" [
  npm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($npm_name | is-empty) { error make --unspanned { msg: "path parameter 'npmName' must be non-empty" } }
  let full_url = (build-url $base ({npm_name: (encode-path-segment $npm_name)} | format pattern "/api/v1/plugins/{npm_name}/public-settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a plugin's registered settings
#
# GET /api/v1/plugins/{npmName}/registered-settings
export def "plugins-registered-settings get" [
  npm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($npm_name | is-empty) { error make --unspanned { msg: "path parameter 'npmName' must be non-empty" } }
  let full_url = (build-url $base ({npm_name: (encode-path-segment $npm_name)} | format pattern "/api/v1/plugins/{npm_name}/registered-settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set a plugin's settings
#
# PUT /api/v1/plugins/{npmName}/settings
export def "plugins-settings update" [
  npm_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --settings: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($npm_name | is-empty) { error make --unspanned { msg: "path parameter 'npmName' must be non-empty" } }
  let full_url = (build-url $base ({npm_name: (encode-path-segment $npm_name)} | format pattern "/api/v1/plugins/{npm_name}/settings"))
  let req_body = {"settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Search channels
#
# GET /api/v1/search/video-channels
# operationId: searchChannels
export def "search-video-channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete channel information and interact with it.
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search-target: string@search-target-completer # If the administrator enabled search index support, you can override the default search target. **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information: * If the current user has the ability to make a remote URI search (this information is available in the config endpoint), then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database. After that, you can use the classic REST API endpoints to fetch the complete object or interact with it * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch the data from the origin instance API
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "searchTarget" $search_target "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/video-channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "start": $start, "count": $count, "searchTarget": $search_target, "sort": $qp_sort} | compact), body: null}
}

# Search playlists
#
# GET /api/v1/search/video-playlists
# operationId: searchPlaylists
export def "search-video-playlists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete playlist information and interact with it.
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search-target: string@search-target-completer # If the administrator enabled search index support, you can override the default search target. **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information: * If the current user has the ability to make a remote URI search (this information is available in the config endpoint), then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database. After that, you can use the classic REST API endpoints to fetch the complete object or interact with it * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch the data from the origin instance API
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: record, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "searchTarget" $search_target "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/video-playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "start": $start, "count": $count, "searchTarget": $search_target, "sort": $qp_sort} | compact), body: null}
}

# Search videos
#
# GET /api/v1/search/videos
# operationId: searchVideos
export def "search-videos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # String to search. If the user can make a remote URI search, and the string is an URI then the PeerTube instance will fetch the remote object and add it to its database. Then, you can use the REST API to fetch the complete video information and interact with it.
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --uuids: string # Find videos with specific UUIDs
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search-target: string@search-target-completer # If the administrator enabled search index support, you can override the default search target. **Warning**: If you choose to make an index search, PeerTube will get results from a third party service. It means the instance may not yet know the objects you fetched. If you want to load video/channel information: * If the current user has the ability to make a remote URI search (this information is available in the config endpoint), then reuse the search API to make a search using the object URI so PeerTube instance fetches the remote object and fill its database. After that, you can use the classic REST API endpoints to fetch the complete object or interact with it * If the current user doesn't have the ability to make a remote URI search, then redirect the user on the origin instance or fetch the data from the origin instance API
  --qp-sort: string@sort-completer-3 # Sort videos by criteria (prefixing with `-` means `DESC` order):
  --start-date: string # Get videos that are published after this date (format: date-time)
  --end-date: string # Get videos that are published before this date (format: date-time)
  --originally-published-start-date: string # Get videos that are originally published after this date (format: date-time)
  --originally-published-end-date: string # Get videos that are originally published before this date (format: date-time)
  --duration-min: int # Get videos that have this minimum duration
  --duration-max: int # Get videos that have this maximum duration
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "categoryOneOf" $category_one_of "scalar") (serialize-qp "isLive" $is_live "scalar") (serialize-qp "tagsOneOf" $tags_one_of "scalar") (serialize-qp "tagsAllOf" $tags_all_of "scalar") (serialize-qp "licenceOneOf" $licence_one_of "scalar") (serialize-qp "languageOneOf" $language_one_of "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $is_local "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacy_one_of "scalar") (serialize-qp "uuids" $uuids "scalar") (serialize-qp "hasHLSFiles" $has_hls_files "scalar") (serialize-qp "hasWebtorrentFiles" $has_webtorrent_files "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "searchTarget" $search_target "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar") (serialize-qp "originallyPublishedStartDate" $originally_published_start_date "scalar") (serialize-qp "originallyPublishedEndDate" $originally_published_end_date "scalar") (serialize-qp "durationMin" $duration_min "scalar") (serialize-qp "durationMax" $duration_max "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/search/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "categoryOneOf": $category_one_of, "isLive": $is_live, "tagsOneOf": $tags_one_of, "tagsAllOf": $tags_all_of, "licenceOneOf": $licence_one_of, "languageOneOf": $language_one_of, "nsfw": $nsfw, "isLocal": $is_local, "include": $include, "privacyOneOf": $privacy_one_of, "uuids": $uuids, "hasHLSFiles": $has_hls_files, "hasWebtorrentFiles": $has_webtorrent_files, "skipCount": $skip_count, "start": $start, "count": $count, "searchTarget": $search_target, "sort": $qp_sort, "startDate": $start_date, "endDate": $end_date, "originallyPublishedStartDate": $originally_published_start_date, "originallyPublishedEndDate": $originally_published_end_date, "durationMin": $duration_min, "durationMax": $duration_max} | compact), body: null}
}

# Get instance audit logs
#
# GET /api/v1/server/audit-logs
# operationId: getInstanceAuditLogs
export def "server-audit-logs get-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/audit-logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List account blocks
#
# GET /api/v1/server/blocklist/accounts
export def "server-blocklist-accounts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/blocklist/accounts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Block an account
#
# POST /api/v1/server/blocklist/accounts
export def "server-blocklist-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_name: string # account to block, in the form `username@domain` (e.g. chocobozzz@example.org)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/blocklist/accounts")
  let req_body = {"accountName": $account_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unblock an account by its handle
#
# DELETE /api/v1/server/blocklist/accounts/{accountName}
export def "server-blocklist-accounts delete" [
  account_name: string
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
  if ($account_name | is-empty) { error make --unspanned { msg: "path parameter 'accountName' must be non-empty" } }
  let full_url = (build-url $base ({account_name: (encode-path-segment $account_name)} | format pattern "/api/v1/server/blocklist/accounts/{account_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List server blocks
#
# GET /api/v1/server/blocklist/servers
export def "server-blocklist-servers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/blocklist/servers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Block a server
#
# POST /api/v1/server/blocklist/servers
export def "server-blocklist-servers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  host: string # server domain to block (format: hostname)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/blocklist/servers")
  let req_body = {"host": $host} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unblock a server by its domain
#
# DELETE /api/v1/server/blocklist/servers/{host}
export def "server-blocklist-servers delete" [
  host: string
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
  if ($host | is-empty) { error make --unspanned { msg: "path parameter 'host' must be non-empty" } }
  let full_url = (build-url $base ({host: (encode-path-segment $host)} | format pattern "/api/v1/server/blocklist/servers/{host}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List instances following the server
#
# GET /api/v1/server/followers
export def "server-followers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1
  --actor-type: string@actor-type-completer
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "actorType" $actor_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"state": $state, "actorType": $actor_type, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Remove or reject a follower to your server
#
# DELETE /api/v1/server/followers/{nameWithHost}
export def "server-followers delete" [
  name_with_host: string
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
  if ($name_with_host | is-empty) { error make --unspanned { msg: "path parameter 'nameWithHost' must be non-empty" } }
  let full_url = (build-url $base ({name_with_host: (encode-path-segment $name_with_host)} | format pattern "/api/v1/server/followers/{name_with_host}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Accept a pending follower to your server
#
# POST /api/v1/server/followers/{nameWithHost}/accept
export def "server-followers-accept create" [
  name_with_host: string
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
  if ($name_with_host | is-empty) { error make --unspanned { msg: "path parameter 'nameWithHost' must be non-empty" } }
  let full_url = (build-url $base ({name_with_host: (encode-path-segment $name_with_host)} | format pattern "/api/v1/server/followers/{name_with_host}/accept"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reject a pending follower to your server
#
# POST /api/v1/server/followers/{nameWithHost}/reject
export def "server-followers-reject create" [
  name_with_host: string
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
  if ($name_with_host | is-empty) { error make --unspanned { msg: "path parameter 'nameWithHost' must be non-empty" } }
  let full_url = (build-url $base ({name_with_host: (encode-path-segment $name_with_host)} | format pattern "/api/v1/server/followers/{name_with_host}/reject"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List instances followed by the server
#
# GET /api/v1/server/following
export def "server-following get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --state: string@state-completer-1
  --actor-type: string@actor-type-completer
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "state" $state "scalar") (serialize-qp "actorType" $actor_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/following" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"state": $state, "actorType": $actor_type, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Follow a list of actors (PeerTube instance, channel or account)
#
# POST /api/v1/server/following
export def "server-following create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --handles: list<string>
  --hosts: list<string>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/following")
  let req_body = {"handles": $handles, "hosts": $hosts} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unfollow an actor (PeerTube instance, channel or account)
#
# DELETE /api/v1/server/following/{hostOrHandle}
export def "server-following delete" [
  host_or_handle: string
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
  if ($host_or_handle | is-empty) { error make --unspanned { msg: "path parameter 'hostOrHandle' must be non-empty" } }
  let full_url = (build-url $base ({host_or_handle: (encode-path-segment $host_or_handle)} | format pattern "/api/v1/server/following/{host_or_handle}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get instance logs
#
# GET /api/v1/server/logs
# operationId: getInstanceLogs
export def "server-logs get-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send client log
#
# POST /api/v1/server/logs/client
# operationId: sendClientLog
export def "server-logs-client send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  level: any@level-completer
  message: string
  --meta: string # Additional information regarding this log
  --stack-trace: string # Stack trace of the error if there is one
  url: string # URL of the current user page
  --user-agent: string # User agent of the web browser that sends the message
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/logs/client")
  let req_body = {"level": $level, "message": $message, "meta": $meta, "stackTrace": $stack_trace, "url": $url, "userAgent": $user_agent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List videos being mirrored
#
# GET /api/v1/server/redundancy/videos
# operationId: getMirroredVideos
export def "server-redundancy-videos get-mirrored" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target: string@target-completer # direction of the mirror
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-4 # Sort abuses by criteria
]: nothing -> table<id: int, name: string, redundancies: record<files: list, streamingPlaylists: list>, url: string, uuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target" $target "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/server/redundancy/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"target": $target, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Mirror a video
#
# POST /api/v1/server/redundancy/videos
# operationId: putMirroredVideo
export def "server-redundancy-videos update-mirrored" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  video_id: int # e.g. 42
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/redundancy/videos")
  let req_body = {"videoId": $video_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a mirror done on a video
#
# DELETE /api/v1/server/redundancy/videos/{redundancyId}
# operationId: delMirroredVideo
export def "server-redundancy-videos delete-mirrored" [
  redundancy_id: string
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
  if ($redundancy_id | is-empty) { error make --unspanned { msg: "path parameter 'redundancyId' must be non-empty" } }
  let full_url = (build-url $base ({redundancy_id: (encode-path-segment $redundancy_id)} | format pattern "/api/v1/server/redundancy/videos/{redundancy_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a server redundancy policy
#
# PUT /api/v1/server/redundancy/{host}
export def "server-redundancy update" [
  host: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --redundancy-allowed: oneof<nothing, bool> # allow mirroring of the host's local videos
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($host | is-empty) { error make --unspanned { msg: "path parameter 'host' must be non-empty" } }
  let full_url = (build-url $base ({host: (encode-path-segment $host)} | format pattern "/api/v1/server/redundancy/{host}"))
  let req_body = {"redundancyAllowed": $redundancy_allowed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get instance stats
#
# GET /api/v1/server/stats
# operationId: getInstanceStats
export def "server-stats get-instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activityPubMessagesProcessedPerSecond: float, totalActivityPubMessagesErrors: float, totalActivityPubMessagesProcessed: float, totalActivityPubMessagesSuccesses: float, totalActivityPubMessagesWaiting: float, totalDailyActiveUsers: float, totalInstanceFollowers: float, totalInstanceFollowing: float, totalLocalDailyActiveVideoChannels: float, totalLocalMonthlyActiveVideoChannels: float, totalLocalPlaylists: float, totalLocalVideoChannels: float, totalLocalVideoComments: float, totalLocalVideoFilesSize: float, totalLocalVideoViews: float, totalLocalVideos: float, totalLocalWeeklyActiveVideoChannels: float, totalMonthlyActiveUsers: float, totalUsers: float, totalVideoComments: float, totalVideos: float, totalWeeklyActiveUsers: float, videosRedundancy: table<strategy: string, totalSize: float, totalUsed: float, totalVideoFiles: float, totalVideos: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/server/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List users
#
# GET /api/v1/users
# operationId: getUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Plain text search that will match with user usernames or emails
  --blocked: oneof<nothing, bool> # Filter results down to (un)banned users
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-5 # Sort users by criteria
]: nothing -> table<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, blocked: bool, blockedReason: string, createdAt: string, email: string, emailVerified: bool, id: record, lastLoginDate: string, noAccountSetupWarningModal: bool, noInstanceConfigWarningModal: bool, noWelcomeModal: bool, nsfwPolicy: string, p2pEnabled: bool, pluginAuth: string, role: record<id: int, label: string>, theme: string, username: string, videoChannels: list<record>, videoQuota: int, videoQuotaDaily: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "blocked" $blocked "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "blocked": $blocked, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Create a user
#
# POST /api/v1/users
# operationId: addUser
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --admin-flags: int@admin-flags-completer # Admin flags for the user (None = `0`, Bypass video blocklist = `1`) (e.g. 1)
  --channel-name: string # immutable name of the channel, used to interact with its actor (e.g. framasoft_videos)
  email: string # The user email (format: email)
  password: string # format: password
  role: int@role-completer # The user role (Admin = `0`, Moderator = `1`, User = `2`) (e.g. 2)
  username: string # immutable name of the user, used to find or mention its actor (e.g. chocobozzz)
  video_quota: int # The user video quota in bytes (e.g. -1)
  video_quota_daily: int # The user daily video quota in bytes (e.g. -1)
]: any -> record<user: record<account: record<id: int>, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users")
  let req_body = {"adminFlags": $admin_flags, "channelName": $channel_name, "email": $email, "password": $password, "role": $role, "username": $username, "videoQuota": $video_quota, "videoQuotaDaily": $video_quota_daily} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Resend user verification link
#
# POST /api/v1/users/ask-send-verify-email
# operationId: resendEmailToVerifyUser
export def "users-ask-send-verify-email resend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/ask-send-verify-email")
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get my user information
#
# GET /api/v1/users/me
# operationId: getUserInfo
export def "users-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, autoPlayNextVideo: bool, autoPlayNextVideoPlaylist: bool, autoPlayVideo: bool, blocked: bool, blockedReason: string, createdAt: string, email: string, emailVerified: bool, id: record, lastLoginDate: string, noAccountSetupWarningModal: bool, noInstanceConfigWarningModal: bool, noWelcomeModal: bool, nsfwPolicy: string, p2pEnabled: bool, pluginAuth: string, role: record<id: int, label: string>, theme: string, username: string, videoChannels: list<record>, videoQuota: int, videoQuotaDaily: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update my user information
#
# PUT /api/v1/users/me
# operationId: putUserInfo
export def "users-me update-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-play-next-video: oneof<nothing, bool> # new preference regarding playing following videos automatically
  --auto-play-next-video-playlist: oneof<nothing, bool> # new preference regarding playing following playlist videos automatically
  --auto-play-video: oneof<nothing, bool> # new preference regarding playing videos automatically
  --current-password: string # format: password
  --display-nsfw: string@display-nsfw-completer # new NSFW display policy
  --display-name: string # new name of the user in its representations
  --email: any # new email used for login and service communications
  --no-account-setup-warning-modal: oneof<nothing, bool>
  --no-instance-config-warning-modal: oneof<nothing, bool>
  --no-welcome-modal: oneof<nothing, bool>
  --p2p-enabled: oneof<nothing, bool> # whether to enable P2P in the player or not
  --password: string # format: password
  --theme: string
  --video-languages: list<string> # list of languages to filter videos down to
  --videos-history-enabled: oneof<nothing, bool> # whether to keep track of watched history or not
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me")
  let req_body = {"autoPlayNextVideo": $auto_play_next_video, "autoPlayNextVideoPlaylist": $auto_play_next_video_playlist, "autoPlayVideo": $auto_play_video, "currentPassword": $current_password, "displayNSFW": $display_nsfw, "displayName": $display_name, "email": $email, "noAccountSetupWarningModal": $no_account_setup_warning_modal, "noInstanceConfigWarningModal": $no_instance_config_warning_modal, "noWelcomeModal": $no_welcome_modal, "p2pEnabled": $p2p_enabled, "password": $password, "theme": $theme, "videoLanguages": $video_languages, "videosHistoryEnabled": $videos_history_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List my abuses
#
# GET /api/v1/users/me/abuses
# operationId: getMyAbuses
export def "users-me-abuses get-my" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # only list the report with this id
  --state: int@state-completer
  --qp-sort: string@sort-completer # Sort abuses by criteria
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
]: nothing -> record<data: table<createdAt: string, id: int, moderationComment: string, predefinedReasons: list, reason: string, reporterAccount: record, state: record, video: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/abuses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"id": $id, "state": $state, "sort": $qp_sort, "start": $start, "count": $count} | compact), body: null}
}

# Delete my avatar
#
# DELETE /api/v1/users/me/avatar
export def "users-me-avatar delete" [
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
  let full_url = (build-url $base "/api/v1/users/me/avatar")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update my user avatar
#
# POST /api/v1/users/me/avatar/pick
export def "users-me-avatar-pick create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarfile: string # The file to upload (format: binary)
]: any -> record<avatars: table<createdAt: string, path: string, updatedAt: string, width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/avatar/pick")
  let req_body = {"avatarfile": $avatarfile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["avatarfile"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# List watched videos history
#
# GET /api/v1/users/me/history/videos
export def "users-me-history-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/history/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "search": $search} | compact), body: null}
}

# Clear video history
#
# POST /api/v1/users/me/history/videos/remove
export def "users-me-history-videos-remove create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --before-date: string # history before this date will be deleted (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/history/videos/remove")
  let req_body = {"beforeDate": $before_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete history element
#
# DELETE /api/v1/users/me/history/videos/{videoId}
export def "users-me-history-videos delete" [
  video_id: int
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
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'videoId' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/api/v1/users/me/history/videos/{video_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update my notification settings
#
# PUT /api/v1/users/me/notification-settings
export def "users-me-notification-settings update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --abuse-as-moderator: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --auto-instance-following: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --blacklist-on-my-video: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --comment-mention: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --my-video-import-finished: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --my-video-published: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-comment-on-my-video: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-follow: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-instance-follower: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-user-registration: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --new-video-from-subscription: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
  --video-auto-blacklist-as-moderator: int # Notification type. One of the following values, or a sum of multiple values: - `0` NONE - `1` WEB - `2` EMAIL
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/notification-settings")
  let req_body = {"abuseAsModerator": $abuse_as_moderator, "autoInstanceFollowing": $auto_instance_following, "blacklistOnMyVideo": $blacklist_on_my_video, "commentMention": $comment_mention, "myVideoImportFinished": $my_video_import_finished, "myVideoPublished": $my_video_published, "newCommentOnMyVideo": $new_comment_on_my_video, "newFollow": $new_follow, "newInstanceFollower": $new_instance_follower, "newUserRegistration": $new_user_registration, "newVideoFromSubscription": $new_video_from_subscription, "videoAutoBlacklistAsModerator": $video_auto_blacklist_as_moderator} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List my notifications
#
# GET /api/v1/users/me/notifications
export def "users-me-notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --unread: oneof<nothing, bool> # only list unread notifications
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<account: record, actorFollow: record, comment: record, createdAt: string, id: int, read: bool, type: int, updatedAt: string, video: record, videoAbuse: record, videoBlacklist: record, videoImport: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "unread" $unread "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"unread": $unread, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Mark notifications as read by their id
#
# POST /api/v1/users/me/notifications/read
export def "users-me-notifications-read create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  ids: list<int> # ids of the notifications to mark as read
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/notifications/read")
  let req_body = {"ids": $ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Mark all my notification as read
#
# POST /api/v1/users/me/notifications/read-all
export def "users-me-notifications-read-all create" [
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
  let full_url = (build-url $base "/api/v1/users/me/notifications/read-all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get my user subscriptions
#
# GET /api/v1/users/me/subscriptions
export def "users-me-subscriptions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Add subscription to my user
#
# POST /api/v1/users/me/subscriptions
export def "users-me-subscriptions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  uri: string # uri of the video channels to subscribe to (format: uri)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/subscriptions")
  let req_body = {"uri": $uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get if subscriptions exist for my user
#
# GET /api/v1/users/me/subscriptions/exist
export def "users-me-subscriptions-exist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --uris: list<string> # list of uris to check if each is part of the user subscriptions
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "uris" $uris "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/subscriptions/exist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"uris": $uris} | compact), body: null}
}

# List videos of subscriptions of my user
#
# GET /api/v1/users/me/subscriptions/videos
export def "users-me-subscriptions-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryOneOf" $category_one_of "scalar") (serialize-qp "isLive" $is_live "scalar") (serialize-qp "tagsOneOf" $tags_one_of "scalar") (serialize-qp "tagsAllOf" $tags_all_of "scalar") (serialize-qp "licenceOneOf" $licence_one_of "scalar") (serialize-qp "languageOneOf" $language_one_of "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $is_local "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacy_one_of "scalar") (serialize-qp "hasHLSFiles" $has_hls_files "scalar") (serialize-qp "hasWebtorrentFiles" $has_webtorrent_files "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/subscriptions/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"categoryOneOf": $category_one_of, "isLive": $is_live, "tagsOneOf": $tags_one_of, "tagsAllOf": $tags_all_of, "licenceOneOf": $licence_one_of, "languageOneOf": $language_one_of, "nsfw": $nsfw, "isLocal": $is_local, "include": $include, "privacyOneOf": $privacy_one_of, "hasHLSFiles": $has_hls_files, "hasWebtorrentFiles": $has_webtorrent_files, "skipCount": $skip_count, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Delete subscription of my user
#
# DELETE /api/v1/users/me/subscriptions/{subscriptionHandle}
export def "users-me-subscriptions delete" [
  subscription_handle: string
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
  if ($subscription_handle | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionHandle' must be non-empty" } }
  let full_url = (build-url $base ({subscription_handle: (encode-path-segment $subscription_handle)} | format pattern "/api/v1/users/me/subscriptions/{subscription_handle}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get subscription of my user
#
# GET /api/v1/users/me/subscriptions/{subscriptionHandle}
export def "users-me-subscriptions get" [
  subscription_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, banners: table<createdAt: string, path: string, updatedAt: string, width: int>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_handle | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionHandle' must be non-empty" } }
  let full_url = (build-url $base ({subscription_handle: (encode-path-segment $subscription_handle)} | format pattern "/api/v1/users/me/subscriptions/{subscription_handle}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check video exists in my playlists
#
# GET /api/v1/users/me/video-playlists/videos-exist
export def "users-me-video-playlists-videos-exist get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-ids: list # The video ids to check
]: nothing -> record<videoId: table<playlistElementId: int, playlistId: int, startTimestamp: int, stopTimestamp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "videoIds" $video_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/video-playlists/videos-exist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"videoIds": $video_ids} | compact), body: null}
}

# Get my user used quota
#
# GET /api/v1/users/me/video-quota-used
export def "users-me-video-quota-used get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<videoQuotaUsed: float, videoQuotaUsedDaily: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/me/video-quota-used")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get videos of my user
#
# GET /api/v1/users/me/videos
export def "users-me-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Get video imports of my user
#
# GET /api/v1/users/me/videos/imports
export def "users-me-videos-imports get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --target-url: string # Filter on import target URL
  --video-channel-sync-id: float # Filter on imports created by a specific channel synchronization
  --search: string # Search in video names
]: nothing -> record<data: table<createdAt: string, error: string, id: record, magnetUri: string, state: record, targetUrl: string, torrentName: string, torrentfile: string, updatedAt: string, video: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "targetUrl" $target_url "scalar") (serialize-qp "videoChannelSyncId" $video_channel_sync_id "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/me/videos/imports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort, "targetUrl": $target_url, "videoChannelSyncId": $video_channel_sync_id, "search": $search} | compact), body: null}
}

# Get rate of my user for a video
#
# GET /api/v1/users/me/videos/{videoId}/rating
export def "users-me-videos-rating get" [
  video_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, rating: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($video_id | is-empty) { error make --unspanned { msg: "path parameter 'videoId' must be non-empty" } }
  let full_url = (build-url $base ({video_id: (encode-path-segment $video_id)} | format pattern "/api/v1/users/me/videos/{video_id}/rating"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Register a user
#
# POST /api/v1/users/register
# operationId: registerUser
# --channel shape: {displayName?: string, name?: string}
export def "users-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel: record # channel base information used to create the first channel of the user — shape: {displayName?: string, name?: string}
  --display-name: string # editable name of the user, displayed in its representations
  email: string # email of the user, used for login or service communications (format: email)
  password: string # format: password
  username: any # immutable name of the user, used to find or mention its actor
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/register")
  let req_body = {"channel": $channel, "displayName": $display_name, "email": $email, "password": $password, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List registrations
#
# GET /api/v1/users/registrations
# operationId: listRegistrations
export def "users-registrations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --search: string
  --qp-sort: string@sort-completer-6
]: nothing -> record<data: table<accountDisplayName: string, channelDisplayName: string, channelHandle: string, createdAt: string, email: string, emailVerified: bool, id: int, moderationResponse: string, registrationReason: string, state: record, updatedAt: string, user: record, username: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/users/registrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "search": $search, "sort": $qp_sort} | compact), body: null}
}

# Resend verification link to registration email
#
# POST /api/v1/users/registrations/ask-send-verify-email
# operationId: resendEmailToVerifyRegistration
export def "users-registrations-ask-send-verify-email resend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # Registration email
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/registrations/ask-send-verify-email")
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Request registration
#
# POST /api/v1/users/registrations/request
# operationId: requestRegistration
# --channel shape: {displayName?: string, name?: string}
export def "users-registrations-request request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel: record # channel base information used to create the first channel of the user — shape: {displayName?: string, name?: string}
  --display-name: string # editable name of the user, displayed in its representations
  email: string # email of the user, used for login or service communications (format: email)
  password: string # format: password
  username: any # immutable name of the user, used to find or mention its actor
  registration_reason: string # reason for the user to register on the instance
]: any -> record<accountDisplayName: string, channelDisplayName: string, channelHandle: string, createdAt: string, email: string, emailVerified: bool, id: int, moderationResponse: string, registrationReason: string, state: record<id: int, label: string>, updatedAt: string, user: record<id: int>, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/registrations/request")
  let req_body = {"channel": $channel, "displayName": $display_name, "email": $email, "password": $password, "username": $username, "registrationReason": $registration_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete registration
#
# DELETE /api/v1/users/registrations/{registrationId}
# operationId: deleteRegistration
export def "users-registrations delete" [
  registration_id: int
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
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registrationId' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/api/v1/users/registrations/{registration_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Accept registration
#
# POST /api/v1/users/registrations/{registrationId}/accept
# operationId: acceptRegistration
export def "users-registrations-accept create" [
  registration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  moderation_response: string # Moderation response to send to the user
  --prevent-email-delivery: oneof<nothing, bool> # Set it to true if you don't want PeerTube to send an email to the user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registrationId' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/api/v1/users/registrations/{registration_id}/accept"))
  let req_body = {"moderationResponse": $moderation_response, "preventEmailDelivery": $prevent_email_delivery} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reject registration
#
# POST /api/v1/users/registrations/{registrationId}/reject
# operationId: rejectRegistration
export def "users-registrations-reject reject" [
  registration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  moderation_response: string # Moderation response to send to the user
  --prevent-email-delivery: oneof<nothing, bool> # Set it to true if you don't want PeerTube to send an email to the user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registrationId' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/api/v1/users/registrations/{registration_id}/reject"))
  let req_body = {"moderationResponse": $moderation_response, "preventEmailDelivery": $prevent_email_delivery} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify a registration email
#
# POST /api/v1/users/registrations/{registrationId}/verify-email
# operationId: verifyRegistrationEmail
export def "users-registrations-verify-email verify" [
  registration_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  verification_string: string # format: url
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registrationId' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/api/v1/users/registrations/{registration_id}/verify-email"))
  let req_body = {"verificationString": $verification_string} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Logout
#
# POST /api/v1/users/revoke-token
# operationId: revokeOAuthToken
export def "users-revoke-token delete-o-auth" [
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
  let full_url = (build-url $base "/api/v1/users/revoke-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Login
#
# POST /api/v1/users/token
# Discriminator (request): grant_type = password, refresh_token
# operationId: getOAuthToken
export def "users-token get-o-auth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<access_token: string, expires_in: int, refresh_token: string, refresh_token_expires_in: int, token_type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/users/token")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete a user
#
# DELETE /api/v1/users/{id}
# operationId: delUser
export def "users delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/users/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a user
#
# GET /api/v1/users/{id}
# operationId: getUser
export def "users get" [
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
  --with-stats: oneof<nothing, bool> # include statistics about the user (only available as a moderator/admin)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "withStats" $with_stats "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/users/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"withStats": $with_stats} | compact), body: null}
}

# Update a user
#
# PUT /api/v1/users/{id}
# operationId: putUser
export def "users update" [
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
  --admin-flags: int@admin-flags-completer # Admin flags for the user (None = `0`, Bypass video blocklist = `1`) (e.g. 1)
  --email: any # The updated email of the user
  --email-verified: oneof<nothing, bool> # Set the email as verified
  --password: string # format: password
  --plugin-auth: string # The auth plugin to use to authenticate the user (nullable, e.g. peertube-plugin-auth-saml2)
  --role: int@role-completer # The user role (Admin = `0`, Moderator = `1`, User = `2`) (e.g. 2)
  --video-quota: int # The updated video quota of the user in bytes
  --video-quota-daily: int # The updated daily video quota of the user in bytes
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/users/{id}"))
  let req_body = {"adminFlags": $admin_flags, "email": $email, "emailVerified": $email_verified, "password": $password, "pluginAuth": $plugin_auth, "role": $role, "videoQuota": $video_quota, "videoQuotaDaily": $video_quota_daily} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Confirm two factor auth
#
# POST /api/v1/users/{id}/two-factor/confirm-request
# operationId: confirmTwoFactorRequest
export def "users-two-factor-confirm-request confirm" [
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
  otp_token: string # OTP token generated by the app
  request_token: string # Token to identify the two factor request
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/users/{id}/two-factor/confirm-request"))
  let req_body = {"otpToken": $otp_token, "requestToken": $request_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Disable two factor auth
#
# POST /api/v1/users/{id}/two-factor/disable
# operationId: disableTwoFactor
export def "users-two-factor-disable disable" [
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
  --current-password: string # Password of the currently authenticated user
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/users/{id}/two-factor/disable"))
  let req_body = {"currentPassword": $current_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Request two factor auth
#
# POST /api/v1/users/{id}/two-factor/request
# operationId: requestTwoFactor
export def "users-two-factor-request request" [
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
  --current-password: string # Password of the currently authenticated user
]: any -> table<otpRequest: record<requestToken: string, secret: string, uri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/users/{id}/two-factor/request"))
  let req_body = {"currentPassword": $current_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify a user
#
# POST /api/v1/users/{id}/verify-email
# operationId: verifyUser
export def "users-verify-email verify" [
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
  --is-pending-email: oneof<nothing, bool>
  verification_string: string # format: url
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/users/{id}/verify-email"))
  let req_body = {"isPendingEmail": $is_pending_email, "verificationString": $verification_string} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a synchronization for a video channel
#
# POST /api/v1/video-channel-syncs
# operationId: addVideoChannelSync
export def "video-channel-syncs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --external-channel-url: string # e.g. https://youtube.com/c/UC_myfancychannel
  --video-channel-id: int # e.g. 42
]: any -> record<videoChannelSync: record<channel: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, banners: list, description: string, displayName: string, isLocal: bool, ownerAccount: record, support: string>, createdAt: string, externalChannelUrl: string, id: int, lastSyncAt: string, state: record<id: int, label: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-channel-syncs")
  let req_body = {"externalChannelUrl": $external_channel_url, "videoChannelId": $video_channel_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a video channel synchronization
#
# DELETE /api/v1/video-channel-syncs/{channelSyncId}
# operationId: delVideoChannelSync
export def "video-channel-syncs delete" [
  channel_sync_id: int
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
  if ($channel_sync_id | is-empty) { error make --unspanned { msg: "path parameter 'channelSyncId' must be non-empty" } }
  let full_url = (build-url $base ({channel_sync_id: (encode-path-segment $channel_sync_id)} | format pattern "/api/v1/video-channel-syncs/{channel_sync_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Triggers the channel synchronization job, fetching all the videos from the remote channel
#
# POST /api/v1/video-channel-syncs/{channelSyncId}/sync
# operationId: triggerVideoChannelSync
export def "video-channel-syncs-sync trigger" [
  channel_sync_id: int
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
  if ($channel_sync_id | is-empty) { error make --unspanned { msg: "path parameter 'channelSyncId' must be non-empty" } }
  let full_url = (build-url $base ({channel_sync_id: (encode-path-segment $channel_sync_id)} | format pattern "/api/v1/video-channel-syncs/{channel_sync_id}/sync"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List video channels
#
# GET /api/v1/video-channels
# operationId: getVideoChannels
export def "video-channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
]: nothing -> record<data: table<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/video-channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Create a video channel
#
# POST /api/v1/video-channels
# operationId: addVideoChannel
export def "video-channels create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any # Channel description
  display_name: any # Channel display name
  --support: any # How to support/fund the channel
  name: any # username of the channel to create
]: any -> record<videoChannel: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-channels")
  let req_body = {"description": $description, "displayName": $display_name, "support": $support, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a video channel
#
# DELETE /api/v1/video-channels/{channelHandle}
# operationId: delVideoChannel
export def "video-channels delete" [
  channel_handle: string
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
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a video channel
#
# GET /api/v1/video-channels/{channelHandle}
# operationId: getVideoChannel
export def "video-channels get" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, banners: table<createdAt: string, path: string, updatedAt: string, width: int>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a video channel
#
# PUT /api/v1/video-channels/{channelHandle}
# operationId: putVideoChannel
export def "video-channels update" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: any # Channel description
  --display-name: any # Channel display name
  --support: any # How to support/fund the channel
  --bulk-videos-support-update: oneof<nothing, bool> # Update the support field for all videos of this channel
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}"))
  let req_body = {"description": $description, "displayName": $display_name, "support": $support, "bulkVideosSupportUpdate": $bulk_videos_support_update} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete channel avatar
#
# DELETE /api/v1/video-channels/{channelHandle}/avatar
export def "video-channels-avatar delete" [
  channel_handle: string
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
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}/avatar"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update channel avatar
#
# POST /api/v1/video-channels/{channelHandle}/avatar/pick
export def "video-channels-avatar-pick create" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --avatarfile: string # The file to upload. (format: binary)
]: any -> record<avatars: table<createdAt: string, path: string, updatedAt: string, width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}/avatar/pick"))
  let req_body = {"avatarfile": $avatarfile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["avatarfile"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete channel banner
#
# DELETE /api/v1/video-channels/{channelHandle}/banner
export def "video-channels-banner delete" [
  channel_handle: string
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
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}/banner"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update channel banner
#
# POST /api/v1/video-channels/{channelHandle}/banner/pick
export def "video-channels-banner-pick create" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --bannerfile: string # The file to upload. (format: binary)
]: any -> record<banners: table<createdAt: string, path: string, updatedAt: string, width: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}/banner/pick"))
  let req_body = {"bannerfile": $bannerfile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["bannerfile"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# List followers of a video channel
#
# GET /api/v1/video-channels/{channelHandle}/followers
# operationId: getVideoChannelFollowers
export def "video-channels-followers get" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-1 # Sort followers by criteria
  --search: string # Plain text search, applied to various parts of the model depending on endpoint
]: nothing -> record<data: table<createdAt: string, follower: record, following: record, id: int, score: float, state: string, updatedAt: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}/followers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort, "search": $search} | compact), body: null}
}

# Import videos in channel
#
# POST /api/v1/video-channels/{channelHandle}/import-videos
export def "video-channels-import-videos create" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  external_channel_url: string # e.g. https://youtube.com/c/UC_myfancychannel
  --video-channel-sync-id: int # If part of a channel sync process, specify its id to assign video imports to this channel synchronization
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}/import-videos"))
  let req_body = {"externalChannelUrl": $external_channel_url, "videoChannelSyncId": $video_channel_sync_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List playlists of a channel
#
# GET /api/v1/video-channels/{channelHandle}/video-playlists
export def "video-channels-video-playlists get" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --playlist-type: int@playlist-type-completer
]: nothing -> record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: record, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "playlistType" $playlist_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}/video-playlists") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort, "playlistType": $playlist_type} | compact), body: null}
}

# List videos of a video channel
#
# GET /api/v1/video-channels/{channelHandle}/videos
# operationId: getVideoChannelVideos
export def "video-channels-videos get" [
  channel_handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($channel_handle | is-empty) { error make --unspanned { msg: "path parameter 'channelHandle' must be non-empty" } }
  let qp = [(serialize-qp "categoryOneOf" $category_one_of "scalar") (serialize-qp "isLive" $is_live "scalar") (serialize-qp "tagsOneOf" $tags_one_of "scalar") (serialize-qp "tagsAllOf" $tags_all_of "scalar") (serialize-qp "licenceOneOf" $licence_one_of "scalar") (serialize-qp "languageOneOf" $language_one_of "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $is_local "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacy_one_of "scalar") (serialize-qp "hasHLSFiles" $has_hls_files "scalar") (serialize-qp "hasWebtorrentFiles" $has_webtorrent_files "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_handle: (encode-path-segment $channel_handle)} | format pattern "/api/v1/video-channels/{channel_handle}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"categoryOneOf": $category_one_of, "isLive": $is_live, "tagsOneOf": $tags_one_of, "tagsAllOf": $tags_all_of, "licenceOneOf": $licence_one_of, "languageOneOf": $language_one_of, "nsfw": $nsfw, "isLocal": $is_local, "include": $include, "privacyOneOf": $privacy_one_of, "hasHLSFiles": $has_hls_files, "hasWebtorrentFiles": $has_webtorrent_files, "skipCount": $skip_count, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# List video playlists
#
# GET /api/v1/video-playlists
# operationId: getPlaylists
export def "video-playlists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string # Sort column (e.g. -createdAt)
  --playlist-type: int@playlist-type-completer
]: nothing -> record<data: table<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record, privacy: record, shortUUID: record, thumbnailPath: string, type: record, updatedAt: string, uuid: string, videoChannel: record, videoLength: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "playlistType" $playlist_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/video-playlists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort, "playlistType": $playlist_type} | compact), body: null}
}

# Create a video playlist
#
# POST /api/v1/video-playlists
# operationId: addPlaylist
export def "video-playlists create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Video playlist description
  display_name: string # Video playlist display name
  --privacy: int@privacy-completer # Video playlist privacy policy (see [/video-playlists/privacies])
  --thumbnailfile: string # Video playlist thumbnail file (format: binary)
  --video-channel-id: any # Video channel in which the playlist will be published
]: any -> record<videoPlaylist: record<id: int, shortUUID: string, uuid: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-playlists")
  let req_body = {"description": $description, "displayName": $display_name, "privacy": $privacy, "thumbnailfile": $thumbnailfile, "videoChannelId": $video_channel_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["thumbnailfile"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# List available playlist privacy policies
#
# GET /api/v1/video-playlists/privacies
# operationId: getPlaylistPrivacyPolicies
export def "video-playlists-privacies get-privacy-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/video-playlists/privacies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a video playlist
#
# DELETE /api/v1/video-playlists/{playlistId}
export def "video-playlists delete" [
  playlist_id: int
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
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id)} | format pattern "/api/v1/video-playlists/{playlist_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a video playlist
#
# GET /api/v1/video-playlists/{playlistId}
export def "video-playlists get" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, description: string, displayName: string, id: int, isLocal: bool, ownerAccount: record<avatars: list<record>, displayName: string, host: string, id: int, name: string, url: string>, privacy: record<id: int, label: string>, shortUUID: record, thumbnailPath: string, type: record<id: int, label: string>, updatedAt: string, uuid: string, videoChannel: record<avatars: list<record>, displayName: string, host: string, id: int, name: string, url: string>, videoLength: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id)} | format pattern "/api/v1/video-playlists/{playlist_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a video playlist
#
# PUT /api/v1/video-playlists/{playlistId}
export def "video-playlists update" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string # Video playlist description
  --display-name: string # Video playlist display name
  --privacy: int@privacy-completer # Video playlist privacy policy (see [/video-playlists/privacies])
  --thumbnailfile: string # Video playlist thumbnail file (format: binary)
  --video-channel-id: any # Video channel in which the playlist will be published
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id)} | format pattern "/api/v1/video-playlists/{playlist_id}"))
  let req_body = {"description": $description, "displayName": $display_name, "privacy": $privacy, "thumbnailfile": $thumbnailfile, "videoChannelId": $video_channel_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["thumbnailfile"] $dry_run)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# List videos of a playlist
#
# GET /api/v1/video-playlists/{playlistId}/videos
# operationId: getVideoPlaylistVideos
export def "video-playlists-videos get" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id)} | format pattern "/api/v1/video-playlists/{playlist_id}/videos") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count} | compact), body: null}
}

# Add a video in a playlist
#
# POST /api/v1/video-playlists/{playlistId}/videos
# operationId: addVideoPlaylistVideo
export def "video-playlists-videos create" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-timestamp: int # Start the video at this specific timestamp (format: seconds)
  --stop-timestamp: int # Stop the video at this specific timestamp (format: seconds)
  video_id: any # Video to add in the playlist
]: any -> record<videoPlaylistElement: record<id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id)} | format pattern "/api/v1/video-playlists/{playlist_id}/videos"))
  let req_body = {"startTimestamp": $start_timestamp, "stopTimestamp": $stop_timestamp, "videoId": $video_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reorder a playlist
#
# POST /api/v1/video-playlists/{playlistId}/videos/reorder
# operationId: reorderVideoPlaylist
export def "video-playlists-videos-reorder create" [
  playlist_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  insert_after_position: int # New position for the block to reorder, to add the block before the first element
  --reorder-length: int # How many element from `startPosition` to reorder
  start_position: int # Start position of the element to reorder
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id)} | format pattern "/api/v1/video-playlists/{playlist_id}/videos/reorder"))
  let req_body = {"insertAfterPosition": $insert_after_position, "reorderLength": $reorder_length, "startPosition": $start_position} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete an element from a playlist
#
# DELETE /api/v1/video-playlists/{playlistId}/videos/{playlistElementId}
# operationId: delVideoPlaylistVideo
export def "video-playlists-videos delete" [
  playlist_id: int
  playlist_element_id: int
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
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  if ($playlist_element_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistElementId' must be non-empty" } }
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id), playlist_element_id: (encode-path-segment $playlist_element_id)} | format pattern "/api/v1/video-playlists/{playlist_id}/videos/{playlist_element_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a playlist element
#
# PUT /api/v1/video-playlists/{playlistId}/videos/{playlistElementId}
# operationId: putVideoPlaylistVideo
export def "video-playlists-videos update" [
  playlist_id: int
  playlist_element_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-timestamp: int # Start the video at this specific timestamp (format: seconds)
  --stop-timestamp: int # Stop the video at this specific timestamp (format: seconds)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($playlist_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistId' must be non-empty" } }
  if ($playlist_element_id | is-empty) { error make --unspanned { msg: "path parameter 'playlistElementId' must be non-empty" } }
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id), playlist_element_id: (encode-path-segment $playlist_element_id)} | format pattern "/api/v1/video-playlists/{playlist_id}/videos/{playlist_element_id}"))
  let req_body = {"startTimestamp": $start_timestamp, "stopTimestamp": $stop_timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List videos
#
# GET /api/v1/videos
# operationId: getVideos
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
  --category-one-of: string # category id of the video (see [/videos/categories](#operation/getCategories))
  --is-live: oneof<nothing, bool> # whether or not the video is a live
  --tags-one-of: string # tag(s) of the video
  --tags-all-of: string # tag(s) of the video, where all should be present in the video
  --licence-one-of: string # licence id of the video (see [/videos/licences](#operation/getLicences))
  --language-one-of: string # language id of the video (see [/videos/languages](#operation/getLanguages)). Use `_unknown` to filter on videos that don't have a video language
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
  --skip-count: string@skip-count-completer # if you don't need the `total` in the response (default: false)
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-2
]: nothing -> record<data: table<account: record, blacklisted: bool, blacklistedReason: string, category: record, channel: record, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record, licence: record, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record, publishedAt: string, scheduledUpdate: record, shortUUID: record, state: record, thumbnailPath: string, updatedAt: string, userHistory: record, uuid: record, views: int, waitTranscoding: bool>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categoryOneOf" $category_one_of "scalar") (serialize-qp "isLive" $is_live "scalar") (serialize-qp "tagsOneOf" $tags_one_of "scalar") (serialize-qp "tagsAllOf" $tags_all_of "scalar") (serialize-qp "licenceOneOf" $licence_one_of "scalar") (serialize-qp "languageOneOf" $language_one_of "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $is_local "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacy_one_of "scalar") (serialize-qp "hasHLSFiles" $has_hls_files "scalar") (serialize-qp "hasWebtorrentFiles" $has_webtorrent_files "scalar") (serialize-qp "skipCount" $skip_count "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"categoryOneOf": $category_one_of, "isLive": $is_live, "tagsOneOf": $tags_one_of, "tagsAllOf": $tags_all_of, "licenceOneOf": $licence_one_of, "languageOneOf": $language_one_of, "nsfw": $nsfw, "isLocal": $is_local, "include": $include, "privacyOneOf": $privacy_one_of, "hasHLSFiles": $has_hls_files, "hasWebtorrentFiles": $has_webtorrent_files, "skipCount": $skip_count, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# List video blocks
#
# GET /api/v1/videos/blacklist
# operationId: getVideoBlocks
export def "videos-blacklist get-blocks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: int@type-completer # list only blocks that match this type: - `1`: manual block - `2`: automatic block that needs review
  --search: string # plain search that will match with video titles, and more
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-7 # Sort blocklists by criteria
]: nothing -> record<data: table<createdAt: string, description: string, dislikes: int, duration: int, id: int, likes: int, name: string, nsfw: bool, updatedAt: string, uuid: string, videoId: int, views: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/blacklist" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type, "search": $search, "start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# List available video categories
#
# GET /api/v1/videos/categories
# operationId: getCategories
export def "videos-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Import a video
#
# POST /api/v1/videos/imports
# operationId: importVideo
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
export def "videos-imports import" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channel_id: int # Channel id that will contain this video (e.g. 3)
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originally-published-at: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --schedule-update: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --wait-transcoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
]: any -> record<video: record<id: int, shortUUID: string, uuid: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/imports")
  let req_body = {"category": $category, "channelId": $channel_id, "commentsEnabled": $comments_enabled, "description": $description, "downloadEnabled": $download_enabled, "language": $language, "licence": $licence, "name": $name, "nsfw": $nsfw, "originallyPublishedAt": $originally_published_at, "previewfile": $previewfile, "privacy": $privacy, "scheduleUpdate": $schedule_update, "support": $support, "tags": $tags, "thumbnailfile": $thumbnailfile, "waitTranscoding": $wait_transcoding} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["previewfile" "thumbnailfile"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Delete video import
#
# DELETE /api/v1/videos/imports/{id}
export def "videos-imports delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/imports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel video import
#
# POST /api/v1/videos/imports/{id}/cancel
export def "videos-imports-cancel create" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/imports/{id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List available video languages
#
# GET /api/v1/videos/languages
# operationId: getLanguages
export def "videos-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List available video licences
#
# GET /api/v1/videos/licences
# operationId: getLicences
export def "videos-licences get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/licences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a live
#
# POST /api/v1/videos/live
# operationId: addLive
export def "videos-live create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channel_id: int # Channel id that will contain this live video
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this live video/replay
  --description: string # Live video/replay description
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for the replay of this live video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --latency-mode: int@latency-mode-completer # The live latency mode (Default = `1`, High latency = `2`, Small Latency = `3`)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Live video/replay name
  --nsfw: oneof<nothing, bool> # Whether or not this live video/replay contains sensitive content
  --permanent-live: oneof<nothing, bool> # User can stream multiple times in a permanent live
  --previewfile: string # Live video/replay preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --save-replay: oneof<nothing, bool>
  --support: string # A text tell the audience how to support the creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Live video/replay tags (maximum 5 tags each between 2 and 30 characters)
  --thumbnailfile: string # Live video/replay thumbnail file (format: binary)
]: any -> record<video: record<id: int, shortUUID: string, uuid: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/live")
  let req_body = {"category": $category, "channelId": $channel_id, "commentsEnabled": $comments_enabled, "description": $description, "downloadEnabled": $download_enabled, "language": $language, "latencyMode": $latency_mode, "licence": $licence, "name": $name, "nsfw": $nsfw, "permanentLive": $permanent_live, "previewfile": $previewfile, "privacy": $privacy, "saveReplay": $save_replay, "support": $support, "tags": $tags, "thumbnailfile": $thumbnailfile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["previewfile" "thumbnailfile"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Get information about a live
#
# GET /api/v1/videos/live/{id}
# operationId: getLiveId
export def "videos-live get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<latencyMode: int, permanentLive: bool, rtmpUrl: string, rtmpsUrl: string, saveReplay: bool, streamKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/live/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update information about a live
#
# PUT /api/v1/videos/live/{id}
# operationId: updateLiveId
export def "videos-live update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --latency-mode: int@latency-mode-completer # The live latency mode (Default = `1`, High latency = `2`, Small Latency = `3`)
  --permanent-live: oneof<nothing, bool> # User can stream multiple times in a permanent live
  --save-replay: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/live/{id}"))
  let req_body = {"latencyMode": $latency_mode, "permanentLive": $permanent_live, "saveReplay": $save_replay} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List live sessions
#
# GET /api/v1/videos/live/{id}/sessions
export def "videos-live-sessions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<endDate: string, error: int, id: int, replayVideo: record, startDate: string>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/live/{id}/sessions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List video ownership changes
#
# GET /api/v1/videos/ownership
export def "videos-ownership get" [
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
  let full_url = (build-url $base "/api/v1/videos/ownership")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Accept ownership change request
#
# POST /api/v1/videos/ownership/{id}/accept
export def "videos-ownership-accept create" [
  id: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/ownership/{id}/accept"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Refuse ownership change request
#
# POST /api/v1/videos/ownership/{id}/refuse
export def "videos-ownership-refuse create" [
  id: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/ownership/{id}/refuse"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List available video privacy policies
#
# GET /api/v1/videos/privacies
# operationId: getPrivacyPolicies
export def "videos-privacies get-privacy-policies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/privacies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload a video
#
# POST /api/v1/videos/upload
# operationId: uploadLegacy
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
export def "videos-upload upload-legacy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channel_id: int # Channel id that will contain this video (e.g. 3)
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originally-published-at: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --schedule-update: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --wait-transcoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  videofile: string # Video file (format: binary)
]: any -> record<video: record<id: int, shortUUID: string, uuid: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/upload")
  let req_body = {"category": $category, "channelId": $channel_id, "commentsEnabled": $comments_enabled, "description": $description, "downloadEnabled": $download_enabled, "language": $language, "licence": $licence, "name": $name, "nsfw": $nsfw, "originallyPublishedAt": $originally_published_at, "previewfile": $previewfile, "privacy": $privacy, "scheduleUpdate": $schedule_update, "support": $support, "tags": $tags, "thumbnailfile": $thumbnailfile, "waitTranscoding": $wait_transcoding, "videofile": $videofile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["previewfile" "thumbnailfile" "videofile"] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Cancel the resumable upload of a video, deleting any data uploaded so far
#
# DELETE /api/v1/videos/upload-resumable
# operationId: uploadResumableCancel
export def "videos-upload-resumable cancel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last 12 hours, it is not valid anymore and the upload session has already been deleted with its data ;-)
  --content-length: float # e.g. 0
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_id" $upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/upload-resumable" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Length": $content_length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"upload_id": $upload_id} | compact), body: null}
}

# Initialize the resumable upload of a video
#
# POST /api/v1/videos/upload-resumable
# operationId: uploadResumableInit
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
export def "videos-upload-resumable upload-init" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-upload-content-length: float # Number of bytes that will be uploaded in subsequent requests. Set this value to the size of the file you are uploading. (e.g. 2469036)
  --x-upload-content-type: string # MIME type of the file that you are uploading. Depending on your instance settings, acceptable values might vary. (e.g. video/mp4)
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  channel_id: int # Channel id that will contain this video (e.g. 3)
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description (e.g. **[Want to help to translate this video?](https://weblate.framasoft.org/projects/what-is-peertube-video/)**\r\n\r\n**Take back the control of your videos! [#JoinPeertube](https://joinpeertube.org)** )
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  name: string # Video name (e.g. What is PeerTube?)
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originally-published-at: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --schedule-update: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Video tags (maximum 5 tags each between 2 and 30 characters) (e.g. [framasoft, peertube])
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --wait-transcoding: oneof<nothing, bool> # Whether or not we wait transcoding before publish the video
  filename: string # Video filename including extension (format: filename, e.g. what_is_peertube.mp4)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/videos/upload-resumable")
  let req_body = {"category": $category, "channelId": $channel_id, "commentsEnabled": $comments_enabled, "description": $description, "downloadEnabled": $download_enabled, "language": $language, "licence": $licence, "name": $name, "nsfw": $nsfw, "originallyPublishedAt": $originally_published_at, "previewfile": $previewfile, "privacy": $privacy, "scheduleUpdate": $schedule_update, "support": $support, "tags": $tags, "thumbnailfile": $thumbnailfile, "waitTranscoding": $wait_transcoding, "filename": $filename} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Upload-Content-Length": $x_upload_content_length, "X-Upload-Content-Type": $x_upload_content_type} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Send chunk for the resumable upload of a video
#
# PUT /api/v1/videos/upload-resumable
# operationId: uploadResumable
export def "videos-upload-resumable upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --upload-id: string # Created session id to proceed with. If you didn't send chunks in the last hour, it is not valid anymore and you need to initialize a new upload.
  --content-range: string # Specifies the bytes in the file that the request is uploading. For example, a value of `bytes 0-262143/1000000` shows that the request is sending the first 262144 bytes (256 x 1024) in a 2,469,036 byte file. (e.g. bytes 0-262143/2469036)
  --content-length: float # Size of the chunk that the request is sending. Remember that larger chunks are more efficient. PeerTube's web client uses chunks varying from 1048576 bytes (~1MB) and increases or reduces size depending on connection health. (e.g. 262144)
  --body: string
]: any -> record<video: record<id: int, shortUUID: string, uuid: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "upload_id" $upload_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/videos/upload-resumable" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Content-Range": $content_range, "Content-Length": $content_length} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/octet-stream" $req_body {query: ({"upload_id": $upload_id} | compact), body: $req_body}
}

# Delete a video
#
# DELETE /api/v1/videos/{id}
# operationId: delVideo
export def "videos delete" [
  id: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a video
#
# GET /api/v1/videos/{id}
# operationId: getVideo
export def "videos get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, blacklisted: bool, blacklistedReason: string, category: record<id: int, label: string>, channel: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, banners: list<record>, description: string, displayName: string, isLocal: bool, ownerAccount: record<id: int, uuid: string>, support: string>, createdAt: string, description: string, dislikes: int, duration: int, embedPath: string, id: record, isLive: bool, isLocal: bool, language: record<id: string, label: string>, licence: record<id: int, label: string>, likes: int, name: string, nsfw: bool, originallyPublishedAt: string, previewPath: string, privacy: record<id: int, label: string>, publishedAt: string, scheduledUpdate: record<privacy: int, updateAt: string>, shortUUID: record, state: record<id: int, label: string>, thumbnailPath: string, updatedAt: string, userHistory: record<currentTime: int>, uuid: record, views: int, waitTranscoding: bool, commentsEnabled: bool, descriptionPath: string, downloadEnabled: bool, files: table<fileDownloadUrl: string, fileUrl: string, fps: float, id: int, magnetUri: string, metadataUrl: string, resolution: record, size: int, torrentDownloadUrl: string, torrentUrl: string>, streamingPlaylists: table<id: int, type: int, files: list, playlistUrl: string, redundancies: list, segmentsSha256Url: string>, support: string, tags: list<string>, trackerUrls: list<string>, viewers: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a video
#
# PUT /api/v1/videos/{id}
# operationId: putVideo
# --scheduleUpdate shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
export def "videos update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: int # category id of the video (see [/videos/categories](#operation/getCategories)) (e.g. 15)
  --comments-enabled: oneof<nothing, bool> # Enable or disable comments for this video
  --description: string # Video description
  --download-enabled: oneof<nothing, bool> # Enable or disable downloading for this video
  --language: string # language id of the video (see [/videos/languages](#operation/getLanguages)) (e.g. en)
  --licence: int # licence id of the video (see [/videos/licences](#operation/getLicences)) (e.g. 2)
  --name: string # Video name
  --nsfw: oneof<nothing, bool> # Whether or not this video contains sensitive content
  --originally-published-at: string # Date when the content was originally published (format: date-time)
  --previewfile: string # Video preview file (format: binary)
  --privacy: int@privacy-completer-1 # privacy id of the video (see [/videos/privacies](#operation/getPrivacyPolicies))
  --schedule-update: any # shape: {privacy?: "1"|"2"|"3"|"4", updateAt: string}
  --support: string # A text tell the audience how to support the video creator (e.g. Please support our work on https://soutenir.framasoft.org/en/ <3)
  --tags: list<string> # Video tags (maximum 5 tags each between 2 and 30 characters)
  --thumbnailfile: string # Video thumbnail file (format: binary)
  --wait-transcoding: string # Whether or not we wait transcoding before publish the video
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}"))
  let req_body = {"category": $category, "commentsEnabled": $comments_enabled, "description": $description, "downloadEnabled": $download_enabled, "language": $language, "licence": $licence, "name": $name, "nsfw": $nsfw, "originallyPublishedAt": $originally_published_at, "previewfile": $previewfile, "privacy": $privacy, "scheduleUpdate": $schedule_update, "support": $support, "tags": $tags, "thumbnailfile": $thumbnailfile, "waitTranscoding": $wait_transcoding} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["previewfile" "thumbnailfile"] $dry_run)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# Unblock a video by its id
#
# DELETE /api/v1/videos/{id}/blacklist
# operationId: delVideoBlock
export def "videos-blacklist delete-block" [
  id: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/blacklist"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Block a video
#
# POST /api/v1/videos/{id}/blacklist
# operationId: addVideoBlock
export def "videos-blacklist create-block" [
  id: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/blacklist"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List captions of a video
#
# GET /api/v1/videos/{id}/captions
# operationId: getVideoCaptions
export def "videos-captions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<captionPath: string, language: record>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/captions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a video caption
#
# DELETE /api/v1/videos/{id}/captions/{captionLanguage}
# operationId: delVideoCaption
export def "videos-captions delete" [
  id: string
  caption_language: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($caption_language | is-empty) { error make --unspanned { msg: "path parameter 'captionLanguage' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), caption_language: (encode-path-segment $caption_language)} | format pattern "/api/v1/videos/{id}/captions/{caption_language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add or replace a video caption
#
# PUT /api/v1/videos/{id}/captions/{captionLanguage}
# operationId: addVideoCaption
export def "videos-captions create" [
  id: string
  caption_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --captionfile: string # The file to upload. (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($caption_language | is-empty) { error make --unspanned { msg: "path parameter 'captionLanguage' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), caption_language: (encode-path-segment $caption_language)} | format pattern "/api/v1/videos/{id}/captions/{caption_language}"))
  let req_body = {"captionfile": $captionfile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body ["captionfile"] $dry_run)
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body {query: {}, body: $req_body}
}

# List threads of a video
#
# GET /api/v1/videos/{id}/comment-threads
export def "videos-comment-threads list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start: int # Offset used to paginate results
  --count: int # Number of items to return (default: 15)
  --qp-sort: string@sort-completer-8 # Sort comments by criteria
]: nothing -> record<data: table<account: record, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: record, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/comment-threads") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"start": $start, "count": $count, "sort": $qp_sort} | compact), body: null}
}

# Create a thread
#
# POST /api/v1/videos/{id}/comment-threads
export def "videos-comment-threads create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: any # format: markdown
]: any -> record<comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: record, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/comment-threads"))
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a thread
#
# GET /api/v1/videos/{id}/comment-threads/{threadId}
export def "videos-comment-threads get" [
  id: string
  thread_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<children: list<any>, comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: record, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($thread_id | is-empty) { error make --unspanned { msg: "path parameter 'threadId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), thread_id: (encode-path-segment $thread_id)} | format pattern "/api/v1/videos/{id}/comment-threads/{thread_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete a comment or a reply
#
# DELETE /api/v1/videos/{id}/comments/{commentId}
export def "videos-comments delete" [
  id: string
  comment_id: int
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), comment_id: (encode-path-segment $comment_id)} | format pattern "/api/v1/videos/{id}/comments/{comment_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reply to a thread of a video
#
# POST /api/v1/videos/{id}/comments/{commentId}
export def "videos-comments create" [
  id: string
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: any # format: markdown
]: any -> record<comment: record<account: record<createdAt: string, followersCount: int, followingCount: int, host: string, hostRedundancyAllowed: bool, id: int, name: record, updatedAt: string, url: string, description: string, displayName: string, userId: record>, createdAt: string, deletedAt: string, id: int, inReplyToCommentId: record, isDeleted: bool, text: string, threadId: int, totalReplies: int, totalRepliesFromVideoAuthor: int, updatedAt: string, url: string, videoId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($comment_id | is-empty) { error make --unspanned { msg: "path parameter 'commentId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), comment_id: (encode-path-segment $comment_id)} | format pattern "/api/v1/videos/{id}/comments/{comment_id}"))
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get complete video description
#
# GET /api/v1/videos/{id}/description
# operationId: getVideoDesc
export def "videos-description get-desc" [
  id: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/description"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Request ownership change
#
# POST /api/v1/videos/{id}/give-ownership
export def "videos-give-ownership create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  username: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/give-ownership"))
  let req_body = {"username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Delete video HLS files
#
# DELETE /api/v1/videos/{id}/hls
# operationId: delVideoHLS
export def "videos-hls delete" [
  id: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/hls"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get live session of a replay
#
# GET /api/v1/videos/{id}/live-session
export def "videos-live-session get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<endDate: string, error: int, id: int, replayVideo: record<id: float, shortUUID: string, uuid: string>, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/live-session"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Like/dislike a video
#
# PUT /api/v1/videos/{id}/rate
export def "videos-rate update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rating: string@rating-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/rate"))
  let req_body = {"rating": $rating} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get video source file metadata
#
# POST /api/v1/videos/{id}/source
# operationId: getVideoSource
export def "videos-source get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<filename: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/source"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get overall stats of a video
#
# GET /api/v1/videos/{id}/stats/overall
export def "videos-stats-overall get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Filter stats by start date (format: date-time)
  --end-date: string # Filter stats by end date (format: date-time)
]: nothing -> record<averageWatchTime: float, countries: table<isoCode: string, viewers: float>, totalWatchTime: float, viewersPeak: float, viewersPeakDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/stats/overall") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date} | compact), body: null}
}

# Get retention stats of a video
#
# GET /api/v1/videos/{id}/stats/retention
export def "videos-stats-retention get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<retentionPercent: float, second: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/stats/retention"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get timeserie stats of a video
#
# GET /api/v1/videos/{id}/stats/timeseries/{metric}
export def "videos-stats-timeseries get" [
  id: string
  metric: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Filter stats by start date (format: date-time)
  --end-date: string # Filter stats by end date (format: date-time)
]: nothing -> record<data: table<date: string, value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($metric | is-empty) { error make --unspanned { msg: "path parameter 'metric' must be non-empty" } }
  let qp = [(serialize-qp "startDate" $start_date "scalar") (serialize-qp "endDate" $end_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), metric: (encode-path-segment $metric)} | format pattern "/api/v1/videos/{id}/stats/timeseries/{metric}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"startDate": $start_date, "endDate": $end_date} | compact), body: null}
}

# Create a studio task
#
# POST /api/v1/videos/{id}/studio/edit
export def "videos-studio-edit create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/studio/edit"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/x-www-form-urlencoded" $req_body_wire {query: {}, body: $req_body}
}

# Request video token
#
# POST /api/v1/videos/{id}/token
# operationId: requestVideoToken
export def "videos-token request" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<files: record<expires: string, token: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/token"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a transcoding job
#
# POST /api/v1/videos/{id}/transcoding
# operationId: createVideoTranscoding
export def "videos-transcoding create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  transcoding_type: string@transcoding-type-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/transcoding"))
  let req_body = {"transcodingType": $transcoding_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Notify user is watching a video
#
# POST /api/v1/videos/{id}/views
# operationId: addView
export def "videos-views create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  current_time: int # timestamp within the video, in seconds (format: seconds, e.g. 5)
  --view-event: string@view-event-completer # Event since last viewing call: * `seek` - If the user seeked the video
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/views"))
  let req_body = {"currentTime": $current_time, "viewEvent": $view_event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Set watching progress of a video
#
# PUT /api/v1/videos/{id}/watching
# DEPRECATED
@deprecated
export def "videos-watching update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  current_time: int # timestamp within the video, in seconds (format: seconds, e.g. 5)
  --view-event: string@view-event-completer # Event since last viewing call: * `seek` - If the user seeked the video
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/watching"))
  let req_body = {"currentTime": $current_time, "viewEvent": $view_event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete video WebTorrent files
#
# DELETE /api/v1/videos/{id}/webtorrent
# operationId: delVideoWebTorrent
export def "videos-webtorrent delete-web-torrent" [
  id: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/v1/videos/{id}/webtorrent"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List videos of subscriptions tied to a token
#
# GET /feeds/subscriptions.{format}
# operationId: getSyndicatedSubscriptionVideos
export def "feeds-subscriptions-format get-syndicated-videos" [
  format: string
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
  --account-id: string # limit listing to a specific account
  --qp-token: string # private token allowing access
  --qp-sort: string # Sort column (e.g. -createdAt)
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $is_local "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacy_one_of "scalar") (serialize-qp "hasHLSFiles" $has_hls_files "scalar") (serialize-qp "hasWebtorrentFiles" $has_webtorrent_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/feeds/subscriptions.{format}") $qp)
  let accept_val = ($accept | default "application/atom+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "token": $qp_token, "sort": $qp_sort, "nsfw": $nsfw, "isLocal": $is_local, "include": $include, "privacyOneOf": $privacy_one_of, "hasHLSFiles": $has_hls_files, "hasWebtorrentFiles": $has_webtorrent_files} | compact), body: null}
}

# List comments on videos
#
# GET /feeds/video-comments.{format}
# operationId: getSyndicatedComments
export def "feeds-video-comments-format get-syndicated" [
  format: string
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
  --video-id: string # limit listing to a specific video
  --account-id: string # limit listing to a specific account
  --account-name: string # limit listing to a specific account
  --video-channel-id: string # limit listing to a specific video channel
  --video-channel-name: string # limit listing to a specific video channel
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "videoId" $video_id "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "accountName" $account_name "scalar") (serialize-qp "videoChannelId" $video_channel_id "scalar") (serialize-qp "videoChannelName" $video_channel_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/feeds/video-comments.{format}") $qp)
  let accept_val = ($accept | default "application/atom+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"videoId": $video_id, "accountId": $account_id, "accountName": $account_name, "videoChannelId": $video_channel_id, "videoChannelName": $video_channel_name} | compact), body: null}
}

# List videos
#
# GET /feeds/videos.{format}
# operationId: getSyndicatedVideos
export def "feeds-videos-format get-syndicated" [
  format: string
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
  --account-id: string # limit listing to a specific account
  --account-name: string # limit listing to a specific account
  --video-channel-id: string # limit listing to a specific video channel
  --video-channel-name: string # limit listing to a specific video channel
  --qp-sort: string # Sort column (e.g. -createdAt)
  --nsfw: string@nsfw-completer # whether to include nsfw videos, if any
  --is-local: oneof<nothing, bool> # **PeerTube >= 4.0** Display only local or remote videos
  --include: int@include-completer # **PeerTube >= 4.0** Include additional videos in results (can be combined using bitwise or operator) - `0` NONE - `1` NOT_PUBLISHED_STATE - `2` BLACKLISTED - `4` BLOCKED_OWNER - `8` FILES
  --privacy-one-of: int@privacy-one-of-completer # **PeerTube >= 4.0** Display only videos in this specific privacy/privacies
  --has-hls-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have HLS files
  --has-webtorrent-files: oneof<nothing, bool> # **PeerTube >= 4.0** Display only videos that have WebTorrent files
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($format | is-empty) { error make --unspanned { msg: "path parameter 'format' must be non-empty" } }
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "accountName" $account_name "scalar") (serialize-qp "videoChannelId" $video_channel_id "scalar") (serialize-qp "videoChannelName" $video_channel_name "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "nsfw" $nsfw "scalar") (serialize-qp "isLocal" $is_local "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "privacyOneOf" $privacy_one_of "scalar") (serialize-qp "hasHLSFiles" $has_hls_files "scalar") (serialize-qp "hasWebtorrentFiles" $has_webtorrent_files "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({format: (encode-path-segment $format)} | format pattern "/feeds/videos.{format}") $qp)
  let accept_val = ($accept | default "application/atom+xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "accountName": $account_name, "videoChannelId": $video_channel_id, "videoChannelName": $video_channel_name, "sort": $qp_sort, "nsfw": $nsfw, "isLocal": $is_local, "include": $include, "privacyOneOf": $privacy_one_of, "hasHLSFiles": $has_hls_files, "hasWebtorrentFiles": $has_webtorrent_files} | compact), body: null}
}

# Get private HLS video file
#
# GET /static/streaming-playlists/hls/private/{filename}
export def "static-streaming-playlists-hls-private get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-file-token: string # Video file token [generated](#operation/requestVideoToken) by PeerTube so you don't need to provide an OAuth token in the request header.
  --reinject-video-file-token: oneof<nothing, bool> # Ask the server to reinject videoFileToken in URLs in m3u8 playlist
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let qp = [(serialize-qp "videoFileToken" $video_file_token "scalar") (serialize-qp "reinjectVideoFileToken" $reinject_video_file_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filename: (encode-path-segment $filename)} | format pattern "/static/streaming-playlists/hls/private/{filename}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"videoFileToken": $video_file_token, "reinjectVideoFileToken": $reinject_video_file_token} | compact), body: null}
}

# Get public HLS video file
#
# GET /static/streaming-playlists/hls/{filename}
export def "static-streaming-playlists-hls get" [
  filename: string
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
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let full_url = (build-url $base ({filename: (encode-path-segment $filename)} | format pattern "/static/streaming-playlists/hls/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get private WebTorrent video file
#
# GET /static/webseed/private/{filename}
export def "static-webseed-private get" [
  filename: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-file-token: string # Video file token [generated](#operation/requestVideoToken) by PeerTube so you don't need to provide an OAuth token in the request header.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let qp = [(serialize-qp "videoFileToken" $video_file_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({filename: (encode-path-segment $filename)} | format pattern "/static/webseed/private/{filename}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"videoFileToken": $video_file_token} | compact), body: null}
}

# Get public WebTorrent video file
#
# GET /static/webseed/{filename}
export def "static-webseed get" [
  filename: string
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
  if ($filename | is-empty) { error make --unspanned { msg: "path parameter 'filename' must be non-empty" } }
  let full_url = (build-url $base ({filename: (encode-path-segment $filename)} | format pattern "/static/webseed/{filename}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
