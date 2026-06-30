# Auto-generated client for Musixmatch API v1.1.0
# Source: https://api.apis.guru/v2/specs/musixmatch.com/1.1.0/swagger.json
# Auth: --token flag or $env.MUSIXMATCH_API_TOKEN

const BASE_URL = "https://api.musixmatch.com/ws/1.1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o MUSIXMATCH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-apikey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "apikey")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://api.musixmatch.com/ws/1.1"] }
def auth-scheme-completer [] { ["query-apikey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "album-get get" } } | get name | first)
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

# GET /album.get
export def "album-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --album-id: string # The musiXmatch album id
]: nothing -> record<message: record<body: record<album: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "album_id" $album_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/album.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "album_id": $album_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /album.tracks.get
export def "album-tracks-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --album-id: string # The musiXmatch album id
  --f-has-lyrics: string # When set, filter only contents with lyrics
  --page: float # Define the page number for paginated results
  --page-size: float # Define the page size for paginated results.Range is 1 to 100.
]: nothing -> record<message: record<body: record<track_list: list>, header: record<available: float, execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "album_id" $album_id "scalar") (serialize-qp "f_has_lyrics" $f_has_lyrics "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/album.tracks.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "album_id": $album_id, "f_has_lyrics": $f_has_lyrics, "page": $page, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /artist.albums.get
export def "artist-albums-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --artist-id: string # The musiXmatch artist id
  --s-release-date: string # Sort by release date (asc|desc)
  --g-album-name: string # Group by Album Name
  --page-size: float # Define the page size for paginated results.Range is 1 to 100.
  --page: float # Define the page number for paginated results
]: nothing -> record<message: record<body: record<album_list: list>, header: record<available: float, execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "artist_id" $artist_id "scalar") (serialize-qp "s_release_date" $s_release_date "scalar") (serialize-qp "g_album_name" $g_album_name "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/artist.albums.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "artist_id": $artist_id, "s_release_date": $s_release_date, "g_album_name": $g_album_name, "page_size": $page_size, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /artist.get
export def "artist-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --artist-id: string # The musiXmatch artist id
]: nothing -> record<message: record<body: record<artist: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "artist_id" $artist_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/artist.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "artist_id": $artist_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /artist.related.get
export def "artist-related-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --artist-id: string # The musiXmatch artist id
  --page-size: float # Define the page size for paginated results.Range is 1 to 100.
  --page: float # Define the page number for paginated results
]: nothing -> record<message: record<body: record<artist_list: list>, header: record<available: float, execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "artist_id" $artist_id "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/artist.related.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "artist_id": $artist_id, "page_size": $page_size, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /artist.search
export def "artist-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --q-artist: string # The song artist
  --f-artist-id: float # When set, filter by this artist id
  --page: float # Define the page number for paginated results
  --page-size: float # Define the page size for paginated results.Range is 1 to 100.
]: nothing -> record<message: record<body: record<artist_list: list>, header: record<available: float, execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "q_artist" $q_artist "scalar") (serialize-qp "f_artist_id" $f_artist_id "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/artist.search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "q_artist": $q_artist, "f_artist_id": $f_artist_id, "page": $page, "page_size": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /chart.artists.get
export def "chart-artists-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --page: float # Define the page number for paginated results
  --page-size: float # Define the page size for paginated results.Range is 1 to 100.
  --country: string # A valid ISO 3166 country code (default: us)
]: nothing -> record<message: record<body: record<artist_list: list>, header: record<available: float, execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "country" $country "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart.artists.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "page": $page, "page_size": $page_size, "country": $country} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /chart.tracks.get
export def "chart-tracks-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --page: float # Define the page number for paginated results
  --page-size: float # Define the page size for paginated results.Range is 1 to 100.
  --country: string # A valid ISO 3166 country code (default: us)
  --f-has-lyrics: string # When set, filter only contents with lyrics
]: nothing -> record<message: record<body: record<track_list: list>, header: record<available: float, execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "country" $country "scalar") (serialize-qp "f_has_lyrics" $f_has_lyrics "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chart.tracks.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "page": $page, "page_size": $page_size, "country": $country, "f_has_lyrics": $f_has_lyrics} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /matcher.lyrics.get
export def "matcher-lyrics-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --q-track: string # The song title
  --q-artist: string # The song artist
]: nothing -> record<message: record<body: record<lyrics: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "q_track" $q_track "scalar") (serialize-qp "q_artist" $q_artist "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matcher.lyrics.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "q_track": $q_track, "q_artist": $q_artist} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /matcher.subtitle.get
export def "matcher-subtitle-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --q-track: string # The song title
  --q-artist: string # The song artist
  --f-subtitle-length: float # Filter by subtitle length in seconds
  --f-subtitle-length-max-deviation: float # Max deviation for a subtitle length in seconds
]: nothing -> record<message: record<body: record<subtitle: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "q_track" $q_track "scalar") (serialize-qp "q_artist" $q_artist "scalar") (serialize-qp "f_subtitle_length" $f_subtitle_length "scalar") (serialize-qp "f_subtitle_length_max_deviation" $f_subtitle_length_max_deviation "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matcher.subtitle.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "q_track": $q_track, "q_artist": $q_artist, "f_subtitle_length": $f_subtitle_length, "f_subtitle_length_max_deviation": $f_subtitle_length_max_deviation} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /matcher.track.get
export def "matcher-track-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --q-artist: string # The song artist
  --q-track: string # The song title
  --f-has-lyrics: float # When set, filter only contents with lyrics
  --f-has-subtitle: float # When set, filter only contents with subtitles
]: nothing -> record<message: record<body: record<track: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "q_artist" $q_artist "scalar") (serialize-qp "q_track" $q_track "scalar") (serialize-qp "f_has_lyrics" $f_has_lyrics "scalar") (serialize-qp "f_has_subtitle" $f_has_subtitle "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/matcher.track.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "q_artist": $q_artist, "q_track": $q_track, "f_has_lyrics": $f_has_lyrics, "f_has_subtitle": $f_has_subtitle} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /track.get
export def "track-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --track-id: string # The musiXmatch track id
]: nothing -> record<message: record<body: record<track: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "track_id" $track_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/track.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "track_id": $track_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /track.lyrics.get
export def "track-lyrics-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --track-id: string # The musiXmatch track id
]: nothing -> record<message: record<body: record<lyrics: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "track_id" $track_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/track.lyrics.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "track_id": $track_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /track.search
export def "track-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --q-track: string # The song title
  --q-artist: string # The song artist
  --q-lyrics: string # Any word in the lyrics
  --f-artist-id: float # When set, filter by this artist id
  --f-music-genre-id: float # When set, filter by this music category id
  --f-lyrics-language: float # Filter by the lyrics language (en,it,..)
  --f-has-lyrics: float # When set, filter only contents with lyrics
  --s-artist-rating: string # Sort by our popularity index for artists (asc|desc)
  --s-track-rating: string # Sort by our popularity index for tracks (asc|desc)
  --quorum-factor: float # Search only a part of the given query string.Allowed range is (0.1 – 0.9) (default: 1)
  --page-size: float # Define the page size for paginated results.Range is 1 to 100.
  --page: float # Define the page number for paginated results
]: nothing -> record<message: record<body: record<track_list: list>, header: record<available: float, execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "q_track" $q_track "scalar") (serialize-qp "q_artist" $q_artist "scalar") (serialize-qp "q_lyrics" $q_lyrics "scalar") (serialize-qp "f_artist_id" $f_artist_id "scalar") (serialize-qp "f_music_genre_id" $f_music_genre_id "scalar") (serialize-qp "f_lyrics_language" $f_lyrics_language "scalar") (serialize-qp "f_has_lyrics" $f_has_lyrics "scalar") (serialize-qp "s_artist_rating" $s_artist_rating "scalar") (serialize-qp "s_track_rating" $s_track_rating "scalar") (serialize-qp "quorum_factor" $quorum_factor "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/track.search" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "q_track": $q_track, "q_artist": $q_artist, "q_lyrics": $q_lyrics, "f_artist_id": $f_artist_id, "f_music_genre_id": $f_music_genre_id, "f_lyrics_language": $f_lyrics_language, "f_has_lyrics": $f_has_lyrics, "s_artist_rating": $s_artist_rating, "s_track_rating": $s_track_rating, "quorum_factor": $quorum_factor, "page_size": $page_size, "page": $page} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /track.snippet.get
export def "track-snippet-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --track-id: string # The musiXmatch track id
]: nothing -> record<message: record<body: record<snippet: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "track_id" $track_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/track.snippet.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "track_id": $track_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# GET /track.subtitle.get
export def "track-subtitle-get get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string # output format: json, jsonp, xml. (default: json)
  --callback: string # jsonp callback
  --track-id: string # The musiXmatch track id
]: nothing -> record<message: record<body: record<subtitle: record>, header: record<execute_time: float, status_code: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-apikey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "track_id" $track_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/track.subtitle.get" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"format": $format, "callback": $callback, "track_id": $track_id} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
