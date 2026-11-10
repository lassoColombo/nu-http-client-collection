# Auto-generated client for SiriKit Cloud Media v1.0.2
# Source: https://api.apis.guru/v2/specs/apple.com/sirikit-cloud-media/1.0.2/openapi.json
# Auth: --token flag or $env.SIRIKIT_CLOUD_MEDIA_TOKEN

const BASE_URL = "https://cloudextension-testservice.local/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SIRIKIT_CLOUD_MEDIA_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style.
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record value follows OpenAPI object serialization: "multi" (form +
# explode) is bare `k=v` pairs, "csv"/"ssv"/"tsv"/"pipes" (no explode) is
# `name=k,v,k,v` with that delimiter, anything else is deepObject
# `name[k]=v`. Null members and null list elements are skipped.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  # A list of records describes as `table<…>`, not `list<…>`.
  let is_list = (($value | describe) =~ '^(list|table)')
  let value = if $is_list { $value | compact } else { $value }
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  let sep = (match $style { "ssv" => "%20", "tsv" => "%09", "pipes" => "|", _ => "," })
  if ($value | describe | str starts-with "record") {
    let pairs = ($value | transpose k v | where v != null)
    return (match $style {
      "multi" => { $pairs | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } }
      "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($pairs | each {|p| [(encode-path-segment $p.k) (encode-path-segment $p.v)] } | flatten | str join $sep)"] }
      _ => { $pairs | each {|p| $"($n)[(encode-path-segment $p.k)]=(encode-path-segment $p.v)" } }
    })
  }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "csv" | "ssv" | "tsv" | "pipes" => { [$"($n)=($value | each { encode-path-segment $in } | str join $sep)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
  }
}

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# A record or list (an array-of-object query param's element) has no scalar
# form, so it is sent as compact JSON, the convention the multipart builder
# uses for structured text parts. `null` encodes as the empty string.
def encode-path-segment [v: any]: nothing -> string {
  if $v == null { return "" }
  let text = if (($v | describe) =~ '^(record|list|table)') { $v | to json --raw } else { $v | into string }
  $text | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | compact | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Serialize a greedy path label (AWS `{Key+}`): the value spans segments, so
# each `/`-separated piece is RFC-3986-encoded on its own and the slashes stay.
# Only a scalar is a path: null and structured values have no slashes to keep
# and take encode-path-segment's form (empty / compact JSON) unchanged.
def encode-path-greedy [v: any]: nothing -> string {
  if ($v == null) or (($v | describe) =~ '^(record|list|table)') { return (encode-path-segment $v) }
  $v | into string | split row "/" | each { encode-path-segment $in } | str join "/"
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
# Only the seam between the base path and `path` is normalized to one `/`:
# slashes inside `path` are data (the S3 keys `dir//f` and `dir/f` differ).
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { $"($parsed.path | str trim --right --char '/')/($path | str trim --left --char '/')" }
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

# Merge pipeline input into the body assembled from flags. A piped record
# merges deep under the flags (a flag wins on a shared key). `accepts` says
# what else the body may be: "list" takes a piped list whole (a oneOf/anyOf
# array variant), "scalar" takes any other piped value when the flags gave
# nothing (a string/opaque body), "record" takes nothing else.
def merge-body-input [input: any, req_body: any, accepts: string]: nothing -> any {
  let input_type = ($input | describe)
  if ($input_type | str starts-with "record") { return ($input | merge deep ($req_body | default {})) }
  match $accepts {
    "list" => { if ($input_type =~ '^(list|table)') { $input } else { $req_body } }
    "scalar" => { if ($input | is-not-empty) and ($req_body | is-empty) { $input } else { $req_body } }
    _ => $req_body
  }
}

# Merge `extra` headers over `base`: the right side wins, as with `merge`,
# except for `Cookie`. A request carries all its cookies in one header
# (RFC 6265 §5.4), so both sides' cookie strings are kept, joined with `; `.
# A plain `merge` would let a cookie param drop a cookie-located auth token.
def merge-headers [base: record, extra: record]: nothing -> record {
  let cookie = ([$base.Cookie? $extra.Cookie?] | where {|c| $c | is-not-empty } | str join "; ")
  let merged = ($base | merge $extra | reject -o Cookie)
  if ($cookie | is-empty) { $merged } else { $merged | insert Cookie $cookie }
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url
  $resp | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://cloudextension-testservice.local/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def report-completer [] { ["local.command.bookmark" "local.command.dislike" "local.command.like" "local.playing.continued" "local.playing.elapsed" "local.playing.fastForward" "local.playing.fastRewind" "local.playing.paused" "local.playing.scrub" "local.playing.transitioned.naturally" "local.playing.transitioned.queue_replaced" "local.playing.transitioned.skip_next" "local.playing.transitioned.skip_previous" "local.stopped.naturally" "local.stopped.skip_past_end"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { ($in.commands | get name | sort) == (["extension-configuration" "add-media-intent-handling" "play-media-intent-handling" "update-media-affinity-intent-handling" "play-media-on-queue" "update-activity-on-queue" "commands"] | sort) } | get name | first)
  let mod_cmds = (scope modules | where name == $mod_name | get commands | first)
  let cmd_ids = ($mod_cmds | where name != "commands" | get decl_id)
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
export def "extension-configuration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string # required
  --x-applecloudextension-retry-count: float # format: uint32
  --request-timeout: float # required, format: uint32
  --user-agent: string # required
  --accept-language: string # required
  --if-none-match: string
  --cache-control: string # required
]: nothing -> oneof<record<hdr: record, intent: record<addMedia: record<opt: list, hdr: record, url: string>, hdr: record, playMedia: record<opt: list, hdr: record, url: string>, updateMediaAffinity: record<opt: list, hdr: record, url: string>>, media: record<queues: record<hdr: record, playMedia: record, updateActivity: record>>, url: string, version: string>, string, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_applecloudextension_session_id == null) { error make --unspanned { msg: "required header parameter 'x-applecloudextension-session-id' missing: pass --x-applecloudextension-session-id" } }
  if ($request_timeout == null) { error make --unspanned { msg: "required header parameter 'Request-Timeout' missing: pass --request-timeout" } }
  if ($user_agent == null) { error make --unspanned { msg: "required header parameter 'User-Agent' missing: pass --user-agent" } }
  if ($accept_language == null) { error make --unspanned { msg: "required header parameter 'Accept-Language' missing: pass --accept-language" } }
  if ($cache_control == null) { error make --unspanned { msg: "required header parameter 'Cache-Control' missing: pass --cache-control" } }
  let full_url = (build-url $base "/configuration" $auth.query)
  let accept_val = "application/jose"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $request_timeout, "User-Agent": $user_agent, "Accept-Language": $accept_language, "If-None-Match": $if_none_match, "Cache-Control": $cache_control} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
  send-get $req $insecure $raw $allow_errors $full [200 304]
}

# addMedia
#
# POST /intent/addMedia
# operationId: addMediaIntentHandling
export def "add-media-intent-handling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string # required
  --x-applecloudextension-retry-count: float # format: uint32
  --request-timeout: float # required, format: uint32
  --user-agent: string # required
  --accept-language: string # required
  --body: list
]: any -> oneof<list<any>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_applecloudextension_session_id == null) { error make --unspanned { msg: "required header parameter 'x-applecloudextension-session-id' missing: pass --x-applecloudextension-session-id" } }
  if ($request_timeout == null) { error make --unspanned { msg: "required header parameter 'Request-Timeout' missing: pass --request-timeout" } }
  if ($user_agent == null) { error make --unspanned { msg: "required header parameter 'User-Agent' missing: pass --user-agent" } }
  if ($accept_language == null) { error make --unspanned { msg: "required header parameter 'Accept-Language' missing: pass --accept-language" } }
  let full_url = (build-url $base "/intent/addMedia" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $request_timeout, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# playMedia
#
# POST /intent/playMedia
# operationId: playMediaIntentHandling
export def "play-media-intent-handling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string # required
  --x-applecloudextension-retry-count: float # format: uint32
  --request-timeout: float # required, format: uint32
  --user-agent: string # required
  --accept-language: string # required
  --body: list
]: any -> oneof<list<any>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_applecloudextension_session_id == null) { error make --unspanned { msg: "required header parameter 'x-applecloudextension-session-id' missing: pass --x-applecloudextension-session-id" } }
  if ($request_timeout == null) { error make --unspanned { msg: "required header parameter 'Request-Timeout' missing: pass --request-timeout" } }
  if ($user_agent == null) { error make --unspanned { msg: "required header parameter 'User-Agent' missing: pass --user-agent" } }
  if ($accept_language == null) { error make --unspanned { msg: "required header parameter 'Accept-Language' missing: pass --accept-language" } }
  let full_url = (build-url $base "/intent/playMedia" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $request_timeout, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# updateMediaAffinity
#
# POST /intent/updateMediaAffinity
# operationId: updateMediaAffinityIntentHandling
export def "update-media-affinity-intent-handling" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string # required
  --x-applecloudextension-retry-count: float # format: uint32
  --request-timeout: float # required, format: uint32
  --user-agent: string # required
  --accept-language: string # required
  --body: list
]: any -> oneof<list<any>, string, record, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_applecloudextension_session_id == null) { error make --unspanned { msg: "required header parameter 'x-applecloudextension-session-id' missing: pass --x-applecloudextension-session-id" } }
  if ($request_timeout == null) { error make --unspanned { msg: "required header parameter 'Request-Timeout' missing: pass --request-timeout" } }
  if ($user_agent == null) { error make --unspanned { msg: "required header parameter 'User-Agent' missing: pass --user-agent" } }
  if ($accept_language == null) { error make --unspanned { msg: "required header parameter 'Accept-Language' missing: pass --accept-language" } }
  let full_url = (build-url $base "/intent/updateMediaAffinity" $auth.query)
  let req_body = $body
  let req_body = (merge-body-input $input $req_body "scalar")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "Request-Timeout": $request_timeout, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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

# playMedia
#
# POST /queues/playMedia
# operationId: playMediaOnQueue
export def "play-media-on-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string # required
  --x-applecloudextension-retry-count: float # format: uint32
  --user-agent: string # required
  --accept-language: string # required
  constraints: record # shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
  --user-activity: record # nullable — shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
  version: string
]: any -> oneof<record<content: table<attributes: record, control: string, identifier: string, isLive: bool, playIndex: int, url: string>, contentItemsCount: int, controls: record<default: record<activity: record, commands: record, scheme: string>>, identifier: string, insertPointer: record<afterIdentifier: string, replace: bool>, nextContentUrl: string, playPointer: record<contentIdentifier: string, offsetInMillis: int>, prerollSeconds: float, previousContentUrl: string, skipsRemaining: int, version: string>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_applecloudextension_session_id == null) { error make --unspanned { msg: "required header parameter 'x-applecloudextension-session-id' missing: pass --x-applecloudextension-session-id" } }
  if ($user_agent == null) { error make --unspanned { msg: "required header parameter 'User-Agent' missing: pass --user-agent" } }
  if ($accept_language == null) { error make --unspanned { msg: "required header parameter 'Accept-Language' missing: pass --accept-language" } }
  let full_url = (build-url $base "/queues/playMedia" $auth.query)
  let req_body = {"constraints": $constraints, "userActivity": $user_activity, "version": $version} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 204]
}

# updateActivity
#
# POST /queues/updateActivity
# operationId: updateActivityOnQueue
export def "update-activity-on-queue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-applecloudextension-session-id: string # required
  --x-applecloudextension-retry-count: float # format: uint32
  --user-agent: string # required
  --accept-language: string # required
  --constraints: record # shape: {allowExplicitContent?: bool, maximumQueueSegmentItemCount?: int, updateUserTasteProfile?: bool}
  --now-playing: record # shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
  --previously-playing: record # shape: {activityIdentifier?: string, contentIdentifier?: string, offsetInMillis?: int, playbackSpeed?: float, queueIdentifier?: string}
  report: string@report-completer
  timestamp: string # format: date-time
  --user-activity: record # nullable — shape: {activityType: string, persistentIdentifier?: string, title?: string, userInfo?: record, version: string}
  version: string
]: any -> oneof<record<queue: record<content: list<record>, contentItemsCount: int, controls: record<default: record>, identifier: string, insertPointer: record<afterIdentifier: string, replace: bool>, nextContentUrl: string, playPointer: record<contentIdentifier: string, offsetInMillis: int>, prerollSeconds: float, previousContentUrl: string, skipsRemaining: int, version: string>, userActivity: record<activityType: string, persistentIdentifier: string, title: string, userInfo: record, version: string>>, string, nothing> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($x_applecloudextension_session_id == null) { error make --unspanned { msg: "required header parameter 'x-applecloudextension-session-id' missing: pass --x-applecloudextension-session-id" } }
  if ($user_agent == null) { error make --unspanned { msg: "required header parameter 'User-Agent' missing: pass --user-agent" } }
  if ($accept_language == null) { error make --unspanned { msg: "required header parameter 'Accept-Language' missing: pass --accept-language" } }
  let full_url = (build-url $base "/queues/updateActivity" $auth.query)
  let req_body = {"constraints": $constraints, "nowPlaying": $now_playing, "previouslyPlaying": $previously_playing, "report": $report, "timestamp": $timestamp, "userActivity": $user_activity, "version": $version} | compact
  let req_body = (merge-body-input $input $req_body "record")
  let accept_val = "application/json"
  let auth = ($auth | update headers (merge-headers $auth.headers {Accept: $accept_val}))
  let extra_headers = {"x-applecloudextension-session-id": $x_applecloudextension_session_id, "x-applecloudextension-retry-count": $x_applecloudextension_retry_count, "User-Agent": $user_agent, "Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers (merge-headers $auth.headers $extra_headers))
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
  send-post $req $req_body $insecure $raw $allow_errors $full [200 204]
}
