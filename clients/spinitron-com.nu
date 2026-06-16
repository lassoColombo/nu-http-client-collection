# Auto-generated client for Spinitron v2 API v1.0.0
# Source: https://api.apis.guru/v2/specs/spinitron.com/1.0.0/openapi.json
# Auth: --token flag or $env.SPINITRON_V2_API_TOKEN

const BASE_URL = "https://spinitron.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SPINITRON_V2_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-access-token" => { {headers: {}, query: $"access-token=($token_val)"} }
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://spinitron.com/api"] }
def auth-scheme-completer [] { ["query-access-token" "bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --name: string # Filter by Persona name
  --count: int # Amount of items to return (default: 20)
  --page: int # Offset, used together with count
  --fields: list # Allows to select only needed fields
  --expand: list # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>>, _meta: record<currentPage: int, pageCount: int, perPage: int, totalCount: int>, items: table<_links: record, bio: string, email: string, id: int, image: string, name: string, since: int, website: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/personas" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: list # Allows to select only needed fields
  --expand: list # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>, shows: list<record>>, bio: string, email: string, id: int, image: string, name: string, since: int, website: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/personas/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: string # The datetime starting from items must be returned. Maximum 1 hour in future.  (format: date-time)
  --end: string # The ending datetime. Maximum 1 hour in future.  (format: date-time)
  --show-id: int # Filter by show
  --persona-id: int # Filter by persona
  --count: int # Amount of items to return (default: 20)
  --page: int # Offset, used together with count
  --fields: list # Allows to select only needed fields
  --expand: list # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>>, _meta: record<currentPage: int, pageCount: int, perPage: int, totalCount: int>, items: table<_links: record, automation: bool, category: string, description: string, duration: int, end: string, episode_description: string, episode_name: string, hide_dj: bool, id: int, image: string, persona_id: int, show_id: int, since: int, start: string, timezone: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "show_id" $show_id "scalar") (serialize-qp "persona_id" $persona_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/playlists" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: list # Allows to select only needed fields
  --expand: list # Allows to select extra fields
]: nothing -> record<_links: record<persona: record<href: string>, self: record<href: string>, show: record<href: string>, spins: record<href: string>>, automation: bool, category: string, description: string, duration: int, end: string, episode_description: string, episode_name: string, hide_dj: bool, id: int, image: string, persona_id: int, show_id: int, since: int, start: string, timezone: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: string # The datetime starting from items must be returned. Maximum 1 hour in past.  (format: date-time)
  --end: string # The ending datetime. Maximum 1 hour in past.  (format: date-time)
  --count: int # Amount of items to return (default: 20)
  --page: int # Offset, used together with count
  --fields: list # Allows to select only needed fields
  --expand: list # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>>, _meta: record<currentPage: int, pageCount: int, perPage: int, totalCount: int>, items: table<_links: record, category: string, description: string, duration: int, end: string, hide_dj: bool, id: int, image: string, one_off: bool, since: int, start: string, timezone: string, title: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/shows" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: list # Allows to select only needed fields
  --expand: list # Allows to select extra fields
]: nothing -> record<_links: record<personas: list<record>, playlists: record<href: string>, self: record<href: string>>, category: string, description: string, duration: int, end: string, hide_dj: bool, id: int, image: string, one_off: bool, since: int, start: string, timezone: string, title: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/shows/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --start: string # The datetime starting from items must be returned.  (format: date-time)
  --end: string # The ending datetime.  (format: date-time)
  --playlist-id: int # Filter by playlist
  --show-id: int # Filter by show
  --count: int # Amount of items to return (default: 20)
  --page: int # Offset, used together with count
  --fields: list # Allows to select only needed fields
  --expand: list # Allows to select extra fields
]: nothing -> record<_links: record<self: record<href: string>>, _meta: record<currentPage: int, pageCount: int, perPage: int, totalCount: int>, items: table<_links: record, artist: string, artist_custom: string, catalog_number: string, classical: bool, composer: string, conductor: string, duration: int, end: string, ensemble: string, genre: string, id: int, image: string, isrc: string, iswc: string, label: string, label_custom: string, local: bool, medium: string, new: bool, note: string, performers: string, playlist_id: int, release: string, release_custom: string, released: int, request: bool, song: string, start: string, timezone: string, upc: string, va: bool, work: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "playlist_id" $playlist_id "scalar") (serialize-qp "show_id" $show_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/spins" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Log a Spin
#
# POST /spins
export def "spins post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
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
  let full_url = (build-url $base "/spins")
  let body = {artist: $artist, composer: $composer, duration: $duration, genre: $genre, isrc: $isrc, label: $label, live: $live, release: $release, song: $song, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $body
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
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --fields: list # Allows to select only needed fields
  --expand: list # Allows to select extra fields
]: nothing -> record<_links: record<playlist: record<href: string>, self: record<href: string>>, artist: string, artist_custom: string, catalog_number: string, classical: bool, composer: string, conductor: string, duration: int, end: string, ensemble: string, genre: string, id: int, image: string, isrc: string, iswc: string, label: string, label_custom: string, local: bool, medium: string, new: bool, note: string, performers: string, playlist_id: int, release: string, release_custom: string, released: int, request: bool, song: string, start: string, timezone: string, upc: string, va: bool, work: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "multi") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/spins/($id)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
