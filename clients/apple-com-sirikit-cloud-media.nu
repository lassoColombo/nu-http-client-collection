# Auto-generated client for SiriKit Cloud Media v1.0.2
# Source: https://api.apis.guru/v2/specs/apple.com/sirikit-cloud-media/1.0.2/openapi.json
# Auth: --token flag or $env.SIRIKIT_CLOUD_MEDIA_TOKEN

const BASE_URL = "https://cloudextension-testservice.local/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SIRIKIT_CLOUD_MEDIA_TOKEN | default "" }
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

def base-url-completer [] { ["https://cloudextension-testservice.local/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def report-completer [] { ["local.command.bookmark" "local.command.dislike" "local.command.like" "local.playing.continued" "local.playing.elapsed" "local.playing.fastForward" "local.playing.fastRewind" "local.playing.paused" "local.playing.scrub" "local.playing.transitioned.naturally" "local.playing.transitioned.queue_replaced" "local.playing.transitioned.skip_next" "local.playing.transitioned.skip_previous" "local.stopped.naturally" "local.stopped.skip_past_end"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "configuration get-extension" } } | get name | first)
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

# Configuration Resource
#
# GET /configuration
# operationId: extensionConfiguration
export def "configuration get-extension" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --request-timeout: float
  --user-agent: string
  --accept-language: string
  --if-none-match: string
  --cache-control: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration")
  let accept_val = "application/jose"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $request_timeout, "User-Agent": $user_agent, "Accept-Language": $accept_language, "If-None-Match": $if_none_match, "Cache-Control": $cache_control} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# addMedia
#
# POST /intent/addMedia
# operationId: addMediaIntentHandling
export def "intent-add-media create-handling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --request-timeout: float
  --user-agent: string
  --accept-language: string
  --body: list
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/intent/addMedia")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $request_timeout, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# playMedia
#
# POST /intent/playMedia
# operationId: playMediaIntentHandling
export def "intent-play-media create-handling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --request-timeout: float
  --user-agent: string
  --accept-language: string
  --body: list
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/intent/playMedia")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $request_timeout, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# updateMediaAffinity
#
# POST /intent/updateMediaAffinity
# operationId: updateMediaAffinityIntentHandling
export def "intent-update-media-affinity update-handling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --request-timeout: float
  --user-agent: string
  --accept-language: string
  --body: list
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/intent/updateMediaAffinity")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $request_timeout, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# playMedia
#
# POST /queues/playMedia
# operationId: playMediaOnQueue
# --constraints shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
# --userActivity shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
export def "queues-play-media create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --user-agent: string
  --accept-language: string
  constraints: record # shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
  --user-activity: record # nullable — shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
  version: string
]: any -> record<content: table<attributes: record, control: string, identifier: string, isLive: bool, playIndex: int, url: string>, contentItemsCount: int, controls: record<default: record<activity: record, commands: record, scheme: string>>, identifier: string, insertPointer: record<afterIdentifier: string, replace: bool>, nextContentUrl: string, playPointer: record<contentIdentifier: string, offsetInMillis: int>, prerollSeconds: float, previousContentUrl: string, skipsRemaining: int, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/queues/playMedia")
  let req_body = {"constraints": $constraints, "userActivity": $user_activity, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# updateActivity
#
# POST /queues/updateActivity
# operationId: updateActivityOnQueue
# --constraints shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
# --nowPlaying shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
# --previouslyPlaying shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
# --userActivity shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
export def "queues-update-activity update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --user-agent: string
  --accept-language: string
  --constraints: record # shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
  --now-playing: record # shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
  --previously-playing: record # shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
  report: string@report-completer
  timestamp: string # format: date-time
  --user-activity: record # nullable — shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
  version: string
]: any -> record<queue: record<content: list<record>, contentItemsCount: int, controls: record<default: record>, identifier: string, insertPointer: record<afterIdentifier: string, replace: bool>, nextContentUrl: string, playPointer: record<contentIdentifier: string, offsetInMillis: int>, prerollSeconds: float, previousContentUrl: string, skipsRemaining: int, version: string>, userActivity: record<activityType: string, persistentIdentifier: string, title: string, userInfo: record, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/queues/updateActivity")
  let req_body = {"constraints": $constraints, "nowPlaying": $now_playing, "previouslyPlaying": $previously_playing, "report": $report, "timestamp": $timestamp, "userActivity": $user_activity, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
