# Auto-generated client for Spinitron v2 API v1.0.0
# Source: https://api.apis.guru/v2/specs/spinitron.com/1.0.0/openapi.json
# Auth: --token flag or $env.SPINITRON_V2_API_TOKEN

const BASE_URL = "https://spinitron.com/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o SPINITRON_V2_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-access-token" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "access-token")=(encode-path-segment $token_val)", location: "query"} }
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

def base-url-completer [] { ["https://spinitron.com/api"] }
def auth-scheme-completer [] { ["query-access-token" "bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "personas list" } } | get name | first)
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

# Get Personas
#
# GET /personas
export def "personas list" [
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
  --name: string # Filter by Persona name
  --count: int # Amount of items to return (default: 20)
  --page: int # Offset, used together with count
  --fields: list<string> # Allows to select only needed fields
  --expand: list<string> # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>>, _meta: record<currentPage: int, pageCount: int, perPage: int, totalCount: int>, items: table<_links: record, bio: string, email: string, id: int, image: string, name: string, since: int, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/personas" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"name": $name, "count": $count, "page": $page, "fields": $fields, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get Persona by id
#
# GET /personas/{id}
export def "personas get" [
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
  --accept: string@accept-completer # Response content type
  --fields: list<string> # Allows to select only needed fields
  --expand: list<string> # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>, shows: list<record>>, bio: string, email: string, id: int, image: string, name: string, since: int, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/personas/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fields": $fields, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns playlists optionally filtered by {start} and/or {end} datetimes
#
# GET /playlists
export def "playlists list" [
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
  --start: string # The datetime starting from items must be returned. Maximum 1 hour in future. (format: date-time)
  --end: string # The ending datetime. Maximum 1 hour in future. (format: date-time)
  --show-id: int # Filter by show
  --persona-id: int # Filter by persona
  --count: int # Amount of items to return (default: 20)
  --page: int # Offset, used together with count
  --fields: list<string> # Allows to select only needed fields
  --expand: list<string> # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>>, _meta: record<currentPage: int, pageCount: int, perPage: int, totalCount: int>, items: table<_links: record, automation: bool, category: string, description: string, duration: int, end: string, episode_description: string, episode_name: string, hide_dj: bool, id: int, image: string, persona_id: int, show_id: int, since: int, start: string, timezone: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "show_id" $show_id "scalar") (serialize-qp "persona_id" $persona_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/playlists" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "show_id": $show_id, "persona_id": $persona_id, "count": $count, "page": $page, "fields": $fields, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Playlist by id
#
# GET /playlists/{id}
export def "playlists get" [
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
  --accept: string@accept-completer # Response content type
  --fields: list<string> # Allows to select only needed fields
  --expand: list<string> # Allows to select extra fields
]: nothing -> record<_links: record<persona: record<href: string>, self: record<href: string>, show: record<href: string>, spins: record<href: string>>, automation: bool, category: string, description: string, duration: int, end: string, episode_description: string, episode_name: string, hide_dj: bool, id: int, image: string, persona_id: int, show_id: int, since: int, start: string, timezone: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/playlists/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fields": $fields, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns scheduled shows optionally filtered by {start} and/or {end} datetimes
#
# GET /shows
export def "shows list" [
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
  --start: string # The datetime starting from items must be returned. Maximum 1 hour in past. (format: date-time)
  --end: string # The ending datetime. Maximum 1 hour in past. (format: date-time)
  --count: int # Amount of items to return (default: 20)
  --page: int # Offset, used together with count
  --fields: list<string> # Allows to select only needed fields
  --expand: list<string> # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>>, _meta: record<currentPage: int, pageCount: int, perPage: int, totalCount: int>, items: table<_links: record, category: string, description: string, duration: int, end: string, hide_dj: bool, id: int, image: string, one_off: bool, since: int, start: string, timezone: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/shows" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "count": $count, "page": $page, "fields": $fields, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get a Show by id
#
# GET /shows/{id}
export def "shows get" [
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
  --accept: string@accept-completer # Response content type
  --fields: list<string> # Allows to select only needed fields
  --expand: list<string> # Allows to select extra fields
]: nothing -> record<_links: record<personas: list<record>, playlists: record<href: string>, self: record<href: string>>, category: string, description: string, duration: int, end: string, hide_dj: bool, id: int, image: string, one_off: bool, since: int, start: string, timezone: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/shows/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fields": $fields, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Returns spins optionally filtered by {start} and/or {end} datetimes
#
# GET /spins
export def "spins list" [
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
  --start: string # The datetime starting from items must be returned. (format: date-time)
  --end: string # The ending datetime. (format: date-time)
  --playlist-id: int # Filter by playlist
  --show-id: int # Filter by show
  --count: int # Amount of items to return (default: 20)
  --page: int # Offset, used together with count
  --fields: list<string> # Allows to select only needed fields
  --expand: list<string> # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>>, _meta: record<currentPage: int, pageCount: int, perPage: int, totalCount: int>, items: table<_links: record, artist: string, artist_custom: string, catalog_number: string, classical: bool, composer: string, conductor: string, duration: int, end: string, ensemble: string, genre: string, id: int, image: string, isrc: string, iswc: string, label: string, label_custom: string, local: bool, medium: string, new: bool, note: string, performers: string, playlist_id: int, release: string, release_custom: string, released: int, request: bool, song: string, start: string, timezone: string, upc: string, va: bool, work: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "playlist_id" $playlist_id "scalar") (serialize-qp "show_id" $show_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/spins" $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"start": $start, "end": $end, "playlist_id": $playlist_id, "show_id": $show_id, "count": $count, "page": $page, "fields": $fields, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Log a Spin
#
# POST /spins
export def "spins create" [
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
  artist: string
  --composer: string
  --duration: int
  --genre: string
  --isrc: string
  --label: string
  --live: oneof<nothing, bool> # Only when automation params are configured with the "Pass through" mode. Enables "live assist" mode. Default mode is "full automation".
  --release: string
  song: string
  --start: string # format: date-time
]: any -> record<_links: record<playlist: record<href: string>, self: record<href: string>>, artist: string, artist_custom: string, catalog_number: string, classical: bool, composer: string, conductor: string, duration: int, end: string, ensemble: string, genre: string, id: int, image: string, isrc: string, iswc: string, label: string, label_custom: string, local: bool, medium: string, new: bool, note: string, performers: string, playlist_id: int, release: string, release_custom: string, released: int, request: bool, song: string, start: string, timezone: string, upc: string, va: bool, work: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/spins" $auth.query)
  let req_body = {"artist": $artist, "composer": $composer, "duration": $duration, "genre": $genre, "isrc": $isrc, "label": $label, "live": $live, "release": $release, "song": $song, "start": $start} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
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

# Get a Spin by id
#
# GET /spins/{id}
export def "spins get" [
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
  --accept: string@accept-completer # Response content type
  --fields: list<string> # Allows to select only needed fields
  --expand: list<string> # Allows to select extra fields
]: nothing -> record<_links: record<playlist: record<href: string>, self: record<href: string>>, artist: string, artist_custom: string, catalog_number: string, classical: bool, composer: string, conductor: string, duration: int, end: string, ensemble: string, genre: string, id: int, image: string, isrc: string, iswc: string, label: string, label_custom: string, local: bool, medium: string, new: bool, note: string, performers: string, playlist_id: int, release: string, release_custom: string, released: int, request: bool, song: string, start: string, timezone: string, upc: string, va: bool, work: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/spins/{id}") $qp $auth.query)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"fields": $fields, "expand": $expand} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
