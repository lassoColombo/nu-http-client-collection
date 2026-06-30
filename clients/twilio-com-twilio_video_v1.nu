# Auto-generated client for Twilio - Video v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_video_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_VIDEO_TOKEN

const BASE_URL = "https://video.twilio.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o TWILIO_VIDEO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://video.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def format-completer [] { ["mp4" "webm"] }
def status-callback-method-completer [] { ["DELETE" "GET" "HEAD" "PATCH" "POST" "PUT"] }
def status-completer [] { ["completed" "deleted" "enqueued" "failed" "processing"] }
def status-completer-1 [] { ["completed" "deleted" "failed" "processing"] }
def media-type-completer [] { ["audio" "data" "video"] }
def status-completer-2 [] { ["completed" "failed" "in-progress"] }
def type-completer [] { ["go" "group" "group-small" "peer-to-peer"] }
def status-completer-3 [] { ["connected" "disconnected"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "composition-hooks list" } } | get name | first)
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

# List of all Recording CompositionHook resources.
#
# GET /v1/CompositionHooks
# operationId: ListCompositionHook
export def "composition-hooks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --enabled: oneof<nothing, bool> # Read only CompositionHook resources with an `enabled` value that matches this parameter.
  --date-created-after: string # Read only CompositionHook resources created on or after this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) datetime with time zone. (format: date-time)
  --date-created-before: string # Read only CompositionHook resources created before this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) datetime with time zone. (format: date-time)
  --friendly-name: string # Read only CompositionHook resources with friendly names that match this string. The match is not case sensitive and can include asterisk `*` characters as wildcard match.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<composition_hooks: table<account_sid: string, audio_sources: list, audio_sources_excluded: list, date_created: string, date_updated: string, enabled: bool, format: string, friendly_name: string, resolution: string, sid: string, status_callback: string, status_callback_method: string, trim: bool, url: string, video_layout: any>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let qp = [(serialize-qp "Enabled" $enabled "scalar") (serialize-qp "DateCreatedAfter" $date_created_after "scalar") (serialize-qp "DateCreatedBefore" $date_created_before "scalar") (serialize-qp "FriendlyName" $friendly_name "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/CompositionHooks" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Enabled": $enabled, "DateCreatedAfter": $date_created_after, "DateCreatedBefore": $date_created_before, "FriendlyName": $friendly_name, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/CompositionHooks
#
# operationId: CreateCompositionHook
export def "composition-hooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-sources: list<string> # An array of track names from the same group room to merge into the compositions created by the composition hook. Can include zero or more track names. A composition triggered by the composition hook includes all audio sources specified in `audio_sources` except those specified in `audio_sources_excluded`. The track names in this parameter can include an asterisk as a wild card character, which matches zero or more characters in a track name. For example, `student*` includes tracks named `student` as well as `studentTeam`.
  --audio-sources-excluded: list<string> # An array of track names to exclude. A composition triggered by the composition hook includes all audio sources specified in `audio_sources` except for those specified in `audio_sources_excluded`. The track names in this parameter can include an asterisk as a wild card character, which matches zero or more characters in a track name. For example, `student*` excludes `student` as well as `studentTeam`. This parameter can also be empty.
  --enabled: oneof<nothing, bool> # Whether the composition hook is active. When `true`, the composition hook will be triggered for every completed Group Room in the account. When `false`, the composition hook will never be triggered.
  --format: string@format-completer
  friendly_name: string # A descriptive string that you create to describe the resource. It can be up to 100 characters long and it must be unique within the account.
  --resolution: string # A string that describes the columns (width) and rows (height) of the generated composed video in pixels. Defaults to `640x480`. The string's format is `{width}x{height}` where: * 16 <= `{width}` <= 1280 * 16 <= `{height}` <= 1280 * `{width}` * `{height}` <= 921,600 Typical values are: * HD = `1280x720` * PAL = `1024x576` * VGA = `640x480` * CIF = `320x240` Note that the `resolution` imposes an aspect ratio to the resulting composition. When the original video tracks are constrained by the aspect ratio, they are scaled to fit. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application on every composition event. If not provided, status callback events will not be dispatched. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --trim: oneof<nothing, bool> # Whether to clip the intervals where there is no active media in the Compositions triggered by the composition hook. The default is `true`. Compositions with `trim` enabled are shorter when the Room is created and no Participant joins for a while as well as if all the Participants leave the room and join later, because those gaps will be removed. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info.
  --video-layout: any # An object that describes the video layout of the composition hook in terms of regions. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info.
]: any -> record<account_sid: string, audio_sources: list<string>, audio_sources_excluded: list<string>, date_created: string, date_updated: string, enabled: bool, format: string, friendly_name: string, resolution: string, sid: string, status_callback: string, status_callback_method: string, trim: bool, url: string, video_layout: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let full_url = (build-url $base "/v1/CompositionHooks" $auth.query)
  let req_body = {"AudioSources": $audio_sources, "AudioSourcesExcluded": $audio_sources_excluded, "Enabled": $enabled, "Format": $format, "FriendlyName": $friendly_name, "Resolution": $resolution, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "Trim": $trim, "VideoLayout": $video_layout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Delete a Recording CompositionHook resource identified by a `CompositionHook SID`.
#
# DELETE /v1/CompositionHooks/{Sid}
# operationId: DeleteCompositionHook
export def "composition-hooks delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/CompositionHooks/{sid}") $auth.query)
  let accept_val = "application/json"
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns a single CompositionHook resource identified by a CompositionHook SID.
#
# GET /v1/CompositionHooks/{Sid}
# operationId: FetchCompositionHook
export def "composition-hooks get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, audio_sources: list<string>, audio_sources_excluded: list<string>, date_created: string, date_updated: string, enabled: bool, format: string, friendly_name: string, resolution: string, sid: string, status_callback: string, status_callback_method: string, trim: bool, url: string, video_layout: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/CompositionHooks/{sid}") $auth.query)
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

# POST /v1/CompositionHooks/{Sid}
#
# operationId: UpdateCompositionHook
export def "composition-hooks update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-sources: list<string> # An array of track names from the same group room to merge into the compositions created by the composition hook. Can include zero or more track names. A composition triggered by the composition hook includes all audio sources specified in `audio_sources` except those specified in `audio_sources_excluded`. The track names in this parameter can include an asterisk as a wild card character, which matches zero or more characters in a track name. For example, `student*` includes tracks named `student` as well as `studentTeam`.
  --audio-sources-excluded: list<string> # An array of track names to exclude. A composition triggered by the composition hook includes all audio sources specified in `audio_sources` except for those specified in `audio_sources_excluded`. The track names in this parameter can include an asterisk as a wild card character, which matches zero or more characters in a track name. For example, `student*` excludes `student` as well as `studentTeam`. This parameter can also be empty.
  --enabled: oneof<nothing, bool> # Whether the composition hook is active. When `true`, the composition hook will be triggered for every completed Group Room in the account. When `false`, the composition hook never triggers.
  --format: string@format-completer
  friendly_name: string # A descriptive string that you create to describe the resource. It can be up to 100 characters long and it must be unique within the account.
  --resolution: string # A string that describes the columns (width) and rows (height) of the generated composed video in pixels. Defaults to `640x480`. The string's format is `{width}x{height}` where: * 16 <= `{width}` <= 1280 * 16 <= `{height}` <= 1280 * `{width}` * `{height}` <= 921,600 Typical values are: * HD = `1280x720` * PAL = `1024x576` * VGA = `640x480` * CIF = `320x240` Note that the `resolution` imposes an aspect ratio to the resulting composition. When the original video tracks are constrained by the aspect ratio, they are scaled to fit. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application on every composition event. If not provided, status callback events will not be dispatched. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --trim: oneof<nothing, bool> # Whether to clip the intervals where there is no active media in the compositions triggered by the composition hook. The default is `true`. Compositions with `trim` enabled are shorter when the Room is created and no Participant joins for a while as well as if all the Participants leave the room and join later, because those gaps will be removed. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info.
  --video-layout: any # A JSON object that describes the video layout of the composition hook in terms of regions. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info.
]: any -> record<account_sid: string, audio_sources: list<string>, audio_sources_excluded: list<string>, date_created: string, date_updated: string, enabled: bool, format: string, friendly_name: string, resolution: string, sid: string, status_callback: string, status_callback_method: string, trim: bool, url: string, video_layout: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/CompositionHooks/{sid}") $auth.query)
  let req_body = {"AudioSources": $audio_sources, "AudioSourcesExcluded": $audio_sources_excluded, "Enabled": $enabled, "Format": $format, "FriendlyName": $friendly_name, "Resolution": $resolution, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "Trim": $trim, "VideoLayout": $video_layout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# GET /v1/CompositionSettings/Default
#
# operationId: FetchCompositionSettings
export def "composition-settings-default get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, aws_credentials_sid: string, aws_s3_url: string, aws_storage_enabled: bool, encryption_enabled: bool, encryption_key_sid: string, friendly_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let full_url = (build-url $base "/v1/CompositionSettings/Default" $auth.query)
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

# POST /v1/CompositionSettings/Default
#
# operationId: CreateCompositionSettings
export def "composition-settings-default create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-credentials-sid: string # The SID of the stored Credential resource.
  --aws-s3-url: string # The URL of the AWS S3 bucket where the compositions should be stored. We only support DNS-compliant URLs like `https://documentation-example-twilio-bucket/compositions`, where `compositions` is the path in which you want the compositions to be stored. This URL accepts only URI-valid characters, as described in the RFC 3986. (format: uri)
  --aws-storage-enabled: oneof<nothing, bool> # Whether all compositions should be written to the `aws_s3_url`. When `false`, all compositions are stored in our cloud.
  --encryption-enabled: oneof<nothing, bool> # Whether all compositions should be stored in an encrypted form. The default is `false`.
  --encryption-key-sid: string # The SID of the Public Key resource to use for encryption.
  friendly_name: string # A descriptive string that you create to describe the resource and show to the user in the console
]: any -> record<account_sid: string, aws_credentials_sid: string, aws_s3_url: string, aws_storage_enabled: bool, encryption_enabled: bool, encryption_key_sid: string, friendly_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let full_url = (build-url $base "/v1/CompositionSettings/Default" $auth.query)
  let req_body = {"AwsCredentialsSid": $aws_credentials_sid, "AwsS3Url": $aws_s3_url, "AwsStorageEnabled": $aws_storage_enabled, "EncryptionEnabled": $encryption_enabled, "EncryptionKeySid": $encryption_key_sid, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# List of all Recording compositions.
#
# GET /v1/Compositions
# operationId: ListComposition
export def "compositions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer # Read only Composition resources with this status. Can be: `enqueued`, `processing`, `completed`, `deleted`, or `failed`.
  --date-created-after: string # Read only Composition resources created on or after this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time with time zone. (format: date-time)
  --date-created-before: string # Read only Composition resources created before this ISO 8601 date-time with time zone. (format: date-time)
  --room-sid: string # Read only Composition resources with this Room SID.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<compositions: table<account_sid: string, audio_sources: list, audio_sources_excluded: list, bitrate: int, date_completed: string, date_created: string, date_deleted: string, duration: int, format: string, links: record, media_external_location: string, resolution: string, room_sid: string, sid: string, size: int, status: string, status_callback: string, status_callback_method: string, trim: bool, url: string, video_layout: any>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "DateCreatedAfter" $date_created_after "scalar") (serialize-qp "DateCreatedBefore" $date_created_before "scalar") (serialize-qp "RoomSid" $room_sid "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Compositions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Status": $status, "DateCreatedAfter": $date_created_after, "DateCreatedBefore": $date_created_before, "RoomSid": $room_sid, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Compositions
#
# operationId: CreateComposition
export def "compositions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-sources: list<string> # An array of track names from the same group room to merge into the new composition. Can include zero or more track names. The new composition includes all audio sources specified in `audio_sources` except for those specified in `audio_sources_excluded`. The track names in this parameter can include an asterisk as a wild card character, which will match zero or more characters in a track name. For example, `student*` includes `student` as well as `studentTeam`. Please, be aware that either video_layout or audio_sources have to be provided to get a valid creation request
  --audio-sources-excluded: list<string> # An array of track names to exclude. The new composition includes all audio sources specified in `audio_sources` except for those specified in `audio_sources_excluded`. The track names in this parameter can include an asterisk as a wild card character, which will match zero or more characters in a track name. For example, `student*` excludes `student` as well as `studentTeam`. This parameter can also be empty.
  --format: string@format-completer
  --resolution: string # A string that describes the columns (width) and rows (height) of the generated composed video in pixels. Defaults to `640x480`. The string's format is `{width}x{height}` where: * 16 <= `{width}` <= 1280 * 16 <= `{height}` <= 1280 * `{width}` * `{height}` <= 921,600 Typical values are: * HD = `1280x720` * PAL = `1024x576` * VGA = `640x480` * CIF = `320x240` Note that the `resolution` imposes an aspect ratio to the resulting composition. When the original video tracks are constrained by the aspect ratio, they are scaled to fit. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info.
  room_sid: string # The SID of the Group Room with the media tracks to be used as composition sources.
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application on every composition event. If not provided, status callback events will not be dispatched. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be: `POST` or `GET` and the default is `POST`. (format: http-method)
  --trim: oneof<nothing, bool> # Whether to clip the intervals where there is no active media in the composition. The default is `true`. Compositions with `trim` enabled are shorter when the Room is created and no Participant joins for a while as well as if all the Participants leave the room and join later, because those gaps will be removed. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info.
  --video-layout: any # An object that describes the video layout of the composition in terms of regions. See [Specifying Video Layouts](https://www.twilio.com/docs/video/api/compositions-resource#specifying-video-layouts) for more info. Please, be aware that either video_layout or audio_sources have to be provided to get a valid creation request
]: any -> record<account_sid: string, audio_sources: list<string>, audio_sources_excluded: list<string>, bitrate: int, date_completed: string, date_created: string, date_deleted: string, duration: int, format: string, links: record, media_external_location: string, resolution: string, room_sid: string, sid: string, size: int, status: string, status_callback: string, status_callback_method: string, trim: bool, url: string, video_layout: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let full_url = (build-url $base "/v1/Compositions" $auth.query)
  let req_body = {"AudioSources": $audio_sources, "AudioSourcesExcluded": $audio_sources_excluded, "Format": $format, "Resolution": $resolution, "RoomSid": $room_sid, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "Trim": $trim, "VideoLayout": $video_layout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# Delete a Recording Composition resource identified by a Composition SID.
#
# DELETE /v1/Compositions/{Sid}
# operationId: DeleteComposition
export def "compositions delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Compositions/{sid}") $auth.query)
  let accept_val = "application/json"
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns a single Composition resource identified by a Composition SID.
#
# GET /v1/Compositions/{Sid}
# operationId: FetchComposition
export def "compositions get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, audio_sources: list<string>, audio_sources_excluded: list<string>, bitrate: int, date_completed: string, date_created: string, date_deleted: string, duration: int, format: string, links: record, media_external_location: string, resolution: string, room_sid: string, sid: string, size: int, status: string, status_callback: string, status_callback_method: string, trim: bool, url: string, video_layout: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Compositions/{sid}") $auth.query)
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

# GET /v1/RecordingSettings/Default
#
# operationId: FetchRecordingSettings
export def "recording-settings-default get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, aws_credentials_sid: string, aws_s3_url: string, aws_storage_enabled: bool, encryption_enabled: bool, encryption_key_sid: string, friendly_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let full_url = (build-url $base "/v1/RecordingSettings/Default" $auth.query)
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

# POST /v1/RecordingSettings/Default
#
# operationId: CreateRecordingSettings
export def "recording-settings-default create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aws-credentials-sid: string # The SID of the stored Credential resource.
  --aws-s3-url: string # The URL of the AWS S3 bucket where the recordings should be stored. We only support DNS-compliant URLs like `https://documentation-example-twilio-bucket/recordings`, where `recordings` is the path in which you want the recordings to be stored. This URL accepts only URI-valid characters, as described in the RFC 3986. (format: uri)
  --aws-storage-enabled: oneof<nothing, bool> # Whether all recordings should be written to the `aws_s3_url`. When `false`, all recordings are stored in our cloud.
  --encryption-enabled: oneof<nothing, bool> # Whether all recordings should be stored in an encrypted form. The default is `false`.
  --encryption-key-sid: string # The SID of the Public Key resource to use for encryption.
  friendly_name: string # A descriptive string that you create to describe the resource and be shown to users in the console
]: any -> record<account_sid: string, aws_credentials_sid: string, aws_s3_url: string, aws_storage_enabled: bool, encryption_enabled: bool, encryption_key_sid: string, friendly_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let full_url = (build-url $base "/v1/RecordingSettings/Default" $auth.query)
  let req_body = {"AwsCredentialsSid": $aws_credentials_sid, "AwsS3Url": $aws_s3_url, "AwsStorageEnabled": $aws_storage_enabled, "EncryptionEnabled": $encryption_enabled, "EncryptionKeySid": $encryption_key_sid, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# List of all Track recordings.
#
# GET /v1/Recordings
# operationId: ListRecording
export def "recordings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Read only the recordings that have this status. Can be: `processing`, `completed`, or `deleted`.
  --source-sid: string # Read only the recordings that have this `source_sid`.
  --grouping-sid: list<string> # Read only recordings with this `grouping_sid`, which may include a `participant_sid` and/or a `room_sid`.
  --date-created-after: string # Read only recordings that started on or after this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time with time zone. (format: date-time)
  --date-created-before: string # Read only recordings that started before this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) date-time with time zone, given as `YYYY-MM-DDThh:mm:ss+|-hh:mm` or `YYYY-MM-DDThh:mm:ssZ`. (format: date-time)
  --media-type: string@media-type-completer # Read only recordings that have this media type. Can be either `audio` or `video`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, recordings: table<account_sid: string, codec: string, container_format: string, date_created: string, duration: int, grouping_sids: any, links: record, media_external_location: string, offset: int, sid: string, size: int, source_sid: string, status: string, status_callback: string, status_callback_method: string, track_name: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "SourceSid" $source_sid "scalar") (serialize-qp "GroupingSid" $grouping_sid "multi") (serialize-qp "DateCreatedAfter" $date_created_after "scalar") (serialize-qp "DateCreatedBefore" $date_created_before "scalar") (serialize-qp "MediaType" $media_type "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Recordings" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Status": $status, "SourceSid": $source_sid, "GroupingSid": $grouping_sid, "DateCreatedAfter": $date_created_after, "DateCreatedBefore": $date_created_before, "MediaType": $media_type, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete a Recording resource identified by a Recording SID.
#
# DELETE /v1/Recordings/{Sid}
# operationId: DeleteRecording
export def "recordings delete" [
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Recordings/{sid}") $auth.query)
  let accept_val = "application/json"
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Returns a single Recording resource identified by a Recording SID.
#
# GET /v1/Recordings/{Sid}
# operationId: FetchRecording
export def "recordings get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, codec: string, container_format: string, date_created: string, duration: int, grouping_sids: any, links: record, media_external_location: string, offset: int, sid: string, size: int, source_sid: string, status: string, status_callback: string, status_callback_method: string, track_name: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Recordings/{sid}") $auth.query)
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

# GET /v1/Rooms
#
# operationId: ListRoom
export def "rooms list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-2 # Read only the rooms with this status. Can be: `in-progress` (default) or `completed`
  --unique-name: string # Read only rooms with the this `unique_name`.
  --date-created-after: string # Read only rooms that started on or after this date, given as `YYYY-MM-DD`. (format: date-time)
  --date-created-before: string # Read only rooms that started before this date, given as `YYYY-MM-DD`. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, rooms: table<account_sid: string, audio_only: bool, date_created: string, date_updated: string, duration: int, empty_room_timeout: int, enable_turn: bool, end_time: string, large_room: bool, links: record, max_concurrent_published_tracks: int, max_participant_duration: int, max_participants: int, media_region: string, record_participants_on_connect: bool, sid: string, status: string, status_callback: string, status_callback_method: string, type: string, unique_name: string, unused_room_timeout: int, url: string, video_codecs: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "UniqueName" $unique_name "scalar") (serialize-qp "DateCreatedAfter" $date_created_after "scalar") (serialize-qp "DateCreatedBefore" $date_created_before "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Rooms" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Status": $status, "UniqueName": $unique_name, "DateCreatedAfter": $date_created_after, "DateCreatedBefore": $date_created_before, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# POST /v1/Rooms
#
# operationId: CreateRoom
export def "rooms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-only: oneof<nothing, bool> # When set to true, indicates that the participants in the room will only publish audio. No video tracks will be allowed. Group rooms only.
  --empty-room-timeout: int # Configures how long (in minutes) a room will remain active after last participant leaves. Valid values range from 1 to 60 minutes (no fractions).
  --enable-turn: oneof<nothing, bool> # Deprecated, now always considered to be true.
  --large-room: oneof<nothing, bool> # When set to true, indicated that this is the large room.
  --max-participant-duration: int # The maximum number of seconds a Participant can be connected to the room. The maximum possible value is 86400 seconds (24 hours). The default is 14400 seconds (4 hours).
  --max-participants: int # The maximum number of concurrent Participants allowed in the room. Peer-to-peer rooms can have up to 10 Participants. Small Group rooms can have up to 4 Participants. Group rooms can have up to 50 Participants.
  --media-region: string # The region for the media server in Group Rooms. Can be: one of the [available Media Regions](https://www.twilio.com/docs/video/ip-address-whitelisting#group-rooms-media-servers). ***This feature is not available in `peer-to-peer` rooms.***
  --record-participants-on-connect: oneof<nothing, bool> # Whether to start recording when Participants connect. ***This feature is not available in `peer-to-peer` rooms.***
  --recording-rules: any # A collection of Recording Rules that describe how to include or exclude matching tracks for recording
  --status-callback: string # The URL we should call using the `status_callback_method` to send status information to your application on every room event. See [Status Callbacks](https://www.twilio.com/docs/video/api/status-callbacks) for more info. (format: uri)
  --status-callback-method: string@status-callback-method-completer # The HTTP method we should use to call `status_callback`. Can be `POST` or `GET`. (format: http-method)
  --type: string@type-completer
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used as a `room_sid` in place of the resource's `sid` in the URL to address the resource, assuming it does not contain any [reserved characters](https://tools.ietf.org/html/rfc3986#section-2.2) that would need to be URL encoded. This value is unique for `in-progress` rooms. SDK clients can use this name to connect to the room. REST API clients can use this name in place of the Room SID to interact with the room as long as the room is `in-progress`.
  --unused-room-timeout: int # Configures how long (in minutes) a room will remain active if no one joins. Valid values range from 1 to 60 minutes (no fractions).
  --video-codecs: list<string> # An array of the video codecs that are supported when publishing a track in the room. Can be: `VP8` and `H264`. ***This feature is not available in `peer-to-peer` rooms***
]: any -> record<account_sid: string, audio_only: bool, date_created: string, date_updated: string, duration: int, empty_room_timeout: int, enable_turn: bool, end_time: string, large_room: bool, links: record, max_concurrent_published_tracks: int, max_participant_duration: int, max_participants: int, media_region: string, record_participants_on_connect: bool, sid: string, status: string, status_callback: string, status_callback_method: string, type: string, unique_name: string, unused_room_timeout: int, url: string, video_codecs: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  let full_url = (build-url $base "/v1/Rooms" $auth.query)
  let req_body = {"AudioOnly": $audio_only, "EmptyRoomTimeout": $empty_room_timeout, "EnableTurn": $enable_turn, "LargeRoom": $large_room, "MaxParticipantDuration": $max_participant_duration, "MaxParticipants": $max_participants, "MediaRegion": $media_region, "RecordParticipantsOnConnect": $record_participants_on_connect, "RecordingRules": $recording_rules, "StatusCallback": $status_callback, "StatusCallbackMethod": $status_callback_method, "Type": $type, "UniqueName": $unique_name, "UnusedRoomTimeout": $unused_room_timeout, "VideoCodecs": $video_codecs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [201]
}

# GET /v1/Rooms/{RoomSid}/Participants
#
# operationId: ListRoomParticipant
export def "rooms-participants list" [
  room_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3 # Read only the participants with this status. Can be: `connected` or `disconnected`. For `in-progress` Rooms the default Status is `connected`, for `completed` Rooms only `disconnected` Participants are returned.
  --identity: string # Read only the Participants with this [User](https://www.twilio.com/docs/chat/rest/user-resource) `identity` value.
  --date-created-after: string # Read only Participants that started after this date in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601#UTC) format. (format: date-time)
  --date-created-before: string # Read only Participants that started before this date in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601#UTC) format. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, date_created: string, date_updated: string, duration: int, end_time: string, identity: string, links: record, room_sid: string, sid: string, start_time: string, status: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "Identity" $identity "scalar") (serialize-qp "DateCreatedAfter" $date_created_after "scalar") (serialize-qp "DateCreatedBefore" $date_created_before "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid)} | format pattern "/v1/Rooms/{room_sid}/Participants") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Status": $status, "Identity": $identity, "DateCreatedAfter": $date_created_after, "DateCreatedBefore": $date_created_before, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a list of tracks associated with a given Participant. Only `currently` Published Tracks are in the list resource.
#
# GET /v1/Rooms/{RoomSid}/Participants/{ParticipantSid}/PublishedTracks
# operationId: ListRoomParticipantPublishedTrack
export def "rooms-participants-published-tracks list" [
  room_sid: string
  participant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, published_tracks: table<date_created: string, date_updated: string, enabled: bool, kind: string, name: string, participant_sid: string, room_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($participant_sid | is-empty) { error make --unspanned { msg: "path parameter 'ParticipantSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), participant_sid: (encode-path-segment $participant_sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{participant_sid}/PublishedTracks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a single Track resource represented by TrackName or SID.
#
# GET /v1/Rooms/{RoomSid}/Participants/{ParticipantSid}/PublishedTracks/{Sid}
# operationId: FetchRoomParticipantPublishedTrack
export def "rooms-participants-published-tracks get" [
  room_sid: string
  participant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<date_created: string, date_updated: string, enabled: bool, kind: string, name: string, participant_sid: string, room_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($participant_sid | is-empty) { error make --unspanned { msg: "path parameter 'ParticipantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), participant_sid: (encode-path-segment $participant_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{participant_sid}/PublishedTracks/{sid}") $auth.query)
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

# Returns a list of Subscribe Rules for the Participant.
#
# GET /v1/Rooms/{RoomSid}/Participants/{ParticipantSid}/SubscribeRules
# operationId: FetchRoomParticipantSubscribeRule
export def "rooms-participants-subscribe-rules get" [
  room_sid: string
  participant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<date_created: string, date_updated: string, participant_sid: string, room_sid: string, rules: table<all: bool, kind: string, priority: string, publisher: string, track: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($participant_sid | is-empty) { error make --unspanned { msg: "path parameter 'ParticipantSid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), participant_sid: (encode-path-segment $participant_sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{participant_sid}/SubscribeRules") $auth.query)
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

# Update the Subscribe Rules for the Participant
#
# POST /v1/Rooms/{RoomSid}/Participants/{ParticipantSid}/SubscribeRules
# operationId: UpdateRoomParticipantSubscribeRule
export def "rooms-participants-subscribe-rules update" [
  room_sid: string
  participant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: any # A JSON-encoded array of subscribe rules. See the [Specifying Subscribe Rules](https://www.twilio.com/docs/video/api/track-subscriptions#specifying-sr) section for further information.
]: any -> record<date_created: string, date_updated: string, participant_sid: string, room_sid: string, rules: table<all: bool, kind: string, priority: string, publisher: string, track: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($participant_sid | is-empty) { error make --unspanned { msg: "path parameter 'ParticipantSid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), participant_sid: (encode-path-segment $participant_sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{participant_sid}/SubscribeRules") $auth.query)
  let req_body = {"Rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [202]
}

# Returns a list of tracks that are subscribed for the participant.
#
# GET /v1/Rooms/{RoomSid}/Participants/{ParticipantSid}/SubscribedTracks
# operationId: ListRoomParticipantSubscribedTrack
export def "rooms-participants-subscribed-tracks list" [
  room_sid: string
  participant_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, subscribed_tracks: table<date_created: string, date_updated: string, enabled: bool, kind: string, name: string, participant_sid: string, publisher_sid: string, room_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($participant_sid | is-empty) { error make --unspanned { msg: "path parameter 'ParticipantSid' must be non-empty" } }
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), participant_sid: (encode-path-segment $participant_sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{participant_sid}/SubscribedTracks") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns a single Track resource represented by `track_sid`. Note: This is one resource with the Video API that requires a SID, be Track Name on the subscriber side is not guaranteed to be unique.
#
# GET /v1/Rooms/{RoomSid}/Participants/{ParticipantSid}/SubscribedTracks/{Sid}
# operationId: FetchRoomParticipantSubscribedTrack
export def "rooms-participants-subscribed-tracks get" [
  room_sid: string
  participant_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<date_created: string, date_updated: string, enabled: bool, kind: string, name: string, participant_sid: string, publisher_sid: string, room_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($participant_sid | is-empty) { error make --unspanned { msg: "path parameter 'ParticipantSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), participant_sid: (encode-path-segment $participant_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{participant_sid}/SubscribedTracks/{sid}") $auth.query)
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

# GET /v1/Rooms/{RoomSid}/Participants/{Sid}
#
# operationId: FetchRoomParticipant
export def "rooms-participants get" [
  room_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, duration: int, end_time: string, identity: string, links: record, room_sid: string, sid: string, start_time: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{sid}") $auth.query)
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

# POST /v1/Rooms/{RoomSid}/Participants/{Sid}
#
# operationId: UpdateRoomParticipant
export def "rooms-participants update" [
  room_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-3
]: any -> record<account_sid: string, date_created: string, date_updated: string, duration: int, end_time: string, identity: string, links: record, room_sid: string, sid: string, start_time: string, status: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{sid}") $auth.query)
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}

# POST /v1/Rooms/{RoomSid}/Participants/{Sid}/Anonymize
#
# operationId: UpdateRoomParticipantAnonymize
export def "rooms-participants-anonymize update" [
  room_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, duration: int, end_time: string, identity: string, room_sid: string, sid: string, start_time: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{room_sid}/Participants/{sid}/Anonymize") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
}

# Returns a list of Recording Rules for the Room.
#
# GET /v1/Rooms/{RoomSid}/RecordingRules
# operationId: FetchRoomRecordingRule
export def "rooms-recording-rules get" [
  room_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<date_created: string, date_updated: string, room_sid: string, rules: table<all: bool, kind: string, publisher: string, track: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid)} | format pattern "/v1/Rooms/{room_sid}/RecordingRules") $auth.query)
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

# Update the Recording Rules for the Room
#
# POST /v1/Rooms/{RoomSid}/RecordingRules
# operationId: UpdateRoomRecordingRule
export def "rooms-recording-rules update" [
  room_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rules: any # A JSON-encoded array of recording rules.
]: any -> record<date_created: string, date_updated: string, room_sid: string, rules: table<all: bool, kind: string, publisher: string, track: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid)} | format pattern "/v1/Rooms/{room_sid}/RecordingRules") $auth.query)
  let req_body = {"Rules": $rules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [202]
}

# GET /v1/Rooms/{RoomSid}/Recordings
#
# operationId: ListRoomRecording
export def "rooms-recordings list" [
  room_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string@status-completer-1 # Read only the recordings with this status. Can be: `processing`, `completed`, or `deleted`.
  --source-sid: string # Read only the recordings that have this `source_sid`.
  --date-created-after: string # Read only recordings that started on or after this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) datetime with time zone. (format: date-time)
  --date-created-before: string # Read only Recordings that started before this [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) datetime with time zone. (format: date-time)
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, recordings: table<account_sid: string, codec: string, container_format: string, date_created: string, duration: int, grouping_sids: any, links: record, media_external_location: string, offset: int, room_sid: string, sid: string, size: int, source_sid: string, status: string, track_name: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  let qp = [(serialize-qp "Status" $status "scalar") (serialize-qp "SourceSid" $source_sid "scalar") (serialize-qp "DateCreatedAfter" $date_created_after "scalar") (serialize-qp "DateCreatedBefore" $date_created_before "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid)} | format pattern "/v1/Rooms/{room_sid}/Recordings") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"Status": $status, "SourceSid": $source_sid, "DateCreatedAfter": $date_created_after, "DateCreatedBefore": $date_created_before, "PageSize": $page_size, "Page": $page, "PageToken": $page_token} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# DELETE /v1/Rooms/{RoomSid}/Recordings/{Sid}
#
# operationId: DeleteRoomRecording
export def "rooms-recordings delete" [
  room_sid: string
  sid: string
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
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{room_sid}/Recordings/{sid}") $auth.query)
  let accept_val = "application/json"
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
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# GET /v1/Rooms/{RoomSid}/Recordings/{Sid}
#
# operationId: FetchRoomRecording
export def "rooms-recordings get" [
  room_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, codec: string, container_format: string, date_created: string, duration: int, grouping_sids: any, links: record, media_external_location: string, offset: int, room_sid: string, sid: string, size: int, source_sid: string, status: string, track_name: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($room_sid | is-empty) { error make --unspanned { msg: "path parameter 'RoomSid' must be non-empty" } }
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({room_sid: (encode-path-segment $room_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{room_sid}/Recordings/{sid}") $auth.query)
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

# GET /v1/Rooms/{Sid}
#
# operationId: FetchRoom
export def "rooms get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, audio_only: bool, date_created: string, date_updated: string, duration: int, empty_room_timeout: int, enable_turn: bool, end_time: string, large_room: bool, links: record, max_concurrent_published_tracks: int, max_participant_duration: int, max_participants: int, media_region: string, record_participants_on_connect: bool, sid: string, status: string, status_callback: string, status_callback_method: string, type: string, unique_name: string, unused_room_timeout: int, url: string, video_codecs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{sid}") $auth.query)
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

# POST /v1/Rooms/{Sid}
#
# operationId: UpdateRoom
export def "rooms update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  status: string@status-completer-2
]: any -> record<account_sid: string, audio_only: bool, date_created: string, date_updated: string, duration: int, empty_room_timeout: int, enable_turn: bool, end_time: string, large_room: bool, links: record, max_concurrent_published_tracks: int, max_participant_duration: int, max_participants: int, media_region: string, record_participants_on_connect: bool, sid: string, status: string, status_callback: string, status_callback_method: string, type: string, unique_name: string, unused_room_timeout: int, url: string, video_codecs: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://video.twilio.com")
  if ($sid | is-empty) { error make --unspanned { msg: "path parameter 'Sid' must be non-empty" } }
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Rooms/{sid}") $auth.query)
  let req_body = {"Status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body_wire = (if (($req_body | describe) | str starts-with "record") { $req_body | transpose k v | where v != null | reduce -f {} {|p, acc| $acc | upsert $p.k $p.v } | url build-query } else if ($req_body == null) { "" } else { $req_body | into string })
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/x-www-form-urlencoded"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body_wire $insecure $raw $allow_errors $full [200]
}
