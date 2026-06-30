# Auto-generated client for Shutterstock API Explorer v1.1.32
# Source: https://api.apis.guru/v2/specs/shutterstock.com/1.1.32/openapi.json
# Auth: --token flag or $env.SHUTTERSTOCK_API_EXPLORER_TOKEN

const BASE_URL = "https://api.shutterstock.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SHUTTERSTOCK_API_EXPLORER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.shutterstock.com" "https://api-sandbox.shutterstock.com"] }
def auth-scheme-completer [] { ["basic" "bearer" "basic-credentials"] }

# Completers for enum parameters
def view-completer [] { ["full" "minimal"] }
def sort-completer [] { ["newest" "oldest"] }
def download-availability-completer [] { ["all" "downloadable" "non_downloadable"] }
def license-completer [] { ["asset_all_music" "audio_platform" "premier_music_basic" "premier_music_comp" "premier_music_extended" "premier_music_pro"] }
def sort-completer-1 [] { ["artist" "bpm" "duration" "freshness" "ranking_all" "score" "title"] }
def sort-order-completer [] { ["asc" "desc"] }
def library-completer [] { ["premier" "shutterstock"] }
def language-completer [] { ["ar" "bg" "bn" "cs" "da" "de" "el" "en" "es" "fi" "fr" "gu" "he" "hi" "hr" "hu" "id" "it" "ja" "kn" "ko" "ml" "mr" "nb" "nl" "or" "pl" "pt" "ro" "ru" "sk" "sl" "sv" "ta" "te" "th" "tr" "uk" "ur" "vi" "zh" "zh-Hant"] }
def orientation-completer [] { ["horizontal" "vertical"] }
def people-age-completer [] { ["20s" "30s" "40s" "50s" "60s" "children" "infants" "older" "teenagers"] }
def people-gender-completer [] { ["both" "female" "male"] }
def sort-completer-2 [] { ["newest" "popular" "random" "relevance"] }
def visibility-completer [] { ["private" "public"] }
def sort-completer-3 [] { ["item_count" "last_updated" "newest"] }
def sort-completer-4 [] { ["newest" "oldest" "relevant"] }
def type-completer [] { ["addition" "edit"] }
def resolution-completer [] { ["4k" "high_definition" "standard_definition"] }
def embed-completer [] { ["share_url"] }
def asset-hint-completer [] { ["1x" "2x"] }
def format-completer [] { ["eps" "jpg"] }
def size-completer [] { ["custom" "huge" "medium" "small" "vector"] }
def size-completer-1 [] { ["huge" "medium" "small" "supersize" "vector"] }
def ai-industry-completer [] { ["automotive" "cpg" "finance" "healthcare" "retail" "technology"] }
def ai-objective-completer [] { ["awareness" "conversions" "traffic"] }
def grant-type-completer [] { ["authorization_code" "client_credentials" "refresh_token"] }
def realm-completer [] { ["contributor" "customer"] }
def response-type-completer [] { ["code"] }
def library-completer-1 [] { ["premier" "premiumbeat" "shutterstock"] }
def sort-completer-5 [] { ["newest" "oldest" "popular" "random" "relevance"] }
def size-completer-2 [] { ["4k" "hd" "sd" "web"] }
def aspect-ratio-completer [] { ["16_9" "4_3" "nonstandard"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ai-audio-descriptors list-custom" } } | get name | first)
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

# List computer audio descriptors
#
# GET /v2/ai/audio/descriptors
# operationId: listCustomDescriptors
export def "ai-audio-descriptors list-custom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --render-speed-over: float # Show descriptors with an average render speed that is greater than or equal to the specified value (e.g. 5)
  --band-id: string # Show descriptors that contain the specified band (case-sentsitive) (e.g. Corporate Folk Bonfire Band 1)
  --band-name: string # Show descriptors with the specified band name (case-sensitive) (e.g. Documentary Underscore Heartfelt Band 1)
  --page: int # Page number (default: 1, e.g. 1)
  --per-page: int # Number of results per page (default: 20, e.g. 1)
  --id: list<string> # Show descriptors with the specified IDs (case-sensitive) (e.g. documentary_underscore_heartfelt)
  --instrument-name: string # Show descriptors with the specified instrument name (case-sensitive) (e.g. Precision Bass - Full)
  --instrument-id: string # Show descriptors with the specified instrument ID (case-sensitive) (e.g. direct_fluorescent_synth_lead)
  --tempo: float # Show descriptors whose tempo range includes the specified tempo in beats per minute (e.g. 90)
  --tempo-to: float # Show descriptors with a tempo that is less than or equal to the specified number (e.g. 120)
  --tempo-from: float # Show descriptors that have a tempo range that includes the specified tempo in beats per minute (e.g. 60)
  --name: string # Show descriptors with the specified name (case-sensitive) (e.g. Corporate Pop Inspirational High Energy)
  --tag: string # Show descriptors with the specified tag, such as Cinematic or Roomy (case-sensitive) (e.g. Cinematic)
]: nothing -> record<data: table<average_render_speed: float, bands: list, id: string, instruments: list, max_tempo: float, min_tempo: float, name: string, previews: list, tags: list>, page: int, per_page: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "render_speed_over" $render_speed_over "scalar") (serialize-qp "band_id" $band_id "scalar") (serialize-qp "band_name" $band_name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "id" $id "multi") (serialize-qp "instrument_name" $instrument_name "scalar") (serialize-qp "instrument_id" $instrument_id "scalar") (serialize-qp "tempo" $tempo "scalar") (serialize-qp "tempo_to" $tempo_to "scalar") (serialize-qp "tempo_from" $tempo_from "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/ai/audio/descriptors" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"render_speed_over": $render_speed_over, "band_id": $band_id, "band_name": $band_name, "page": $page, "per_page": $per_page, "id": $id, "instrument_name": $instrument_name, "instrument_id": $instrument_id, "tempo": $tempo, "tempo_to": $tempo_to, "tempo_from": $tempo_from, "name": $name, "tag": $tag} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List computer audio instruments
#
# GET /v2/ai/audio/instruments
# operationId: listCustomInstruments
export def "ai-audio-instruments list-custom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Show instruments with the specified ID (e.g. wood_blocks)
  --per-page: int # Number of results per page (default: 20, e.g. 1)
  --page: int # Page number (default: 1, e.g. 1)
  --name: string # Show instruments with the specified name (case-sensitive) (e.g. Precision Bass - Full)
  --tag: string # Show instruments with the specified tag, such as Percussion or Strings (case-sensitive) (e.g. Percussion)
]: nothing -> record<data: table<id: string, name: string, previews: list, tags: list>, page: int, per_page: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/ai/audio/instruments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "per_page": $per_page, "page": $page, "name": $name, "tag": $tag} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details about audio renders
#
# GET /v2/ai/audio/renders
# operationId: fetchRenders
export def "ai-audio-renders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # One or more render IDs (e.g. [L2w7h9VNFlkzpllSUunSYayenKjN, BeHx3UNXzMBB4dGsC9aa6VxnpcWl])
]: nothing -> record<audio_renders: table<created_date: string, files: list, id: string, preset: string, progress_percent: int, status: string, timeline: record, updated_date: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/ai/audio/renders" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create rendered audio
#
# POST /v2/ai/audio/renders
# operationId: createAudioRenders
# --audio_renders item shape: {filename: string, preset: "MASTER_MP3"|"MASTER_WAV"|"STEMS_WAV", timeline: record}
export def "ai-audio-renders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  audio_renders: list # Parameters to create computer audio renders — item shape: {filename: string, preset: "MASTER_MP3"|"MASTER_WAV"|"STEMS_WAV", timeline: record}
]: any -> record<audio_renders: table<created_date: string, files: list, id: string, preset: string, progress_percent: int, status: string, timeline: record, updated_date: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/ai/audio/renders" $auth.query)
  let req_body = {"audio_renders": $audio_renders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List audio tracks
#
# GET /v2/audio
# operationId: getTrackList
export def "audio get-track-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # One or more audio IDs (e.g. [442583, 434750])
  --view: string@view-completer # Amount of detail to render in the response (default: minimal, e.g. full)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, album: record, artists: list, assets: record, bpm: int, contributor: record, deleted_time: string, description: string, duration: float, genres: list, id: string, instruments: list, is_adult: bool, is_instrumental: bool, isrc: string, keywords: list, language: string, lyrics: string, media_type: string, model_releases: list, moods: list, published_time: string, recording_version: string, releases: list, similar_artists: list, submitted_time: string, title: string, updated_time: string, url: string, vocal_description: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "view" $view "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audio" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "view": $view, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List audio collections
#
# GET /v2/audio/collections
# operationId: getTrackCollectionList
export def "audio-collections get-track-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (default: 1, e.g. 1)
  --per-page: int # Number of results per page (default: 100, e.g. 100)
  --embed: list<string> # Which sharing information to include in the response, such as a URL to the collection (e.g. share_code)
]: nothing -> record<data: table<cover_item: record, created_time: string, id: string, items_updated_time: string, name: string, share_code: string, share_url: string, total_item_count: int, updated_time: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "embed" $embed "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audio/collections" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create audio collections
#
# POST /v2/audio/collections
# operationId: createTrackCollection
export def "audio-collections create-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the collection
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/audio/collections" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete audio collections
#
# DELETE /v2/audio/collections/{id}
# operationId: deleteTrackCollection
export def "audio-collections delete-track" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/audio/collections/{id}") $auth.query)
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

# Get the details of audio collections
#
# GET /v2/audio/collections/{id}
# operationId: getTrackCollection
export def "audio-collections get-track" [
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
  --embed: list<string> # Which sharing information to include in the response, such as a URL to the collection
  --share-code: string # Code to retrieve a shared collection
]: nothing -> record<cover_item: record<added_time: string, id: string, media_type: string>, created_time: string, id: string, items_updated_time: string, name: string, share_code: string, share_url: string, total_item_count: int, updated_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "multi") (serialize-qp "share_code" $share_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/audio/collections/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed, "share_code": $share_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Rename audio collections
#
# POST /v2/audio/collections/{id}
# operationId: renameTrackCollection
export def "audio-collections rename-track" [
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
  name: string # The new name of the collection
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/audio/collections/{id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove audio tracks from collections
#
# DELETE /v2/audio/collections/{id}/items
# operationId: deleteTrackCollectionItems
export def "audio-collections-items delete-track" [
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
  --item-id: list<string> # One or more item IDs to remove from the collection (e.g. [76688182, 40005859])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "item_id" $item_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/audio/collections/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"item_id": $item_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the contents of audio collections
#
# GET /v2/audio/collections/{id}/items
# operationId: getTrackCollectionItems
export def "audio-collections-items get-track" [
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
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 100)
  --share-code: string # Code to retrieve the contents of a shared collection
  --qp-sort: string@sort-completer # Sort order (default: oldest)
]: nothing -> record<data: table<added_time: string, id: string, media_type: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "share_code" $share_code "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/audio/collections/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "share_code": $share_code, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add audio tracks to collections
#
# POST /v2/audio/collections/{id}/items
# operationId: addTrackCollectionItems
# --items item shape: {added_time?: string, id: string, media_type?: string}
export def "audio-collections-items create-track" [
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
  items: list # List of items — item shape: {added_time?: string, id: string, media_type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/audio/collections/{id}/items") $auth.query)
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# List audio genres
#
# GET /v2/audio/genres
# operationId: listGenres
export def "audio-genres list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Which language the genres will be returned
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audio/genres" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List audio instruments
#
# GET /v2/audio/instruments
# operationId: listInstruments
export def "audio-instruments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Which language the instruments will be returned in
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audio/instruments" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List audio licenses
#
# GET /v2/audio/licenses
# operationId: getTrackLicenseList
export def "audio-licenses get-track-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --audio-id: string # Show licenses for the specified track ID (e.g. 1)
  --license: string # Restrict results by license. Prepending a `-` sign will exclude results by license (e.g. 48433107)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --qp-sort: string@sort-completer # Sort order (default: newest)
  --username: string # Filter licenses by username of licensee (e.g. aUniqueUsername)
  --start-date: string # Show licenses created on or after the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --end-date: string # Show licenses created before the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --download-availability: string@download-availability-completer # Filter licenses by download availability (default: all)
  --team-history: oneof<nothing, bool> # Set to true to see license history for all members of your team. (default: false)
]: nothing -> record<data: table<audio: record, download_time: string, id: string, image: record, is_downloadable: bool, license: string, metadata: record, revshare: record, subscription_id: string, user: record, video: record>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "audio_id" $audio_id "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "download_availability" $download_availability "scalar") (serialize-qp "team_history" $team_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audio/licenses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"audio_id": $audio_id, "license": $license, "page": $page, "per_page": $per_page, "sort": $qp_sort, "username": $username, "start_date": $start_date, "end_date": $end_date, "download_availability": $download_availability, "team_history": $team_history} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# License audio tracks
#
# POST /v2/audio/licenses
# operationId: licenseTrack
# --audio item shape: {audio_id: string, license?: "audio_platform"|"premier_music_basic"|"premier_music_extended"|"premier_music_pro"|"premier_music_comp"|"asset_all_music", search_id?: string}
export def "audio-licenses create-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --license: string@license-completer # License type (e.g. audio_platform)
  --search-id: string # The ID of the search that led to licensing this track (e.g. p5S6QwRikdFJTHXwsoiqTg)
  audio: list # List of audio tracks to license — item shape: {audio_id: string, license?: "audio_platform"|"premier_music_basic"|"premier_music_extended"|"premier_music_pro"|"premier_music_comp"|"asset_all_music", search_id?: string}
]: any -> record<data: table<allotment_charge: float, audio_id: string, download: record, error: string, license_id: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "license" $license "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audio/licenses" $qp $auth.query)
  let req_body = {"audio": $audio} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"license": $license, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Download audio tracks
#
# POST /v2/audio/licenses/{id}/downloads
# operationId: downloadTracks
export def "audio-licenses-downloads download-tracks" [
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
]: nothing -> record<shorts_loops_stems: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/audio/licenses/{id}/downloads") $auth.query)
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

# List audio moods
#
# GET /v2/audio/moods
# operationId: listMoods
export def "audio-moods list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Which language the moods will be returned in
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audio/moods" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for tracks
#
# GET /v2/audio/search
# operationId: searchTracks
@deprecated --flag bpm
export def "audio-search list-tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --artists: list<string> # Show tracks with one of the specified artist names or IDs
  --bpm: int # (Deprecated; use bpm_from and bpm_to instead) Show tracks with the specified beats per minute (DEPRECATED)
  --bpm-from: int # Show tracks with the specified beats per minute or faster (e.g. 80)
  --bpm-to: int # Show tracks with the specified beats per minute or slower (e.g. 120)
  --duration: int # Show tracks with the specified duration in seconds (e.g. 180)
  --duration-from: int # Show tracks with the specified duration or longer in seconds (e.g. 30)
  --duration-to: int # Show tracks with the specified duration or shorter in seconds (e.g. 180)
  --genre: list<string> # Show tracks with each of the specified genres; to get the list of genres, use `GET /v2/audio/genres` (e.g. [Classical, Holiday])
  --is-instrumental: oneof<nothing, bool> # Show instrumental music only (e.g. true)
  --instruments: list<string> # Show tracks with each of the specified instruments; to get the list of instruments, use `GET /v2/audio/instruments` (e.g. [Trumpet, Percussion])
  --moods: list<string> # Show tracks with each of the specified moods; to get the list of moods, use `GET /v2/audio/moods` (e.g. [Confident, Playful])
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20, e.g. 1)
  --query: string # One or more search terms separated by spaces (e.g. drum)
  --qp-sort: string@sort-completer-1 # Sort by (e.g. score)
  --sort-order: string@sort-order-completer # Sort order (default: desc)
  --vocal-description: string # Show tracks with the specified vocal description (male, female) (e.g. female)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal, e.g. full)
  --fields: string # Fields to display in the response; see the documentation for the fields parameter in the overview section
  --library: string@library-completer # Which library to search (default: premier)
  --language: string # Which language to search in
]: nothing -> record<data: table<added_date: string, affiliate_url: string, album: record, artists: list, assets: record, bpm: int, contributor: record, deleted_time: string, description: string, duration: float, genres: list, id: string, instruments: list, is_adult: bool, is_instrumental: bool, isrc: string, keywords: list, language: string, lyrics: string, media_type: string, model_releases: list, moods: list, published_time: string, recording_version: string, releases: list, similar_artists: list, submitted_time: string, title: string, updated_time: string, url: string, vocal_description: string>, message: string, page: int, per_page: int, search_id: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "artists" $artists "multi") (serialize-qp "bpm" $bpm "scalar") (serialize-qp "bpm_from" $bpm_from "scalar") (serialize-qp "bpm_to" $bpm_to "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "duration_from" $duration_from "scalar") (serialize-qp "duration_to" $duration_to "scalar") (serialize-qp "genre" $genre "multi") (serialize-qp "is_instrumental" $is_instrumental "scalar") (serialize-qp "instruments" $instruments "multi") (serialize-qp "moods" $moods "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "vocal_description" $vocal_description "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "library" $library "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/audio/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"artists": $artists, "bpm": $bpm, "bpm_from": $bpm_from, "bpm_to": $bpm_to, "duration": $duration, "duration_from": $duration_from, "duration_to": $duration_to, "genre": $genre, "is_instrumental": $is_instrumental, "instruments": $instruments, "moods": $moods, "page": $page, "per_page": $per_page, "query": $query, "sort": $qp_sort, "sort_order": $sort_order, "vocal_description": $vocal_description, "view": $view, "fields": $fields, "library": $library, "language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details about audio tracks
#
# GET /v2/audio/{id}
# operationId: getTrack
export def "audio get-track" [
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
  --view: string@view-completer # Amount of detail to render in the response (default: full, e.g. full)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<added_date: string, affiliate_url: string, album: record<id: string, title: string>, artists: table<name: string>, assets: record<album_art: record<file_size: int, url: string>, clean_audio: record<file_size: int, url: string>, original_audio: record<file_size: int, url: string>, preview_mp3: record<file_size: int, url: string>, preview_ogg: record<file_size: int, url: string>, shorts_loops_stems: record<loops: any, shorts: any, stems: any>, waveform: record<file_size: int, url: string>>, bpm: int, contributor: record<id: string>, deleted_time: string, description: string, duration: float, genres: list<string>, id: string, instruments: list<string>, is_adult: bool, is_instrumental: bool, isrc: string, keywords: list<string>, language: string, lyrics: string, media_type: string, model_releases: table<id: string>, moods: list<string>, published_time: string, recording_version: string, releases: list<string>, similar_artists: table<name: string>, submitted_time: string, title: string, updated_time: string, url: string, vocal_description: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "view" $view "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/audio/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"view": $view, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Run multiple image searches
#
# POST /v2/bulk_search/images
# operationId: bulkSearchImages
@deprecated --flag height
@deprecated --flag width
export def "bulk-search-images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --added-date: string # Show images added on the specified date (format: date, e.g. 2021-03-29)
  --added-date-start: string # Show images added on or after the specified date (format: date, e.g. 2021-03-29)
  --aspect-ratio-min: float # Show images with the specified aspect ratio or higher, using a positive decimal of the width divided by the height, such as 1.7778 for a 16:9 image (e.g. 1.7778)
  --aspect-ratio-max: float # Show images with the specified aspect ratio or lower, using a positive decimal of the width divided by the height, such as 1.7778 for a 16:9 image (e.g. 1.7778)
  --aspect-ratio: float # Show images with the specified aspect ratio, using a positive decimal of the width divided by the height, such as 1.7778 for a 16:9 image (e.g. 1.7778)
  --added-date-end: string # Show images added before the specified date (format: date, e.g. 2021-03-29)
  --category: string # Show images with the specified Shutterstock-defined category; specify a category name or ID
  --color: string # Specify either a hexadecimal color in the format '4F21EA' or 'grayscale'; the API returns images that use similar colors (e.g. 4F21EA)
  --contributor: list<string> # Show images with the specified contributor names or IDs, allows multiple (e.g. [123456])
  --contributor-country: string # Show images from contributors in one or more specified countries, or start with NOT to exclude a country from the search (e.g. US)
  --fields: string # Fields to display in the response; see the documentation for the fields parameter in the overview section
  --height: int # (Deprecated; use height_from and height_to instead) Show images with the specified height (DEPRECATED)
  --height-from: int # Show images with the specified height or larger, in pixels (e.g. 1080)
  --height-to: int # Show images with the specified height or smaller, in pixels (e.g. 1080)
  --image-type: list<string> # Show images of the specified type (e.g. photo)
  --keyword-safe-search: oneof<nothing, bool> # Hide results with potentially unsafe keywords (default: true)
  --language: string@language-completer # Set query and result language (uses Accept-Language header if not set) (e.g. cs)
  --license: list<string> # Show only images with the specified license
  --model: list<string> # Show image results with the specified model IDs (e.g. [12345, 67890])
  --orientation: string@orientation-completer # Show image results with horizontal or vertical orientation (e.g. vertical)
  --page: int # Page number (default: 1, e.g. 1)
  --per-page: int # Number of results per page (default: 20, e.g. 10)
  --people-model-released: oneof<nothing, bool> # Show images of people with a signed model release (e.g. true)
  --people-age: string@people-age-completer # Show images that feature people of the specified age category (e.g. 20s)
  --people-ethnicity: list<string> # Show images with people of the specified ethnicities, or start with NOT to show images without those ethnicities (e.g. hispanic)
  --people-gender: string@people-gender-completer # Show images with people of the specified gender (e.g. both)
  --people-number: int # Show images with the specified number of people (e.g. 2)
  --region: string # Raise or lower search result rankings based on the result's relevance to a specified region; you can provide a country code or an IP address from which the API infers a country (e.g. US)
  --safe: oneof<nothing, bool> # Enable or disable safe search (default: true)
  --qp-sort: string@sort-completer-2 # Sort by (default: popular)
  --spellcheck-query: oneof<nothing, bool> # Spellcheck the search query and return results on suggested spellings (default: true)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal)
  --width: int # (Deprecated; use width_from and width_to instead) Show images with the specified width (DEPRECATED)
  --width-from: int # Show images with the specified width or larger, in pixels (e.g. 1920)
  --width-to: int # Show images with the specified width or smaller, in pixels (e.g. 1920)
  --body: list
]: any -> record<bulk_search_id: string, results: table<data: list, insights: record, message: string, page: int, per_page: int, search_id: string, spellcheck_info: record, total_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "added_date" $added_date "scalar") (serialize-qp "added_date_start" $added_date_start "scalar") (serialize-qp "aspect_ratio_min" $aspect_ratio_min "scalar") (serialize-qp "aspect_ratio_max" $aspect_ratio_max "scalar") (serialize-qp "aspect_ratio" $aspect_ratio "scalar") (serialize-qp "added_date_end" $added_date_end "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "contributor" $contributor "multi") (serialize-qp "contributor_country" $contributor_country "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "height_from" $height_from "scalar") (serialize-qp "height_to" $height_to "scalar") (serialize-qp "image_type" $image_type "multi") (serialize-qp "keyword_safe_search" $keyword_safe_search "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "license" $license "multi") (serialize-qp "model" $model "multi") (serialize-qp "orientation" $orientation "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "people_model_released" $people_model_released "scalar") (serialize-qp "people_age" $people_age "scalar") (serialize-qp "people_ethnicity" $people_ethnicity "multi") (serialize-qp "people_gender" $people_gender "scalar") (serialize-qp "people_number" $people_number "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "safe" $safe "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "spellcheck_query" $spellcheck_query "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "width_from" $width_from "scalar") (serialize-qp "width_to" $width_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/bulk_search/images" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"added_date": $added_date, "added_date_start": $added_date_start, "aspect_ratio_min": $aspect_ratio_min, "aspect_ratio_max": $aspect_ratio_max, "aspect_ratio": $aspect_ratio, "added_date_end": $added_date_end, "category": $category, "color": $color, "contributor": $contributor, "contributor_country": $contributor_country, "fields": $fields, "height": $height, "height_from": $height_from, "height_to": $height_to, "image_type": $image_type, "keyword_safe_search": $keyword_safe_search, "language": $language, "license": $license, "model": $model, "orientation": $orientation, "page": $page, "per_page": $per_page, "people_model_released": $people_model_released, "people_age": $people_age, "people_ethnicity": $people_ethnicity, "people_gender": $people_gender, "people_number": $people_number, "region": $region, "safe": $safe, "sort": $qp_sort, "spellcheck_query": $spellcheck_query, "view": $view, "width": $width, "width_from": $width_from, "width_to": $width_to} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# List catalog collections
#
# GET /v2/catalog/collections
# operationId: getCollections
export def "catalog-collections get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (default: 1, e.g. 1)
  --per-page: int # Number of results per page (default: 20, e.g. 20)
  --qp-sort: string@sort-completer # Sort by (default: newest)
  --shared: oneof<nothing, bool> # Set to true to omit collections that you own and return only collections that are shared with you (default: false)
]: nothing -> record<data: table<cover_asset: record, created_time: string, id: string, name: string, role_assignments: record, total_item_count: float, updated_time: string, visibility: string>, page: float, per_page: float, total_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "shared" $shared "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/catalog/collections" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "sort": $qp_sort, "shared": $shared} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create catalog collections
#
# POST /v2/catalog/collections
# operationId: createCollection
# --items item shape: {asset: record}
export def "catalog-collections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --items: list # item shape: {asset: record}
  name: string
  --visibility: string@visibility-completer # default: private
]: any -> record<cover_asset: record<asset: record<id: string, name: string, type: string>, collection_ids: list<string>, created_time: string, id: string>, created_time: string, id: string, name: string, role_assignments: record<collection_id: string, roles: record<editors: list, owners: list, viewers: list>>, total_item_count: float, updated_time: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/catalog/collections" $auth.query)
  let req_body = {"items": $items, "name": $name, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete catalog collections
#
# DELETE /v2/catalog/collections/{collection_id}
# operationId: deleteCollection
export def "catalog-collections delete" [
  collection_id: string
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
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/v2/catalog/collections/{collection_id}") $auth.query)
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

# Update collection metadata
#
# PATCH /v2/catalog/collections/{collection_id}
# operationId: updateCollection
# --cover_asset shape: {id: string}
export def "catalog-collections update" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cover-asset: record # shape: {id: string}
  --name: string
  --visibility: string@visibility-completer
]: any -> record<cover_asset: record<asset: record<id: string, name: string, type: string>, collection_ids: list<string>, created_time: string, id: string>, created_time: string, id: string, name: string, role_assignments: record<collection_id: string, roles: record<editors: list, owners: list, viewers: list>>, total_item_count: float, updated_time: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/v2/catalog/collections/{collection_id}") $auth.query)
  let req_body = {"cover_asset": $cover_asset, "name": $name, "visibility": $visibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Remove items from catalog collection
#
# DELETE /v2/catalog/collections/{collection_id}/items
# operationId: deleteFromCollection
# --items item shape: {id: string}
export def "catalog-collections-items delete" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  items: list # item shape: {id: string}
]: any -> record<cover_asset: record<asset: record<id: string, name: string, type: string>, collection_ids: list<string>, created_time: string, id: string>, created_time: string, id: string, name: string, role_assignments: record<collection_id: string, roles: record<editors: list, owners: list, viewers: list>>, total_item_count: float, updated_time: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/v2/catalog/collections/{collection_id}/items") $auth.query)
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# Add items to catalog collections
#
# POST /v2/catalog/collections/{collection_id}/items
# operationId: addToCollection
# --items item shape: {asset: record}
export def "catalog-collections-items create" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  items: list # item shape: {asset: record}
]: any -> record<cover_asset: record<asset: record<id: string, name: string, type: string>, collection_ids: list<string>, created_time: string, id: string>, created_time: string, id: string, name: string, role_assignments: record<collection_id: string, roles: record<editors: list, owners: list, viewers: list>>, total_item_count: float, updated_time: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collection_id' must be non-empty" } }
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/v2/catalog/collections/{collection_id}/items") $auth.query)
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# Search catalogs for assets
#
# GET /v2/catalog/search
# operationId: searchCatalog
export def "catalog-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer # Sort by (default: newest)
  --page: int # Page number (default: 1, e.g. 1)
  --per-page: int # Number of results per page (default: 20, e.g. 50)
  --query: string # One or more search terms separated by spaces (e.g. dogs on the beach)
  --collection-id: list<string> # Filter by collection id (e.g. [123456, 456789, 13579])
  --asset-type: list<string> # Filter by asset type (e.g. [image, editorial-image])
]: nothing -> record<data: table<asset: record, collection_ids: list, created_time: string, id: string>, page: float, per_page: float, total_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "collection_id" $collection_id "multi") (serialize-qp "asset_type" $asset_type "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/catalog/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort": $qp_sort, "page": $page, "per_page": $per_page, "query": $query, "collection_id": $collection_id, "asset_type": $asset_type} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details about multiple contributors
#
# GET /v2/contributors
# operationId: getContributorList
export def "contributors get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # One or more contributor IDs (e.g. [800506, 1653538])
]: nothing -> record<data: table<about: string, contributor_type: list, display_name: string, equipment: list, id: string, location: string, portfolio_url: string, social_media: record, styles: list, subjects: list, website: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/contributors" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details about a single contributor
#
# GET /v2/contributors/{contributor_id}
# operationId: getContributor
export def "contributors get" [
  contributor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<about: string, contributor_type: list<string>, display_name: string, equipment: list<string>, id: string, location: string, portfolio_url: string, social_media: record<facebook: string, google_plus: string, linkedin: string, pinterest: string, tumblr: string, twitter: string>, styles: list<string>, subjects: list<string>, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($contributor_id | is-empty) { error make --unspanned { msg: "path parameter 'contributor_id' must be non-empty" } }
  let full_url = (build-url $base ({contributor_id: (encode-path-segment $contributor_id)} | format pattern "/v2/contributors/{contributor_id}") $auth.query)
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

# List contributors' collections
#
# GET /v2/contributors/{contributor_id}/collections
# operationId: getContributorCollectionsList
export def "contributors-collections get-list" [
  contributor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string@sort-completer-3 # Sort order
]: nothing -> record<data: table<cover_item: record, created_time: string, id: string, items_updated_time: string, name: string, share_code: string, share_url: string, total_item_count: int, updated_time: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($contributor_id | is-empty) { error make --unspanned { msg: "path parameter 'contributor_id' must be non-empty" } }
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({contributor_id: (encode-path-segment $contributor_id)} | format pattern "/v2/contributors/{contributor_id}/collections") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details about contributors' collections
#
# GET /v2/contributors/{contributor_id}/collections/{id}
# operationId: getContributorCollections
export def "contributors-collections get" [
  contributor_id: string
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
]: nothing -> record<cover_item: record<added_time: string, id: string, media_type: string>, created_time: string, id: string, items_updated_time: string, name: string, share_code: string, share_url: string, total_item_count: int, updated_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($contributor_id | is-empty) { error make --unspanned { msg: "path parameter 'contributor_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({contributor_id: (encode-path-segment $contributor_id), id: (encode-path-segment $id)} | format pattern "/v2/contributors/{contributor_id}/collections/{id}") $auth.query)
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

# Get the items in contributors' collections
#
# GET /v2/contributors/{contributor_id}/collections/{id}/items
# operationId: getContributorCollectionItems
export def "contributors-collections-items get" [
  contributor_id: string
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
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --qp-sort: string@sort-completer # Sort order
]: nothing -> record<data: table<added_time: string, id: string, media_type: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($contributor_id | is-empty) { error make --unspanned { msg: "path parameter 'contributor_id' must be non-empty" } }
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({contributor_id: (encode-path-segment $contributor_id), id: (encode-path-segment $id)} | format pattern "/v2/contributors/{contributor_id}/collections/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Upload images
#
# POST /v2/cv/images
# operationId: uploadImage
export def "cv-images upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  base64_image: string # A Base 64 encoded jpeg or png; images can be no larger than 10mb and can be no larger than 10,000 pixels in width or height
]: any -> record<upload_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/cv/images" $auth.query)
  let req_body = {"base64_image": $base64_image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List suggested keywords
#
# GET /v2/cv/keywords
# operationId: getKeywords
export def "cv-keywords get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The asset ID or upload ID to suggest keywords for (e.g. U6ba16262e3bc2db470b8e3cfa8aaab25)
]: nothing -> record<data: list<string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset_id" $asset_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cv/keywords" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"asset_id": $asset_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List similar images
#
# GET /v2/cv/similar/images
# operationId: getSimilarImages
export def "cv-similar-images get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The asset ID or upload ID to find similar images for (e.g. U6ba16262e3bc2db470b8e3cfa8aaab25)
  --license: list<string> # Show only images with the specified license (default: [commercial])
  --safe: oneof<nothing, bool> # Enable or disable safe search (default: true)
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, aspect: float, assets: record, categories: list, contributor: record, description: string, has_model_release: bool, has_property_release: bool, id: string, image_type: string, insights: record, is_adult: bool, is_editorial: bool, is_illustration: bool, keywords: list, media_type: string, model_releases: list, models: list, releases: list, url: string>, insights: record<label_performance: list<record>>, message: string, page: int, per_page: int, search_id: string, spellcheck_info: record, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset_id" $asset_id "scalar") (serialize-qp "license" $license "multi") (serialize-qp "safe" $safe "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cv/similar/images" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"asset_id": $asset_id, "license": $license, "safe": $safe, "language": $language, "page": $page, "per_page": $per_page, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List similar videos
#
# GET /v2/cv/similar/videos
# operationId: getSimilarVideos
export def "cv-similar-videos get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --asset-id: string # The asset ID or upload ID to find similar videos for (e.g. U6ba16262e3bc2db470b8e3cfa8aaab25)
  --license: list<string> # Show only videos with the specified license (default: [commercial])
  --safe: oneof<nothing, bool> # Enable or disable safe search (default: true)
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, aspect: float, aspect_ratio: string, assets: record, categories: list, contributor: record, description: string, duration: float, has_model_release: bool, has_property_release: bool, id: string, is_adult: bool, is_editorial: bool, keywords: list, media_type: string, models: list, url: string>, message: string, page: int, per_page: int, search_id: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asset_id" $asset_id "scalar") (serialize-qp "license" $license "multi") (serialize-qp "safe" $safe "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/cv/similar/videos" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"asset_id": $asset_id, "license": $license, "safe": $safe, "language": $language, "page": $page, "per_page": $per_page, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# (Deprecated) List editorial categories
#
# GET /v2/editorial/categories
# DEPRECATED
# operationId: getEditorialCategories
@deprecated
export def "editorial-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/editorial/categories" $auth.query)
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

# List editorial categories
#
# GET /v2/editorial/images/categories
# operationId: listEditorialImageCategories
export def "editorial-images-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/editorial/images/categories" $auth.query)
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

# List editorial image licenses
#
# GET /v2/editorial/images/licenses
# operationId: getEditorialImageLicenseList
export def "editorial-images-licenses get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-id: string # Show licenses for the specified editorial image ID (e.g. 12345678)
  --license: string # Show editorial images that are available with the specified license name (e.g. premier_editorial_all_digital)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --qp-sort: string@sort-completer # Sort order (default: newest)
  --username: string # Filter licenses by username of licensee (e.g. aUniqueUsername)
  --start-date: string # Show licenses created on or after the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --end-date: string # Show licenses created before the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --download-availability: string@download-availability-completer # Filter licenses by download availability (default: all)
  --team-history: oneof<nothing, bool> # Set to true to see license history for all members of your team. (default: false)
]: nothing -> record<data: table<audio: record, download_time: string, id: string, image: record, is_downloadable: bool, license: string, metadata: record, revshare: record, subscription_id: string, user: record, video: record>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "image_id" $image_id "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "download_availability" $download_availability "scalar") (serialize-qp "team_history" $team_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/images/licenses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"image_id": $image_id, "license": $license, "page": $page, "per_page": $per_page, "sort": $qp_sort, "username": $username, "start_date": $start_date, "end_date": $end_date, "download_availability": $download_availability, "team_history": $team_history} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# License editorial content
#
# POST /v2/editorial/images/licenses
# operationId: licenseEditorialImages
# --editorial item shape: {editorial_id: string, license: string, metadata?: record, size?: "small"|"medium"|"original"}
export def "editorial-images-licenses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: any # A valid ISO 3166-1 Alpha-2 or ISO 3166-1 Alpha-3 code. (e.g. USA)
  editorial: list # Editorial content to license — item shape: {editorial_id: string, license: string, metadata?: record, size?: "small"|"medium"|"original"}
]: any -> record<data: table<allotment_charge: int, download: record, editorial_id: string, error: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/editorial/images/licenses" $auth.query)
  let req_body = {"country": $country, "editorial": $editorial} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# Get editorial livefeed list
#
# GET /v2/editorial/images/livefeeds
# operationId: getEditorialImageLivefeedList
export def "editorial-images-livefeeds get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Returns only livefeeds that are available for distribution in a certain country (format: country-code-3, e.g. USA)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
]: nothing -> record<data: table<cover_item: record, created_time: string, id: string, name: string, total_item_count: int>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/images/livefeeds" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get editorial livefeed
#
# GET /v2/editorial/images/livefeeds/{id}
# operationId: getEditorialImageLivefeed
export def "editorial-images-livefeeds get" [
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
  --country: string # Returns only if the livefeed is available for distribution in a certain country (format: country-code-3, e.g. USA)
]: nothing -> record<cover_item: record<height: int, id: string, url: string, width: int>, created_time: string, id: string, name: string, total_item_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/editorial/images/livefeeds/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get editorial livefeed items
#
# GET /v2/editorial/images/livefeeds/{id}/items
# operationId: getEditorialImageLivefeedItems
export def "editorial-images-livefeeds-items get" [
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
  --country: string # Returns only if the livefeed items are available for distribution in a certain country (format: country-code-3, e.g. USA)
]: nothing -> record<data: table<aspect: float, assets: record, byline: string, caption: string, categories: list, date_taken: string, description: string, id: string, keywords: list, special_instructions: string, title: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/editorial/images/livefeeds/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search editorial images
#
# GET /v2/editorial/images/search
# operationId: searchEditorialImages
export def "editorial-images-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # One or more search terms separated by spaces (e.g. The Academy Awards)
  --qp-sort: string@sort-completer-4 # Sort by (default: relevant)
  --category: string # Show editorial content with each of the specified editorial categories; specify category names in a comma-separated list (e.g. Alone,Performing)
  --country: string # Show only editorial content that is available for distribution in a certain country (format: country-code-3, e.g. USA)
  --supplier-code: list<string> # Show only editorial content from certain suppliers
  --date-start: string # Show only editorial content generated on or after a specific date (format: date, e.g. 2020-05-29)
  --date-end: string # Show only editorial content generated on or before a specific date (format: date, e.g. 2021-05-29)
  --per-page: int # Number of results per page (default: 20)
  --cursor: string # The cursor of the page with which to start fetching results; this cursor is returned from previous requests (e.g. eyJ2IjoxLCJzIjoxfQ==)
]: nothing -> record<data: table<aspect: float, assets: record, byline: string, caption: string, categories: list, date_taken: string, description: string, id: string, keywords: list, special_instructions: string, title: string>, message: string, next: string, page: int, per_page: int, prev: string, search_id: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "supplier_code" $supplier_code "multi") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/images/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "sort": $qp_sort, "category": $category, "country": $country, "supplier_code": $supplier_code, "date_start": $date_start, "date_end": $date_end, "per_page": $per_page, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List updated content
#
# GET /v2/editorial/images/updated
# operationId: getUpdatedEditorialImages
export def "editorial-images-updated get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Specify `addition` to return only images that were added or `edit` to return only images that were edited or deleted (e.g. edit)
  --date-updated-start: string # Show images images added, edited, or deleted after the specified date. Acceptable range is 1970-01-01T00:00:01 to 2038-01-19T00:00:00. (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --date-updated-end: string # Show images images added, edited, or deleted before the specified date. Acceptable range is 1970-01-01T00:00:01 to 2038-01-19T00:00:00. (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --date-taken-start: string # Show images that were taken on or after the specified date; use this parameter if you want recently created images from the collection instead of updated older assets (format: date, e.g. 2020-02-04)
  --date-taken-end: string # Show images that were taken before the specified date (format: date, e.g. 2020-02-05)
  --cursor: string # The cursor of the page with which to start fetching results; this cursor is returned from previous requests (e.g. eyJ2IjoxLCJzIjoyfQ==)
  --qp-sort: string@sort-completer # Sort by (default: newest, e.g. newest)
  --supplier-code: list<string> # Show only editorial content from certain suppliers (e.g. ABC)
  --country: string # Show only editorial content that is available for distribution in a certain country (format: country-code-3, e.g. USA)
  --per-page: int # Number of results per page (default: 500, e.g. 200)
]: nothing -> record<data: table<aspect: float, assets: record, byline: string, caption: string, categories: list, commercial_status: record, created_time: string, date_taken: string, description: string, id: string, keywords: list, rights: record, special_instructions: string, supplier_code: string, title: string, updated_time: string, updates: list>, message: string, next: string, per_page: int, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "date_updated_start" $date_updated_start "scalar") (serialize-qp "date_updated_end" $date_updated_end "scalar") (serialize-qp "date_taken_start" $date_taken_start "scalar") (serialize-qp "date_taken_end" $date_taken_end "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "supplier_code" $supplier_code "multi") (serialize-qp "country" $country "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/images/updated" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "date_updated_start": $date_updated_start, "date_updated_end": $date_updated_end, "date_taken_start": $date_taken_start, "date_taken_end": $date_taken_end, "cursor": $cursor, "sort": $qp_sort, "supplier_code": $supplier_code, "country": $country, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get editorial content details
#
# GET /v2/editorial/images/{id}
# operationId: getEditorialImage
export def "editorial-images get" [
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
  --country: string # Returns only if the content is available for distribution in a certain country (format: country-code-3, e.g. USA)
]: nothing -> record<aspect: float, assets: record<medium_jpg: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, original: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, small_jpg: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, thumb_170: record<height: int, url: string, width: int>, thumb_220: record<height: int, url: string, width: int>, watermark_1500: record<height: int, url: string, width: int>, watermark_450: record<height: int, url: string, width: int>>, byline: string, caption: string, categories: table<name: string>, date_taken: string, description: string, id: string, keywords: list<string>, special_instructions: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/editorial/images/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# (Deprecated) License editorial content
#
# POST /v2/editorial/licenses
# DEPRECATED
# operationId: licenseEditorialImage
# --editorial item shape: {editorial_id: string, license: string, metadata?: record, size?: "small"|"medium"|"original"}
@deprecated
export def "editorial-licenses create-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: any # A valid ISO 3166-1 Alpha-2 or ISO 3166-1 Alpha-3 code. (e.g. USA)
  editorial: list # Editorial content to license — item shape: {editorial_id: string, license: string, metadata?: record, size?: "small"|"medium"|"original"}
]: any -> record<data: table<allotment_charge: int, download: record, editorial_id: string, error: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/editorial/licenses" $auth.query)
  let req_body = {"country": $country, "editorial": $editorial} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# (Deprecated) Get editorial livefeed list
#
# GET /v2/editorial/livefeeds
# DEPRECATED
# operationId: getEditorialLivefeedList
@deprecated
export def "editorial-livefeeds get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Returns only livefeeds that are available for distribution in a certain country (format: country-code-3, e.g. USA)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
]: nothing -> record<data: table<cover_item: record, created_time: string, id: string, name: string, total_item_count: int>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/livefeeds" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# (Deprecated) Get editorial livefeed
#
# GET /v2/editorial/livefeeds/{id}
# DEPRECATED
# operationId: getEditorialLivefeed
@deprecated
export def "editorial-livefeeds get" [
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
  --country: string # Returns only if the livefeed is available for distribution in a certain country (format: country-code-3, e.g. USA)
]: nothing -> record<cover_item: record<height: int, id: string, url: string, width: int>, created_time: string, id: string, name: string, total_item_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/editorial/livefeeds/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# (Deprecated) Get editorial livefeed items
#
# GET /v2/editorial/livefeeds/{id}/items
# DEPRECATED
# operationId: getEditorialLivefeedItems
@deprecated
export def "editorial-livefeeds-items get" [
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
  --country: string # Returns only if the livefeed items are available for distribution in a certain country (format: country-code-3, e.g. USA)
]: nothing -> record<data: table<aspect: float, assets: record, byline: string, caption: string, categories: list, date_taken: string, description: string, id: string, keywords: list, special_instructions: string, title: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/editorial/livefeeds/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# (Deprecated) Search editorial content
#
# GET /v2/editorial/search
# DEPRECATED
# operationId: searchEditorial
@deprecated
export def "editorial-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # One or more search terms separated by spaces
  --qp-sort: string@sort-completer-4 # Sort by (default: relevant)
  --category: string # Show editorial content within a certain editorial category; specify by category name
  --country: string # Show only editorial content that is available for distribution in a certain country (format: country-code-3, e.g. USA)
  --supplier-code: list<string> # Show only editorial content from certain suppliers
  --date-start: string # Show only editorial content generated on or after a specific date (format: date)
  --date-end: string # Show only editorial content generated on or before a specific date (format: date)
  --per-page: int # Number of results per page (default: 20)
  --cursor: string # The cursor of the page with which to start fetching results; this cursor is returned from previous requests
]: nothing -> record<data: table<aspect: float, assets: record, byline: string, caption: string, categories: list, date_taken: string, description: string, id: string, keywords: list, special_instructions: string, title: string>, message: string, next: string, page: int, per_page: int, prev: string, search_id: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "supplier_code" $supplier_code "multi") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "sort": $qp_sort, "category": $category, "country": $country, "supplier_code": $supplier_code, "date_start": $date_start, "date_end": $date_end, "per_page": $per_page, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# (Deprecated) List updated content
#
# GET /v2/editorial/updated
# DEPRECATED
# operationId: getUpdatedEditorialImage
@deprecated
export def "editorial-updated get-image" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Specify `addition` to return only images that were added or `edit` to return only images that were edited or deleted (e.g. edit)
  --date-updated-start: string # Show images images added, edited, or deleted after the specified date. Acceptable range is 1970-01-01T00:00:01 to 2038-01-19T00:00:00. (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --date-updated-end: string # Show images images added, edited, or deleted before the specified date. Acceptable range is 1970-01-01T00:00:01 to 2038-01-19T00:00:00. (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --date-taken-start: string # Show images that were taken on or after the specified date; use this parameter if you want recently created images from the collection instead of updated older assets (format: date, e.g. 2020-02-04)
  --date-taken-end: string # Show images that were taken before the specified date (format: date, e.g. 2020-02-05)
  --cursor: string # The cursor of the page with which to start fetching results; this cursor is returned from previous requests (e.g. eyJ2IjoxLCJzIjoyfQ==)
  --qp-sort: string@sort-completer # Sort by (default: newest, e.g. newest)
  --supplier-code: list<string> # Show only editorial content from certain suppliers (e.g. ABC)
  --country: string # Show only editorial content that is available for distribution in a certain country (format: country-code-3, e.g. USA)
  --per-page: int # Number of results per page (default: 500, e.g. 200)
]: nothing -> record<data: table<aspect: float, assets: record, byline: string, caption: string, categories: list, commercial_status: record, created_time: string, date_taken: string, description: string, id: string, keywords: list, rights: record, special_instructions: string, supplier_code: string, title: string, updated_time: string, updates: list>, message: string, next: string, per_page: int, prev: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "date_updated_start" $date_updated_start "scalar") (serialize-qp "date_updated_end" $date_updated_end "scalar") (serialize-qp "date_taken_start" $date_taken_start "scalar") (serialize-qp "date_taken_end" $date_taken_end "scalar") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "supplier_code" $supplier_code "multi") (serialize-qp "country" $country "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/updated" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "date_updated_start": $date_updated_start, "date_updated_end": $date_updated_end, "date_taken_start": $date_taken_start, "date_taken_end": $date_taken_end, "cursor": $cursor, "sort": $qp_sort, "supplier_code": $supplier_code, "country": $country, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List editorial video categories
#
# GET /v2/editorial/videos/categories
# operationId: listEditorialVideoCategories
export def "editorial-videos-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/editorial/videos/categories" $auth.query)
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

# List editorial video licenses
#
# GET /v2/editorial/videos/licenses
# operationId: getEditorialVideoLicenseList
export def "editorial-videos-licenses get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-id: string # Show licenses for the specified editorial video ID (e.g. 12345678)
  --license: string # Show editorial videos that are available with the specified license name (e.g. premier_editorial_all_media)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --qp-sort: string@sort-completer # Sort order (default: newest)
  --username: string # Filter licenses by username of licensee (e.g. aUniqueUsername)
  --start-date: string # Show licenses created on or after the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --end-date: string # Show licenses created before the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --download-availability: string@download-availability-completer # Filter licenses by download availability (default: all)
  --team-history: oneof<nothing, bool> # Set to true to see license history for all members of your team. (default: false)
]: nothing -> record<data: table<audio: record, download_time: string, id: string, image: record, is_downloadable: bool, license: string, metadata: record, revshare: record, subscription_id: string, user: record, video: record>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "video_id" $video_id "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "download_availability" $download_availability "scalar") (serialize-qp "team_history" $team_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/videos/licenses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"video_id": $video_id, "license": $license, "page": $page, "per_page": $per_page, "sort": $qp_sort, "username": $username, "start_date": $start_date, "end_date": $end_date, "download_availability": $download_availability, "team_history": $team_history} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# License editorial video content
#
# POST /v2/editorial/videos/licenses
# operationId: licenseEditorialVideo
# --editorial item shape: {editorial_id: string, license: "premier_editorial_video_digital_only"|"premier_editorial_video_all_media"|"premier_editorial_video_all_media_single_territory"|"premier_editorial_video_comp", metadata?: record, size?: "original"}
export def "editorial-videos-licenses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  country: any # A valid ISO 3166-1 Alpha-2 or ISO 3166-1 Alpha-3 code. (e.g. USA)
  editorial: list # Editorial content to license — item shape: {editorial_id: string, license: "premier_editorial_video_digital_only"|"premier_editorial_video_all_media"|"premier_editorial_video_all_media_single_territory"|"premier_editorial_video_comp", metadata?: record, size?: "original"}
]: any -> record<data: table<allotment_charge: int, download: record, editorial_id: string, error: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/editorial/videos/licenses" $auth.query)
  let req_body = {"country": $country, "editorial": $editorial} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# Search editorial video content
#
# GET /v2/editorial/videos/search
# operationId: searchEditorialVideos
export def "editorial-videos-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # One or more search terms separated by spaces (e.g. The Academy Awards)
  --qp-sort: string@sort-completer-4 # Sort by (default: relevant)
  --category: string # Show editorial content with each of the specified editorial categories; specify category names in a comma-separated list (e.g. Alone,Performing)
  --country: string # Show only editorial video content that is available for distribution in a certain country (format: country-code-3, e.g. USA)
  --supplier-code: list<string> # Show only editorial video content from certain suppliers
  --date-start: string # Show only editorial video content generated on or after a specific date (format: date, e.g. 2020-05-29)
  --date-end: string # Show only editorial video content generated on or before a specific date (format: date, e.g. 2021-05-29)
  --resolution: string@resolution-completer # Show only editorial video content with specific resolution (e.g. 4k)
  --fps: float # Show only editorial video content generated with specific frames per second (e.g. 24)
  --per-page: int # Number of results per page (default: 20)
  --cursor: string # The cursor of the page with which to start fetching results; this cursor is returned from previous requests (e.g. eyJ2IjoxLCJzIjoxfQ==)
]: nothing -> record<data: table<aspect: float, assets: record, byline: string, caption: string, categories: list, date_taken: string, description: string, id: string, keywords: list, title: string>, message: string, next: string, page: int, per_page: int, prev: string, search_id: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "supplier_code" $supplier_code "multi") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "fps" $fps "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/editorial/videos/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "sort": $qp_sort, "category": $category, "country": $country, "supplier_code": $supplier_code, "date_start": $date_start, "date_end": $date_end, "resolution": $resolution, "fps": $fps, "per_page": $per_page, "cursor": $cursor} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get editorial video content details
#
# GET /v2/editorial/videos/{id}
# operationId: getEditorialVideo
export def "editorial-videos get" [
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
  --country: string # Returns only if the content is available for distribution in a certain country (format: country-code-3, e.g. USA)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<aspect: float, assets: record<original: record<display_name: string, file_size: int, format: string, fps: float, height: int, is_licensable: bool, width: int>, preview_mp4: record<url: string>, preview_webm: record<url: string>, thumb_jpg: record<url: string>>, byline: string, caption: string, categories: table<name: string>, date_taken: string, description: string, id: string, keywords: list<string>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/editorial/videos/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# (Deprecated) Get editorial content details
#
# GET /v2/editorial/{id}
# DEPRECATED
@deprecated
export def "editorial get" [
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
  --country: string # Returns only if the content is available for distribution in a certain country (format: country-code-3, e.g. USA)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<aspect: float, assets: record<medium_jpg: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, original: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, small_jpg: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, thumb_170: record<height: int, url: string, width: int>, thumb_220: record<height: int, url: string, width: int>, watermark_1500: record<height: int, url: string, width: int>, watermark_450: record<height: int, url: string, width: int>>, byline: string, caption: string, categories: table<name: string>, date_taken: string, description: string, id: string, keywords: list<string>, special_instructions: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "country" $country "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/editorial/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"country": $country, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List images
#
# GET /v2/images
# operationId: getImageList
export def "images get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # One or more image IDs (e.g. [1110335168, 465011609])
  --view: string@view-completer # Amount of detail to render in the response (default: minimal, e.g. minimal)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, aspect: float, assets: record, categories: list, contributor: record, description: string, has_model_release: bool, has_property_release: bool, id: string, image_type: string, insights: record, is_adult: bool, is_editorial: bool, is_illustration: bool, keywords: list, media_type: string, model_releases: list, models: list, releases: list, url: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "view" $view "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "view": $view, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Upload ephemeral images
#
# POST /v2/images
# DEPRECATED
# operationId: uploadEphemeralImage
@deprecated
export def "images upload-ephemeral" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  base64_image: string # A Base 64 encoded jpeg or png; images can be no larger than 10mb and can be no larger than 10,000 pixels in width or height
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/images" $auth.query)
  let req_body = {"base64_image": $base64_image} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List image categories
#
# GET /v2/images/categories
# operationId: listImageCategories
export def "images-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
]: nothing -> record<data: table<id: string, name: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/categories" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List image collections
#
# GET /v2/images/collections
# operationId: getImageCollectionList
export def "images-collections get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: list<string> # Which sharing information to include in the response, such as a URL to the collection (e.g. share_code)
  --page: int # Page number (default: 1, e.g. 1)
  --per-page: int # Number of results per page (default: 100, e.g. 2)
]: nothing -> record<data: table<cover_item: record, created_time: string, id: string, items_updated_time: string, name: string, share_code: string, share_url: string, total_item_count: int, updated_time: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/collections" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed, "page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create image collections
#
# POST /v2/images/collections
# operationId: createImageCollection
export def "images-collections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the collection
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/images/collections" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List featured image collections
#
# GET /v2/images/collections/featured
# operationId: getFeaturedImageCollectionList
export def "images-collections-featured get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string@embed-completer # Which sharing information to include in the response, such as a URL to the collection (e.g. share_url)
  --type: list<string> # The types of collections to return (e.g. [photo])
  --asset-hint: string@asset-hint-completer # Cover image size (default: 1x, e.g. 1x)
]: nothing -> record<data: table<cover_item: record, created_time: string, hero_item: record, id: string, items_updated_time: string, name: string, share_url: string, total_item_count: int, updated_time: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "scalar") (serialize-qp "type" $type "multi") (serialize-qp "asset_hint" $asset_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/collections/featured" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed, "type": $type, "asset_hint": $asset_hint} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the details of featured image collections
#
# GET /v2/images/collections/featured/{id}
# operationId: getFeaturedImageCollection
export def "images-collections-featured get" [
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
  --embed: string@embed-completer # Which sharing information to include in the response, such as a URL to the collection
  --asset-hint: string@asset-hint-completer # Cover image size (default: 1x)
]: nothing -> record<cover_item: record<url: string>, created_time: string, hero_item: record<url: string>, id: string, items_updated_time: string, name: string, share_url: string, total_item_count: int, updated_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "scalar") (serialize-qp "asset_hint" $asset_hint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/collections/featured/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed, "asset_hint": $asset_hint} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the contents of featured image collections
#
# GET /v2/images/collections/featured/{id}/items
# operationId: getFeaturedImageCollectionItems
export def "images-collections-featured-items get" [
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
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 100)
]: nothing -> record<data: table<added_time: string, id: string, media_type: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/collections/featured/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete image collections
#
# DELETE /v2/images/collections/{id}
# operationId: deleteImageCollection
export def "images-collections delete" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/collections/{id}") $auth.query)
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

# Get the details of image collections
#
# GET /v2/images/collections/{id}
# operationId: getImageCollection
export def "images-collections get" [
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
  --embed: list<string> # Which sharing information to include in the response, such as a URL to the collection
  --share-code: string # Code to retrieve a shared collection
]: nothing -> record<cover_item: record<added_time: string, id: string, media_type: string>, created_time: string, id: string, items_updated_time: string, name: string, share_code: string, share_url: string, total_item_count: int, updated_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "multi") (serialize-qp "share_code" $share_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/collections/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed, "share_code": $share_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Rename image collections
#
# POST /v2/images/collections/{id}
# operationId: renameImageCollection
export def "images-collections rename" [
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
  name: string # The new name of the collection
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/collections/{id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove images from collections
#
# DELETE /v2/images/collections/{id}/items
# operationId: deleteImageCollectionItems
export def "images-collections-items delete" [
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
  --item-id: list<string> # One or more image IDs to remove from the collection
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "item_id" $item_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/collections/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"item_id": $item_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the contents of image collections
#
# GET /v2/images/collections/{id}/items
# operationId: getImageCollectionItems
export def "images-collections-items get" [
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
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 100)
  --share-code: string # Code to retrieve the contents of a shared collection
  --qp-sort: string@sort-completer # Sort order (default: oldest)
]: nothing -> record<data: table<added_time: string, id: string, media_type: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "share_code" $share_code "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/collections/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "share_code": $share_code, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add images to collections
#
# POST /v2/images/collections/{id}/items
# operationId: addImageCollectionItems
# --items item shape: {added_time?: string, id: string, media_type?: string}
export def "images-collections-items create" [
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
  items: list # List of items — item shape: {added_time?: string, id: string, media_type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/collections/{id}/items") $auth.query)
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# List image licenses
#
# GET /v2/images/licenses
# operationId: getImageLicenseList
export def "images-licenses get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --image-id: string # Show licenses for the specified image ID (e.g. 12345678)
  --license: string # Show images that are available with the specified license, such as `standard` or `enhanced`; prepending a `-` sign excludes results from that license (e.g. standard)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --qp-sort: string@sort-completer # Sort order (default: newest)
  --username: string # Filter licenses by username of licensee (e.g. aUniqueUsername)
  --start-date: string # Show licenses created on or after the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --end-date: string # Show licenses created before the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --download-availability: string@download-availability-completer # Filter licenses by download availability (default: all)
  --team-history: oneof<nothing, bool> # Set to true to see license history for all members of your team. (default: false)
]: nothing -> record<data: table<audio: record, download_time: string, id: string, image: record, is_downloadable: bool, license: string, metadata: record, revshare: record, subscription_id: string, user: record, video: record>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "image_id" $image_id "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "download_availability" $download_availability "scalar") (serialize-qp "team_history" $team_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/licenses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"image_id": $image_id, "license": $license, "page": $page, "per_page": $per_page, "sort": $qp_sort, "username": $username, "start_date": $start_date, "end_date": $end_date, "download_availability": $download_availability, "team_history": $team_history} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# License images
#
# POST /v2/images/licenses
# operationId: licenseImages
@deprecated --flag format
export def "images-licenses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-id: string # Subscription ID to use to license the image
  --format: string@format-completer # (Deprecated) Image format (DEPRECATED)
  --size: string@size-completer # Image size (default: huge)
  --search-id: string # Search ID that was provided in the results of an image search
  images: list # Images to create licenses for
]: any -> record<data: table<allotment_charge: int, download: record, error: string, image_id: string, license_id: string, price: record>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_id" $subscription_id "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/licenses" $qp $auth.query)
  let req_body = {"images": $images} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"subscription_id": $subscription_id, "format": $format, "size": $size, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Download images
#
# POST /v2/images/licenses/{id}/downloads
# operationId: downloadImage
# --auth_cookie shape: {name: string, value: string}
@deprecated --flag show-modal
@deprecated --flag verification-code
export def "images-licenses-downloads download" [
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
  --auth-cookie: record # Cookie object (e.g. {name: The name of the cookie, value: The value of the cookie}) — shape: {name: string, value: string}
  --show-modal: oneof<nothing, bool> # (Deprecated) (DEPRECATED)
  --size: string@size-completer-1 # Size of the image
  --verification-code: string # (Deprecated) (DEPRECATED)
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/licenses/{id}/downloads") $auth.query)
  let req_body = {"auth_cookie": $auth_cookie, "show_modal": $show_modal, "size": $size, "verification_code": $verification_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List recommended images
#
# GET /v2/images/recommendations
# operationId: getImageRecommendations
export def "images-recommendations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # Image IDs (e.g. [465011609])
  --max-items: int # Maximum number of results returned in the response (default: 20)
  --safe: oneof<nothing, bool> # Restrict results to safe images (default: true)
]: nothing -> record<data: table<id: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "max_items" $max_items "scalar") (serialize-qp "safe" $safe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/recommendations" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "max_items": $max_items, "safe": $safe} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Search for images
#
# GET /v2/images/search
# operationId: searchImages
@deprecated --flag height
@deprecated --flag width
export def "images-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --added-date: string # Show images added on the specified date (format: date, e.g. 2021-03-29)
  --added-date-start: string # Show images added on or after the specified date (format: date, e.g. 2021-03-29)
  --aspect-ratio-min: float # Show images with the specified aspect ratio or higher, using a positive decimal of the width divided by the height, such as 1.7778 for a 16:9 image (e.g. 1.7778)
  --aspect-ratio-max: float # Show images with the specified aspect ratio or lower, using a positive decimal of the width divided by the height, such as 1.7778 for a 16:9 image (e.g. 1.7778)
  --aspect-ratio: float # Show images with the specified aspect ratio, using a positive decimal of the width divided by the height, such as 1.7778 for a 16:9 image (e.g. 1.7778)
  --ai-search: oneof<nothing, bool> # Set to true and specify the `ai_objective` and `ai_industry` parameters to use AI-powered search; the API returns information about how well images meet the objective for the industry
  --ai-labels-limit: int # For AI-powered search, specify the maximum number of labels to return (default: 20)
  --ai-industry: string@ai-industry-completer # For AI-powered search, specify the industry to target; requires that the `ai_search` parameter is set to true
  --ai-objective: string@ai-objective-completer # For AI-powered search, specify the goal of the media; requires that the `ai_search` parameter is set to true
  --added-date-end: string # Show images added before the specified date (format: date, e.g. 2021-03-29)
  --category: string # Show images with the specified Shutterstock-defined category; specify a category name or ID
  --color: string # Specify either a hexadecimal color in the format '4F21EA' or 'grayscale'; the API returns images that use similar colors (e.g. 4F21EA)
  --contributor: list<string> # Show images with the specified contributor names or IDs, allows multiple (e.g. [123456])
  --contributor-country: string # Show images from contributors in one or more specified countries, or start with NOT to exclude a country from the search (e.g. US)
  --fields: string # Fields to display in the response; see the documentation for the fields parameter in the overview section
  --height: int # (Deprecated; use height_from and height_to instead) Show images with the specified height (DEPRECATED)
  --height-from: int # Show images with the specified height or larger, in pixels (e.g. 1080)
  --height-to: int # Show images with the specified height or smaller, in pixels (e.g. 1080)
  --image-type: list<string> # Show images of the specified type (e.g. photo)
  --keyword-safe-search: oneof<nothing, bool> # Hide results with potentially unsafe keywords (default: true)
  --language: string@language-completer # Set query and result language (uses Accept-Language header if not set) (e.g. cs)
  --license: list<string> # Show only images with the specified license
  --model: list<string> # Show image results with the specified model IDs (e.g. [12345, 67890])
  --orientation: string@orientation-completer # Show image results with horizontal or vertical orientation (e.g. vertical)
  --page: int # Page number (default: 1, e.g. 1)
  --per-page: int # Number of results per page (default: 20, e.g. 50)
  --people-model-released: oneof<nothing, bool> # Show images of people with a signed model release (e.g. true)
  --people-age: string@people-age-completer # Show images that feature people of the specified age category (e.g. 20s)
  --people-ethnicity: list<string> # Show images with people of the specified ethnicities, or start with NOT to show images without those ethnicities (e.g. hispanic)
  --people-gender: string@people-gender-completer # Show images with people of the specified gender (e.g. both)
  --people-number: int # Show images with the specified number of people (e.g. 2)
  --query: string # One or more search terms separated by spaces; you can use NOT to filter out images that match a term (e.g. dogs on the beach)
  --region: string # Raise or lower search result rankings based on the result's relevance to a specified region; you can provide a country code or an IP address from which the API infers a country (e.g. US)
  --safe: oneof<nothing, bool> # Enable or disable safe search (default: true)
  --qp-sort: string@sort-completer-2 # Sort by (default: popular)
  --spellcheck-query: oneof<nothing, bool> # Spellcheck the search query and return results on suggested spellings (default: true)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal)
  --width: int # (Deprecated; use width_from and width_to instead) Show images with the specified width (DEPRECATED)
  --width-from: int # Show images with the specified width or larger, in pixels (e.g. 1920)
  --width-to: int # Show images with the specified width or smaller, in pixels (e.g. 1920)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, aspect: float, assets: record, categories: list, contributor: record, description: string, has_model_release: bool, has_property_release: bool, id: string, image_type: string, insights: record, is_adult: bool, is_editorial: bool, is_illustration: bool, keywords: list, media_type: string, model_releases: list, models: list, releases: list, url: string>, insights: record<label_performance: list<record>>, message: string, page: int, per_page: int, search_id: string, spellcheck_info: record, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "added_date" $added_date "scalar") (serialize-qp "added_date_start" $added_date_start "scalar") (serialize-qp "aspect_ratio_min" $aspect_ratio_min "scalar") (serialize-qp "aspect_ratio_max" $aspect_ratio_max "scalar") (serialize-qp "aspect_ratio" $aspect_ratio "scalar") (serialize-qp "ai_search" $ai_search "scalar") (serialize-qp "ai_labels_limit" $ai_labels_limit "scalar") (serialize-qp "ai_industry" $ai_industry "scalar") (serialize-qp "ai_objective" $ai_objective "scalar") (serialize-qp "added_date_end" $added_date_end "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "contributor" $contributor "multi") (serialize-qp "contributor_country" $contributor_country "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "height_from" $height_from "scalar") (serialize-qp "height_to" $height_to "scalar") (serialize-qp "image_type" $image_type "multi") (serialize-qp "keyword_safe_search" $keyword_safe_search "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "license" $license "multi") (serialize-qp "model" $model "multi") (serialize-qp "orientation" $orientation "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "people_model_released" $people_model_released "scalar") (serialize-qp "people_age" $people_age "scalar") (serialize-qp "people_ethnicity" $people_ethnicity "multi") (serialize-qp "people_gender" $people_gender "scalar") (serialize-qp "people_number" $people_number "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "safe" $safe "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "spellcheck_query" $spellcheck_query "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "width_from" $width_from "scalar") (serialize-qp "width_to" $width_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"added_date": $added_date, "added_date_start": $added_date_start, "aspect_ratio_min": $aspect_ratio_min, "aspect_ratio_max": $aspect_ratio_max, "aspect_ratio": $aspect_ratio, "ai_search": $ai_search, "ai_labels_limit": $ai_labels_limit, "ai_industry": $ai_industry, "ai_objective": $ai_objective, "added_date_end": $added_date_end, "category": $category, "color": $color, "contributor": $contributor, "contributor_country": $contributor_country, "fields": $fields, "height": $height, "height_from": $height_from, "height_to": $height_to, "image_type": $image_type, "keyword_safe_search": $keyword_safe_search, "language": $language, "license": $license, "model": $model, "orientation": $orientation, "page": $page, "per_page": $per_page, "people_model_released": $people_model_released, "people_age": $people_age, "people_ethnicity": $people_ethnicity, "people_gender": $people_gender, "people_number": $people_number, "query": $query, "region": $region, "safe": $safe, "sort": $qp_sort, "spellcheck_query": $spellcheck_query, "view": $view, "width": $width, "width_from": $width_from, "width_to": $width_to} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get suggestions for a search term
#
# GET /v2/images/search/suggestions
# operationId: getImageSuggestions
export def "images-search-suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search term for which you want keyword suggestions (e.g. cats)
  --limit: int # Limit the number of suggestions (default: 10)
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/search/suggestions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get keywords from text
#
# POST /v2/images/search/suggestions
# operationId: getImageKeywordSuggestions
export def "images-search-suggestions get-keyword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  text: string # Plain text to extract keywords from
]: any -> record<keywords: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/images/search/suggestions" $auth.query)
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# List updated images
#
# GET /v2/images/updated
# operationId: getUpdatedImages
export def "images-updated get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: list<string> # Show images that were added, deleted, or edited; by default, the endpoint returns images that were updated in any of these ways (e.g. addition)
  --start-date: string # Show images updated on or after the specified date (format: date, e.g. 2021-03-29)
  --end-date: string # Show images updated before the specified date (format: date, e.g. 2021-03-29)
  --interval: string # Show images updated in the specified time period, where the time period is an interval (like SQL INTERVAL) such as 1 DAY, 6 HOUR, or 30 MINUTE; the default is 1 HOUR, which shows images that were updated in the hour preceding the request (default: 1 HOUR)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 100)
  --qp-sort: string@sort-completer # Sort order (default: newest)
]: nothing -> record<data: table<id: string, updated_time: string, updates: list>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/updated" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"type": $type, "start_date": $start_date, "end_date": $end_date, "interval": $interval, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details about images
#
# GET /v2/images/{id}
# operationId: getImage
export def "images get" [
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
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
  --view: string@view-completer # Amount of detail to render in the response (default: full)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<added_date: string, affiliate_url: string, aspect: float, assets: record<huge_jpg: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, huge_thumb: record<height: int, url: string, width: int>, large_thumb: record<height: int, url: string, width: int>, medium_jpg: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, preview: record<height: int, url: string, width: int>, preview_1000: record<height: int, url: string, width: int>, preview_1500: record<height: int, url: string, width: int>, small_jpg: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, small_thumb: record<height: int, url: string, width: int>, supersize_jpg: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>, vector_eps: record<display_name: string, dpi: int, file_size: int, format: string, height: int, is_licensable: bool, width: int>>, categories: table<id: string, name: string>, contributor: record<id: string>, description: string, has_model_release: bool, has_property_release: bool, id: string, image_type: string, insights: record<labels: list<string>>, is_adult: bool, is_editorial: bool, is_illustration: bool, keywords: list<string>, media_type: string, model_releases: table<id: string>, models: table<id: string>, releases: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language, "view": $view, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List similar images
#
# GET /v2/images/{id}/similar
# operationId: listSimilarImages
export def "images-similar list" [
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
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, aspect: float, assets: record, categories: list, contributor: record, description: string, has_model_release: bool, has_property_release: bool, id: string, image_type: string, insights: record, is_adult: bool, is_editorial: bool, is_illustration: bool, keywords: list, media_type: string, model_releases: list, models: list, releases: list, url: string>, insights: record<label_performance: list<record>>, message: string, page: int, per_page: int, search_id: string, spellcheck_info: record, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/images/{id}/similar") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language, "page": $page, "per_page": $per_page, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get access tokens
#
# POST /v2/oauth/access_token
# operationId: createAccessToken
export def "oauth-access-token create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  client_id: string # Client ID (Consumer Key) of your application
  --client-secret: string # Client Secret (Consumer Secret) of your application
  --code: string # Response code from the /oauth/authorize flow; required if grant_type=authorization_code
  --expires: oneof<nothing, bool> # Whether or not the token expires, expiring tokens come with a refresh_token to renew the access_token (default: false)
  grant_type: string@grant-type-completer # Grant type: authorization_code generates user tokens, client_credentials generates short-lived client grants
  --realm: string@realm-completer # User type to be authorized (usually 'customer') (default: customer)
  --refresh-token: string # Pass this along with grant_type=refresh_token to get a fresh access token
]: any -> record<access_token: string, expires_in: int, refresh_token: string, token_type: string, user_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/oauth/access_token" $auth.query)
  let req_body = {"client_id": $client_id, "client_secret": $client_secret, "code": $code, "expires": $expires, "grant_type": $grant_type, "realm": $realm, "refresh_token": $refresh_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# Authorize applications
#
# GET /v2/oauth/authorize
# operationId: authorize
export def "oauth-authorize get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string # Client ID (Consumer Key) of your application (e.g. 6d097450b209c6dcd859)
  --realm: string@realm-completer # User type to be authorized (usually 'customer') (default: customer, e.g. customer)
  --redirect-uri: string # The callback URI to send the request to after authorization; must use a host name that is registered with your application (e.g. localhost)
  --response-type: string@response-type-completer # Type of temporary authorization code that will be used to generate an access code; the only valid value is 'code' (e.g. code)
  --scope: string # Space-separated list of scopes to be authorized (default: user.view, e.g. user.view)
  --state: string # Unique value used by the calling app to verify the request (e.g. 1540290465000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "realm" $realm "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "response_type" $response_type "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/oauth/authorize" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"client_id": $client_id, "realm": $realm, "redirect_uri": $redirect_uri, "response_type": $response_type, "scope": $scope, "state": $state} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [302]
}

# List details about sound effects
#
# GET /v2/sfx
# operationId: getSfxListDetails
export def "sfx get-list-details" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # One or more sound effect IDs (e.g. [1110335168, 465011609])
  --view: string@view-completer # Amount of detail to render in the response (default: minimal, e.g. minimal)
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
  --library: string@library-completer-1 # Which library to fetch from (e.g. shutterstock)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, artist: string, assets: record, contributor: record, description: string, duration: float, id: string, keywords: list, media_type: string, releases: list, title: string, updated_time: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "view" $view "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "library" $library "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sfx" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "view": $view, "language": $language, "library": $library, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List sound effects licenses
#
# GET /v2/sfx/licenses
# operationId: getSfxLicenseList
export def "sfx-licenses get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sfx-id: string # Show licenses for the specified sound effects ID (e.g. 12345678)
  --license: string # Show sound effects that are available with the specified license, such as `standard` or `enhanced`; prepending a `-` sign excludes results from that license (e.g. standard)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --qp-sort: string@sort-completer # Sort order (default: newest)
  --username: string # Filter licenses by username of licensee (e.g. aUniqueUsername)
  --start-date: string # Show licenses created on or after the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --end-date: string # Show licenses created before the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --license-id: string # Filter by the license ID
  --download-availability: string@download-availability-completer # Filter licenses by download availability (default: all)
  --team-history: oneof<nothing, bool> # Set to true to see license history for all members of your team. (default: false)
]: nothing -> record<data: table<audio: record, download_time: string, id: string, image: record, is_downloadable: bool, license: string, metadata: record, revshare: record, subscription_id: string, user: record, video: record>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sfx_id" $sfx_id "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "license_id" $license_id "scalar") (serialize-qp "download_availability" $download_availability "scalar") (serialize-qp "team_history" $team_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sfx/licenses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"sfx_id": $sfx_id, "license": $license, "page": $page, "per_page": $per_page, "sort": $qp_sort, "username": $username, "start_date": $start_date, "end_date": $end_date, "license_id": $license_id, "download_availability": $download_availability, "team_history": $team_history} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# License sound effects
#
# POST /v2/sfx/licenses
# operationId: licensesSFX
# --sound_effects item shape: {audio_layout?: "ambisonic"|"5.1"|"stereo", format?: "wav"|"mp3", search_id?: string, sfx_id: string, subscription_id: string}
export def "sfx-licenses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  sound_effects: list # Sound effects to license for — item shape: {audio_layout?: "ambisonic"|"5.1"|"stereo", format?: "wav"|"mp3", search_id?: string, sfx_id: string, subscription_id: string}
]: any -> record<data: table<allotment_charge: int, download: record, error: string, license_id: string, sfx_id: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/sfx/licenses" $auth.query)
  let req_body = {"sound_effects": $sound_effects} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# Download sound effects
#
# POST /v2/sfx/licenses/{id}/downloads
# operationId: downloadSfx
export def "sfx-licenses-downloads download" [
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
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/sfx/licenses/{id}/downloads") $auth.query)
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

# Search for sound effects
#
# GET /v2/sfx/search
# operationId: searchSFX
export def "sfx-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --added-date: string # Show sound effects added on the specified date (format: date, e.g. 2022-09-23)
  --added-date-start: string # Show sound effects added on or after the specified date (format: date, e.g. 2021-03-29)
  --added-date-end: string # Show sound effects added before the specified date (format: date, e.g. 2021-03-29)
  --duration: int # Show sound effects with the specified duration in seconds (e.g. 180)
  --duration-from: int # Show sound effects with the specified duration or longer in seconds (e.g. 30)
  --duration-to: int # Show sound effects with the specified duration or shorter in seconds (e.g. 180)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20, e.g. 1)
  --query: string # One or more search terms separated by spaces (e.g. drum)
  --safe: oneof<nothing, bool> # Enable or disable safe search (default: true)
  --qp-sort: string@sort-completer-5 # Sort by (default: popular, e.g. popular)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal, e.g. full)
  --language: string@language-completer # Set query and result language (uses Accept-Language header if not set) (e.g. cs)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, artist: string, assets: record, contributor: record, description: string, duration: float, id: string, keywords: list, media_type: string, releases: list, title: string, updated_time: string, url: string>, message: string, page: int, per_page: int, search_id: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "added_date" $added_date "scalar") (serialize-qp "added_date_start" $added_date_start "scalar") (serialize-qp "added_date_end" $added_date_end "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "duration_from" $duration_from "scalar") (serialize-qp "duration_to" $duration_to "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "safe" $safe "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sfx/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"added_date": $added_date, "added_date_start": $added_date_start, "added_date_end": $added_date_end, "duration": $duration, "duration_from": $duration_from, "duration_to": $duration_to, "page": $page, "per_page": $per_page, "query": $query, "safe": $safe, "sort": $qp_sort, "view": $view, "language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details about sound effects
#
# GET /v2/sfx/{id}
# operationId: getSfxDetails
export def "sfx get-details" [
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
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal, e.g. full)
  --library: string@library-completer-1 # Which library to fetch from (e.g. shutterstock)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<added_date: string, affiliate_url: string, artist: string, assets: record<preview_mp3: record<file_size: int, url: string>, waveform: record<file_size: int, url: string>>, contributor: record<id: string>, description: string, duration: float, id: string, keywords: list<string>, media_type: string, releases: list<string>, title: string, updated_time: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "library" $library "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/sfx/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language, "view": $view, "library": $library, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Echo text
#
# GET /v2/test
# operationId: echo
export def "test get-echo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Text to echo (default: ok)
]: nothing -> record<text: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/test" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"text": $text} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Validate input
#
# GET /v2/test/validate
# operationId: validate
export def "test-validate validate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: int # Integer ID (e.g. 123)
  --tag: list<string> # List of tags
  --user-agent: string # User agent
]: nothing -> record<header: record<user_agent: string>, query: record<id: int, tag: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "tag" $tag "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/test/validate" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"user-agent": $user_agent} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "tag": $tag} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get user details
#
# GET /v2/user
# operationId: getUser
export def "user get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<contributor_id: string, customer_id: string, email: string, first_name: string, full_name: string, id: string, is_premier: bool, is_premier_parent: bool, language: string, last_name: string, only_enhanced_license: bool, only_sensitive_use: bool, organization_id: string, premier_permissions: list<string>, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user" $auth.query)
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

# Get access token details
#
# GET /v2/user/access_token
# operationId: getAccessToken
export def "user-access-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client_id: string, contributor_id: string, customer_id: string, expires_in: int, organization_id: string, realm: string, scopes: list<string>, user_id: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/access_token" $auth.query)
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

# List user subscriptions
#
# GET /v2/user/subscriptions
# operationId: getUserSubscriptionList
export def "user-subscriptions get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<allotment: record, asset_type: string, description: string, expiration_time: string, formats: list, id: string, license: string, metadata: record, price_per_download: record>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/subscriptions" $auth.query)
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

# List videos
#
# GET /v2/videos
# operationId: getVideoList
export def "videos get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: list<string> # One or more video IDs (e.g. [639703, 993721])
  --view: string@view-completer # Amount of detail to render in the response (default: minimal)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, aspect: float, aspect_ratio: string, assets: record, categories: list, contributor: record, description: string, duration: float, has_model_release: bool, has_property_release: bool, id: string, is_adult: bool, is_editorial: bool, keywords: list, media_type: string, models: list, url: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "multi") (serialize-qp "view" $view "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"id": $id, "view": $view, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List video categories
#
# GET /v2/videos/categories
# operationId: listVideoCategories
export def "videos-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
]: nothing -> record<data: table<id: string, name: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos/categories" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List video collections
#
# GET /v2/videos/collections
# operationId: getVideoCollectionList
export def "videos-collections get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 100)
  --embed: list<string> # Which sharing information to include in the response, such as a URL to the collection (e.g. share_code)
]: nothing -> record<data: table<cover_item: record, created_time: string, id: string, items_updated_time: string, name: string, share_code: string, share_url: string, total_item_count: int, updated_time: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "embed" $embed "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos/collections" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Create video collections
#
# POST /v2/videos/collections
# operationId: createVideoCollection
export def "videos-collections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The name of the collection
]: any -> record<id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/videos/collections" $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# List featured video collections
#
# GET /v2/videos/collections/featured
# operationId: getFeaturedVideoCollectionList
export def "videos-collections-featured get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed: string@embed-completer # What information to include in the response, such as a URL to the collection (e.g. share_url)
]: nothing -> record<data: table<cover_item: record, created_time: string, hero_item: record, id: string, items_updated_time: string, name: string, share_url: string, total_item_count: int, updated_time: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos/collections/featured" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the details of featured video collections
#
# GET /v2/videos/collections/featured/{id}
# operationId: getFeaturedVideoCollection
export def "videos-collections-featured get" [
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
  --embed: string@embed-completer # What information to include in the response, such as a URL to the collection
]: nothing -> record<cover_item: record<url: string>, created_time: string, hero_item: record<url: string>, id: string, items_updated_time: string, name: string, share_url: string, total_item_count: int, updated_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/collections/featured/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get the contents of featured video collections
#
# GET /v2/videos/collections/featured/{id}/items
# operationId: getFeaturedVideoCollectionItems
export def "videos-collections-featured-items get" [
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
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 100)
]: nothing -> record<data: table<added_time: string, id: string, media_type: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/collections/featured/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete video collections
#
# DELETE /v2/videos/collections/{id}
# operationId: deleteVideoCollection
export def "videos-collections delete" [
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
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/collections/{id}") $auth.query)
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

# Get the details of video collections
#
# GET /v2/videos/collections/{id}
# operationId: getVideoCollection
export def "videos-collections get" [
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
  --embed: list<string> # Which sharing information to include in the response, such as a URL to the collection
  --share-code: string # Code to retrieve a shared collection
]: nothing -> record<cover_item: record<added_time: string, id: string, media_type: string>, created_time: string, id: string, items_updated_time: string, name: string, share_code: string, share_url: string, total_item_count: int, updated_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "embed" $embed "multi") (serialize-qp "share_code" $share_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/collections/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"embed": $embed, "share_code": $share_code} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Rename video collections
#
# POST /v2/videos/collections/{id}
# operationId: renameVideoCollection
export def "videos-collections rename" [
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
  name: string # The new name of the collection
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/collections/{id}") $auth.query)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# Remove videos from collections
#
# DELETE /v2/videos/collections/{id}/items
# operationId: deleteVideoCollectionItems
export def "videos-collections-items delete" [
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
  --item-id: list<string> # One or more video IDs to remove from the collection
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "item_id" $item_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/collections/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: ({"item_id": $item_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get the contents of video collections
#
# GET /v2/videos/collections/{id}/items
# operationId: getVideoCollectionItems
export def "videos-collections-items get" [
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
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 100)
  --share-code: string # Code to retrieve the contents of a shared collection
  --qp-sort: string@sort-completer # Sort order (default: oldest)
]: nothing -> record<data: table<added_time: string, id: string, media_type: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "share_code" $share_code "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/collections/{id}/items") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "per_page": $per_page, "share_code": $share_code, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add videos to collections
#
# POST /v2/videos/collections/{id}/items
# operationId: addVideoCollectionItems
# --items item shape: {added_time?: string, id: string, media_type?: string}
export def "videos-collections-items create" [
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
  items: list # List of items — item shape: {added_time?: string, id: string, media_type?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/collections/{id}/items") $auth.query)
  let req_body = {"items": $items} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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
  send-post $req $req_body $insecure $raw $allow_errors $full [204]
}

# List video licenses
#
# GET /v2/videos/licenses
# operationId: getVideoLicenseList
export def "videos-licenses get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --video-id: string # Show licenses for the specified video ID (e.g. 12345678)
  --license: string # Show videos that are available with the specified license, such as `standard` or `enhanced`; prepending a `-` sign excludes results from that license (e.g. standard)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --qp-sort: string@sort-completer # Sort by oldest or newest videos first (default: newest)
  --username: string # Filter licenses by username of licensee (e.g. aUniqueUsername)
  --start-date: string # Show licenses created on or after the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --end-date: string # Show licenses created before the specified date (format: date-time, e.g. 2021-03-29T13:25:13.521Z)
  --download-availability: string@download-availability-completer # Filter licenses by download availability (default: all)
  --team-history: oneof<nothing, bool> # Set to true to see license history for all members of your team. (default: false)
]: nothing -> record<data: table<audio: record, download_time: string, id: string, image: record, is_downloadable: bool, license: string, metadata: record, revshare: record, subscription_id: string, user: record, video: record>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "video_id" $video_id "scalar") (serialize-qp "license" $license "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "download_availability" $download_availability "scalar") (serialize-qp "team_history" $team_history "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos/licenses" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"video_id": $video_id, "license": $license, "page": $page, "per_page": $per_page, "sort": $qp_sort, "username": $username, "start_date": $start_date, "end_date": $end_date, "download_availability": $download_availability, "team_history": $team_history} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# License videos
#
# POST /v2/videos/licenses
# operationId: licenseVideos
# --videos item shape: {auth_cookie?: record, editorial_acknowledgement?: bool, metadata?: record, price?: float, search_id?: string, show_modal?: bool, size?: "web"|"sd"|"hd"|"4k", subscription_id?: string, video_id: string}
export def "videos-licenses create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --subscription-id: string # The subscription ID to use for licensing (e.g. s12345678)
  --size: string@size-completer-2 # The size of the video to license (default: web)
  --search-id: string # The Search ID that led to this licensing event
  videos: list # Videos to license — item shape: {auth_cookie?: record, editorial_acknowledgement?: bool, metadata?: record, price?: float, search_id?: string, show_modal?: bool, size?: "web"|"sd"|"hd"|"4k", subscription_id?: string, video_id: string}
]: any -> record<data: table<allotment_charge: int, download: record, error: string, license_id: string, price: record, video_id: string>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "subscription_id" $subscription_id "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos/licenses" $qp $auth.query)
  let req_body = {"videos": $videos} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"subscription_id": $subscription_id, "size": $size, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
}

# Download videos
#
# POST /v2/videos/licenses/{id}/downloads
# operationId: downloadVideos
# --auth_cookie shape: {name: string, value: string}
@deprecated --flag show-modal
@deprecated --flag verification-code
export def "videos-licenses-downloads download" [
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
  --auth-cookie: record # Cookie object (e.g. {name: The name of the cookie, value: The value of the cookie}) — shape: {name: string, value: string}
  --show-modal: oneof<nothing, bool> # (Deprecated) (DEPRECATED)
  --size: string@size-completer-2 # Size of the video
  --verification-code: string # (Deprecated) (DEPRECATED)
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/licenses/{id}/downloads") $auth.query)
  let req_body = {"auth_cookie": $auth_cookie, "show_modal": $show_modal, "size": $size, "verification_code": $verification_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
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

# Search for videos
#
# GET /v2/videos/search
# operationId: searchVideos
@deprecated --flag duration
@deprecated --flag fps
export def "videos-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --added-date: string # Show videos added on the specified date (format: date, e.g. 2020-05-29)
  --added-date-start: string # Show videos added on or after the specified date (format: date, e.g. 2020-05-29)
  --added-date-end: string # Show videos added before the specified date (format: date, e.g. 2020-05-29)
  --aspect-ratio: string@aspect-ratio-completer # Show videos with the specified aspect ratio (e.g. 4_3)
  --category: string # Show videos with the specified Shutterstock-defined category; specify a category name or ID
  --contributor: list<string> # Show videos with the specified artist names or IDs (e.g. [12345678])
  --contributor-country: list<string> # Show videos from contributors in one or more specified countries (e.g. US)
  --duration: int # (Deprecated; use duration_from and duration_to instead) Show videos with the specified duration in seconds (DEPRECATED)
  --duration-from: int # Show videos with the specified duration or longer in seconds (e.g. 60)
  --duration-to: int # Show videos with the specified duration or shorter in seconds (e.g. 180)
  --fps: float # (Deprecated; use fps_from and fps_to instead) Show videos with the specified frames per second (DEPRECATED)
  --fps-from: float # Show videos with the specified frames per second or more (e.g. 24)
  --fps-to: float # Show videos with the specified frames per second or fewer (e.g. 60)
  --keyword-safe-search: oneof<nothing, bool> # Hide results with potentially unsafe keywords (default: true)
  --language: string@language-completer # Set query and result language (uses Accept-Language header if not set) (e.g. cs)
  --license: list<string> # Show only videos with the specified license or licenses (e.g. [commercial, editorial])
  --model: list<string> # Show videos with each of the specified models (e.g. [442583, 434750])
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --people-age: string@people-age-completer # Show videos that feature people of the specified age range (e.g. 20s)
  --people-ethnicity: list<string> # Show videos with people of the specified ethnicities (e.g. hispanic)
  --people-gender: string@people-gender-completer # Show videos with people with the specified gender (e.g. female)
  --people-number: int # Show videos with the specified number of people (e.g. 2)
  --people-model-released: oneof<nothing, bool> # Show only videos of people with a signed model release (e.g. true)
  --query: string # One or more search terms separated by spaces; you can use NOT to filter out videos that match a term (e.g. dogs running on the beach)
  --resolution: string@resolution-completer # Show videos with the specified resolution (e.g. 4k)
  --safe: oneof<nothing, bool> # Enable or disable safe search (default: true)
  --qp-sort: string@sort-completer-2 # Sort by one of these categories (default: popular)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, aspect: float, aspect_ratio: string, assets: record, categories: list, contributor: record, description: string, duration: float, has_model_release: bool, has_property_release: bool, id: string, is_adult: bool, is_editorial: bool, keywords: list, media_type: string, models: list, url: string>, message: string, page: int, per_page: int, search_id: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "added_date" $added_date "scalar") (serialize-qp "added_date_start" $added_date_start "scalar") (serialize-qp "added_date_end" $added_date_end "scalar") (serialize-qp "aspect_ratio" $aspect_ratio "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "contributor" $contributor "multi") (serialize-qp "contributor_country" $contributor_country "multi") (serialize-qp "duration" $duration "scalar") (serialize-qp "duration_from" $duration_from "scalar") (serialize-qp "duration_to" $duration_to "scalar") (serialize-qp "fps" $fps "scalar") (serialize-qp "fps_from" $fps_from "scalar") (serialize-qp "fps_to" $fps_to "scalar") (serialize-qp "keyword_safe_search" $keyword_safe_search "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "license" $license "multi") (serialize-qp "model" $model "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "people_age" $people_age "scalar") (serialize-qp "people_ethnicity" $people_ethnicity "multi") (serialize-qp "people_gender" $people_gender "scalar") (serialize-qp "people_number" $people_number "scalar") (serialize-qp "people_model_released" $people_model_released "scalar") (serialize-qp "query" $query "scalar") (serialize-qp "resolution" $resolution "scalar") (serialize-qp "safe" $safe "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos/search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"added_date": $added_date, "added_date_start": $added_date_start, "added_date_end": $added_date_end, "aspect_ratio": $aspect_ratio, "category": $category, "contributor": $contributor, "contributor_country": $contributor_country, "duration": $duration, "duration_from": $duration_from, "duration_to": $duration_to, "fps": $fps, "fps_from": $fps_from, "fps_to": $fps_to, "keyword_safe_search": $keyword_safe_search, "language": $language, "license": $license, "model": $model, "page": $page, "per_page": $per_page, "people_age": $people_age, "people_ethnicity": $people_ethnicity, "people_gender": $people_gender, "people_number": $people_number, "people_model_released": $people_model_released, "query": $query, "resolution": $resolution, "safe": $safe, "sort": $qp_sort, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get suggestions for a search term
#
# GET /v2/videos/search/suggestions
# operationId: getVideoSuggestions
export def "videos-search-suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search term for which you want keyword suggestions (e.g. cats)
  --limit: int # Limit the number of the suggestions (default: 10)
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos/search/suggestions" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"query": $query, "limit": $limit} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List updated videos
#
# GET /v2/videos/updated
# operationId: getUpdatedVideos
export def "videos-updated get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Show videos updated on or after the specified date (format: date, e.g. 2020-05-29)
  --end-date: string # Show videos updated before the specified date (format: date, e.g. 2021-05-29)
  --interval: string # Show videos updated in the specified time period, where the time period is an interval (like SQL INTERVAL) such as 1 DAY, 6 HOUR, or 30 MINUTE; the default is 1 HOUR, which shows videos that were updated in the hour preceding the request (default: 1 HOUR)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 100)
  --qp-sort: string@sort-completer # Sort by oldest or newest videos first (default: newest)
]: nothing -> record<data: table<id: string, updated_time: string, updates: list>, errors: table<code: string, data: string, items: list, message: string, path: string>, message: string, page: int, per_page: int, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/videos/updated" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start_date": $start_date, "end_date": $end_date, "interval": $interval, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get details about videos
#
# GET /v2/videos/{id}
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
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
  --view: string@view-completer # Amount of detail to render in the response (default: full)
  --search-id: string # The ID of the search that is related to this request (e.g. 00000000-0000-0000-0000-000000000000)
]: nothing -> record<added_date: string, affiliate_url: string, aspect: float, aspect_ratio: string, assets: record<4k: record<display_name: string, file_size: int, format: string, fps: float, height: int, is_licensable: bool, width: int>, hd: record<display_name: string, file_size: int, format: string, fps: float, height: int, is_licensable: bool, width: int>, preview_jpg: record<url: string>, preview_mp4: record<url: string>, preview_webm: record<url: string>, sd: record<display_name: string, file_size: int, format: string, fps: float, height: int, is_licensable: bool, width: int>, thumb_jpg: record<url: string>, thumb_jpgs: record<urls: list>, thumb_mp4: record<url: string>, thumb_webm: record<url: string>, web: record<display_name: string, file_size: int, format: string, fps: float, height: int, is_licensable: bool, width: int>>, categories: table<id: string, name: string>, contributor: record<id: string>, description: string, duration: float, has_model_release: bool, has_property_release: bool, id: string, is_adult: bool, is_editorial: bool, keywords: list<string>, media_type: string, models: table<id: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "view" $view "scalar") (serialize-qp "search_id" $search_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/{id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language, "view": $view, "search_id": $search_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# List similar videos
#
# GET /v2/videos/{id}/similar
# operationId: findSimilarVideos
export def "videos-similar find" [
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
  --language: string@language-completer # Language for the keywords and categories in the response (e.g. cs)
  --page: int # Page number (default: 1)
  --per-page: int # Number of results per page (default: 20)
  --view: string@view-completer # Amount of detail to render in the response (default: minimal)
]: nothing -> record<data: table<added_date: string, affiliate_url: string, aspect: float, aspect_ratio: string, assets: record, categories: list, contributor: record, description: string, duration: float, has_model_release: bool, has_property_release: bool, id: string, is_adult: bool, is_editorial: bool, keywords: list, media_type: string, models: list, url: string>, message: string, page: int, per_page: int, search_id: string, total_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "view" $view "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/videos/{id}/similar") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"language": $language, "page": $page, "per_page": $per_page, "view": $view} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
