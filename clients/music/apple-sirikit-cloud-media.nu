# Auto-generated client for SiriKit Cloud Media v1.0.2
# Source: https://api.apis.guru/v2/specs/apple.com/sirikit-cloud-media/1.0.2/openapi.json
# Auth: --token flag or $env.SIRIKIT_CLOUD_MEDIA_TOKEN

const BASE_URL = "https://cloudextension-testservice.local/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SIRIKIT_CLOUD_MEDIA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://cloudextension-testservice.local/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def report-completer [] { ["local.command.bookmark" "local.command.dislike" "local.command.like" "local.playing.continued" "local.playing.elapsed" "local.playing.fastForward" "local.playing.fastRewind" "local.playing.paused" "local.playing.scrub" "local.playing.transitioned.naturally" "local.playing.transitioned.queue_replaced" "local.playing.transitioned.skip_next" "local.playing.transitioned.skip_previous" "local.stopped.naturally" "local.stopped.skip_past_end"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "configuration extensionConfiguration" } } | get name | first)
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
export def "configuration extensionConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --Request-Timeout: float
  --User-Agent: string
  --Accept-Language: string
  --If-None-Match: string
  --Cache-Control: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configuration")
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $Request_Timeout, "User-Agent": $User_Agent, "Accept-Language": $Accept_Language, "If-None-Match": $If_None_Match, "Cache-Control": $Cache_Control} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/jose"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# addMedia
#
# POST /intent/addMedia
# operationId: addMediaIntentHandling
export def "intent-add-media addMediaIntentHandling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --Request-Timeout: float
  --User-Agent: string
  --Accept-Language: string
  --body: record
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/intent/addMedia")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $Request_Timeout, "User-Agent": $User_Agent, "Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# playMedia
#
# POST /intent/playMedia
# operationId: playMediaIntentHandling
export def "intent-play-media playMediaIntentHandling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --Request-Timeout: float
  --User-Agent: string
  --Accept-Language: string
  --body: record
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/intent/playMedia")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $Request_Timeout, "User-Agent": $User_Agent, "Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateMediaAffinity
#
# POST /intent/updateMediaAffinity
# operationId: updateMediaAffinityIntentHandling
export def "intent-update-media-affinity updateMediaAffinityIntentHandling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --Request-Timeout: float
  --User-Agent: string
  --Accept-Language: string
  --body: record
]: any -> list<any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/intent/updateMediaAffinity")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $Request_Timeout, "User-Agent": $User_Agent, "Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# playMedia
#
# POST /queues/playMedia
# operationId: playMediaOnQueue
# --constraints shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
# --userActivity shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
export def "queues-play-media playMediaOnQueue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --User-Agent: string
  --Accept-Language: string
  constraints: record # shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
  --userActivity: record # nullable — shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
  version: string
]: any -> record<content: table<attributes: record, control: string, identifier: string, isLive: bool, playIndex: int, url: string>, contentItemsCount: int, controls: record<default: record<activity: record, commands: record, scheme: string>>, identifier: string, insertPointer: record<afterIdentifier: string, replace: bool>, nextContentUrl: string, playPointer: record<contentIdentifier: string, offsetInMillis: int>, prerollSeconds: float, previousContentUrl: string, skipsRemaining: int, version: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/queues/playMedia")
  let body = {constraints: $constraints, userActivity: $userActivity, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "User-Agent": $User_Agent, "Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# updateActivity
#
# POST /queues/updateActivity
# operationId: updateActivityOnQueue
# --constraints shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
# --nowPlaying shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
# --previouslyPlaying shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
# --userActivity shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
export def "queues-update-activity updateActivityOnQueue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string
  --x-applecloudextension-retry-count: float
  --User-Agent: string
  --Accept-Language: string
  --constraints: record # shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
  --nowPlaying: record # shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
  --previouslyPlaying: record # shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
  report: string@report-completer
  timestamp: string # format: date-time
  --userActivity: record # nullable — shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
  version: string
]: any -> record<queue: record<content: list<record>, contentItemsCount: int, controls: record<default: record>, identifier: string, insertPointer: record<afterIdentifier: string, replace: bool>, nextContentUrl: string, playPointer: record<contentIdentifier: string, offsetInMillis: int>, prerollSeconds: float, previousContentUrl: string, skipsRemaining: int, version: string>, userActivity: record<activityType: string, persistentIdentifier: string, title: string, userInfo: record, version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/queues/updateActivity")
  let body = {constraints: $constraints, nowPlaying: $nowPlaying, previouslyPlaying: $previouslyPlaying, report: $report, timestamp: $timestamp, userActivity: $userActivity, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "User-Agent": $User_Agent, "Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
