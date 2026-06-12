# Auto-generated client for graphql.animethemes v0.0.0
# Source: https://graphql.animethemes.moe
# Auth: --token flag or $env.GRAPHQL_ANIMETHEMES_TOKEN

const BASE_URL = "https://graphql.animethemes.moe"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GRAPHQL_ANIMETHEMES_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

# Unwrap a GraphQL response: extract data.{field} and surface errors
def unwrap-graphql [resp: any, field: string] {
  if ($resp | describe) == "string" { return $resp }
  let errors = ($resp.errors? | default [])
  if ($errors | length) > 0 {
    let msgs = ($errors | each {|e| $e.message? | default "unknown error" } | str join "; ")
    error make --unspanned { msg: $"GraphQL error: ($msgs)" }
  }
  $resp.data? | get -o $field | default $resp.data?
}

def base-url-completer [] { ["https://graphql.animethemes.moe"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def site-completer [] { ["AMAZON_MUSIC" "AMAZON_PRIME_VIDEO" "ANIDB" "ANILIST" "ANIME_PLANET" "ANN" "APPLE_MUSIC" "CRUNCHYROLL" "DISNEY_PLUS" "HIDIVE" "HULU" "KITSU" "LIVECHART" "MAL" "NETFLIX" "OFFICIAL_SITE" "SPOTIFY" "WIKI" "X" "YOUTUBE" "YOUTUBE_MUSIC"] }
def type-completer [] { ["ED" "IN" "OP"] }
def format-completer [] { ["MOVIE" "ONA" "OVA" "SPECIAL" "TV" "TV_SHORT"] }
def sort-completer [] { ["CREATED_AT" "CREATED_AT_DESC" "ID" "ID_DESC" "RANDOM" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer [] { ["CREATED_AT" "ID" "PATH" "UPDATED_AT"] }
def where-operator-completer [] { ["BETWEEN" "EQ" "GT" "GTE" "IN" "IS_NOT_NULL" "IS_NULL" "LIKE" "LT" "LTE" "NEQ" "NOT_BETWEEN" "NOT_IN" "NOT_LIKE"] }
def sort-completer-1 [] { ["CREATED_AT" "CREATED_AT_DESC" "ID" "ID_DESC" "NAME" "NAME_DESC" "RANDOM" "SLUG" "SLUG_DESC" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer-1 [] { ["BODY" "CREATED_AT" "ID" "NAME" "SLUG" "UPDATED_AT"] }
def where-column-completer-2 [] { ["CREATED_AT" "ID" "NAME" "SITE" "UPDATED_AT" "VISIBILITY"] }
def visibility-completer [] { ["PRIVATE" "PUBLIC" "UNLISTED"] }
def sort-completer-2 [] { ["CREATED_AT" "CREATED_AT_DESC" "ID" "ID_DESC" "LIKES_COUNT" "LIKES_COUNT_DESC" "NAME" "NAME_DESC" "RANDOM" "TRACKS_COUNT" "TRACKS_COUNT_DESC" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer-3 [] { ["CREATED_AT" "DESCRIPTION" "ID" "NAME" "UPDATED_AT" "VISIBILITY"] }
def sort-completer-3 [] { ["CREATED_AT" "CREATED_AT_DESC" "ID" "ID_DESC" "POSITION" "POSITION_DESC" "RANDOM" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer-4 [] { ["CREATED_AT" "ENTRY_ID" "ID" "POSITION" "UPDATED_AT" "VIDEO_ID"] }
def format-in-completer [] { ["MOVIE" "ONA" "OVA" "SPECIAL" "TV" "TV_SHORT"] }
def season-completer [] { ["FALL" "SPRING" "SUMMER" "WINTER"] }
def season-in-completer [] { ["FALL" "SPRING" "SUMMER" "WINTER"] }
def sort-completer-4 [] { ["CREATED_AT" "CREATED_AT_DESC" "ID" "ID_DESC" "NAME" "NAME_DESC" "RANDOM" "UPDATED_AT" "UPDATED_AT_DESC" "YEAR" "YEAR_DESC"] }
def where-column-completer-5 [] { ["CREATED_AT" "FORMAT" "ID" "NAME" "SEASON" "SYNOPSIS" "UPDATED_AT" "YEAR"] }
def sort-completer-5 [] { ["CREATED_AT" "CREATED_AT_DESC" "ID" "ID_DESC" "NAME" "NAME_DESC" "RANDOM" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer-6 [] { ["CREATED_AT" "ID" "INFORMATION" "NAME" "SLUG" "UPDATED_AT"] }
def sort-completer-6 [] { ["BASENAME" "BASENAME_DESC" "CREATED_AT" "CREATED_AT_DESC" "FILENAME" "FILENAME_DESC" "ID" "ID_DESC" "RANDOM" "SIZE" "SIZE_DESC" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer-7 [] { ["BASENAME" "CREATED_AT" "FILENAME" "ID" "MIMETYPE" "PATH" "SIZE" "UPDATED_AT"] }
def facet-completer [] { ["AVATAR" "BANNER" "DOCUMENT" "GRILL" "LARGE_COVER" "SMALL_COVER"] }
def where-column-completer-8 [] { ["CREATED_AT" "FACET" "ID" "PATH" "UPDATED_AT"] }
def where-column-completer-9 [] { ["CREATED_AT" "ID" "NAME" "SLUG" "UPDATED_AT"] }
def sort-completer-7 [] { ["CREATED_AT" "CREATED_AT_DESC" "ID" "ID_DESC" "RANDOM" "TITLE" "TITLE_DESC" "TITLE_NATIVE" "TITLE_NATIVE_DESC" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer-10 [] { ["CREATED_AT" "ID" "TITLE" "TITLE_NATIVE" "UPDATED_AT"] }
def overlap-completer [] { ["NONE" "OVER" "TRANS"] }
def source-completer [] { ["BD" "DVD" "LD" "RAW" "VHS" "WEB"] }
def sort-completer-8 [] { ["BASENAME" "BASENAME_DESC" "CREATED_AT" "CREATED_AT_DESC" "FILENAME" "FILENAME_DESC" "ID" "ID_DESC" "RANDOM" "RESOLUTION" "RESOLUTION_DESC" "SIZE" "SIZE_DESC" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer-11 [] { ["BASENAME" "CREATED_AT" "FILENAME" "ID" "LYRICS" "MIMETYPE" "NC" "OVERLAP" "PATH" "RESOLUTION" "SIZE" "SOURCE" "SUBBED" "UNCEN" "UPDATED_AT"] }
def type-in-completer [] { ["ED" "IN" "OP"] }
def sort-completer-9 [] { ["CREATED_AT" "CREATED_AT_DESC" "ID" "ID_DESC" "RANDOM" "SEQUENCE" "SEQUENCE_DESC" "SONG_TITLE" "SONG_TITLE_DESC" "SONG_TITLE_NATIVE" "SONG_TITLE_NATIVE_DESC" "UPDATED_AT" "UPDATED_AT_DESC"] }
def where-column-completer-12 [] { ["CREATED_AT" "ID" "SEQUENCE" "SLUG" "TYPE" "UPDATED_AT"] }
def sort-completer-10 [] { ["CREATED_AT" "CREATED_AT_DESC" "EPISODES" "EPISODES_DESC" "ID" "ID_DESC" "LIKES_COUNT" "LIKES_COUNT_DESC" "RANDOM" "TRACKS_COUNT" "TRACKS_COUNT_DESC" "UPDATED_AT" "UPDATED_AT_DESC" "VERSION" "VERSION_DESC"] }
def where-column-completer-13 [] { ["CREATED_AT" "EPISODES" "ID" "NOTES" "NSFW" "SPOILER" "UPDATED_AT" "VERSION"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "query search" } } | get name | first)
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

# Returns a listing of resources that match a given search term.
#
# operationId: search
export def "query search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  search: string
  --first: int
  --page: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"search": $search, "first": $first, "page": $page} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($search: String!, $first: Int, $page: Int) { search(search: $search, first: $first, page: $page) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "search" }
}

# Returns the first featured theme where the current date is between start_at and end_at dates.
#
# operationId: currentfeaturedtheme
export def "query currentfeaturedtheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id startAt endAt createdAt updatedAt" }
    let body = {query: ("query { currentfeaturedtheme { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "currentfeaturedtheme" }
}

# Returns the data of the currently authenticated user.
#
# operationId: me
export def "query me" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name email emailVerifiedAt twoFactorConfirmedAt createdAt updatedAt" }
    let body = {query: ("query { me { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "me" }
}

# Returns a page resource.
#
# operationId: page
export def "query page" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  slug: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"slug": $slug} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name slug body createdAt updatedAt" }
    let body = {query: ("query($slug: String!) { page(slug: $slug) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "page" }
}

# Returns a playlist resource.
#
# operationId: playlist
export def "query playlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name description visibility visibilityLocalized tracksCount tracksExists likesCount createdAt updatedAt" }
    let body = {query: ("query($id: String!) { playlist(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "playlist" }
}

# Returns a playlist track resource.
#
# operationId: playlisttrack
export def "query playlisttrack" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  playlist: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "playlist": $playlist} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id position createdAt updatedAt" }
    let body = {query: ("query($id: String!, $playlist: String!) { playlisttrack(id: $id, playlist: $playlist) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "playlisttrack" }
}

# Returns an anime resource.
#
# operationId: anime
export def "query anime" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  slug: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"slug": $slug} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name format formatLocalized season seasonLocalized slug synopsis year createdAt updatedAt" }
    let body = {query: ("query($slug: String!) { anime(slug: $slug) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "anime" }
}

# Filter anime by its external id on given site.
#
# operationId: findAnimeByExternalSite
export def "query find-anime-by-external-site" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  site: string@site-completer
  --id: int
  --link: string
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"site": $site, "id": $id, "link": $link} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name format formatLocalized season seasonLocalized slug synopsis year createdAt updatedAt" }
    let body = {query: ("query($site: ResourceSite!, $id: [Int!], $link: String) { findAnimeByExternalSite(site: $site, id: $id, link: $link) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "findAnimeByExternalSite" }
}

# Returns a list of years grouped by its seasons.
#
# operationId: animeyears
export def "query animeyears" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --year: int
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"year": $year} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "year" }
    let body = {query: ("query($year: [Int!]) { animeyears(year: $year) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "animeyears" }
}

# Returns an artist resource.
#
# operationId: artist
export def "query artist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  slug: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"slug": $slug} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name slug information createdAt updatedAt" }
    let body = {query: ("query($slug: String!) { artist(slug: $slug) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "artist" }
}

# Returns a series resource.
#
# operationId: series
export def "query series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  slug: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"slug": $slug} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name slug createdAt updatedAt" }
    let body = {query: ("query($slug: String!) { series(slug: $slug) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "series" }
}

# Returns a studio resource.
#
# operationId: studio
export def "query studio" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  slug: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"slug": $slug} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name slug createdAt updatedAt" }
    let body = {query: ("query($slug: String!) { studio(slug: $slug) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "studio" }
}

# Returns a video resource.
#
# operationId: video
export def "query video" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id basename filename lyrics mimetype nc overlap overlapLocalized path priority resolution size source sourceLocalized subbed uncen tags link createdAt updatedAt" }
    let body = {query: ("query($id: Int!) { video(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "video" }
}

# Shuffle themes.
#
# operationId: animethemeShuffle
export def "query animetheme-shuffle" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --type: string@type-completer
  --format: string@format-completer
  --year-lte: int
  --year-gte: int
  --spoiler: oneof<nothing, bool>
  --first: int
  --page: int
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"type": $type, "format": $format, "year_lte": $year_lte, "year_gte": $year_gte, "spoiler": $spoiler, "first": $first, "page": $page} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id type typeLocalized sequence slug createdAt updatedAt" }
    let body = {query: ("query($type: [ThemeType!], $format: [AnimeFormat!], $year_lte: Int, $year_gte: Int, $spoiler: Boolean, $first: Int, $page: Int) { animethemeShuffle(type: $type, format: $format, year_lte: $year_lte, year_gte: $year_gte, spoiler: $spoiler, first: $first, page: $page) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "animethemeShuffle" }
}

# Returns a listing of announcement resources given fields.
#
# operationId: announcementPagination
export def "query announcement-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --qp-sort: string@sort-completer
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"sort": $qp_sort, "first": $first, "page": $page} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($sort: [AnnouncementSort!], $first: Int!, $page: Int) { announcementPagination(sort: $sort, first: $first, page: $page) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "announcementPagination" }
}

# Returns a listing of dump resources given fields.
#
# operationId: dumpPagination
# --where-AND item shape: {column?: "ID"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query dump-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --qp-sort: string@sort-completer
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($where: QueryDumpPaginationWhereWhereConditions, $sort: [DumpSort!], $first: Int!, $page: Int) { dumpPagination(sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "dumpPagination" }
}

# Returns a listing of page resources given fields.
#
# operationId: pagePagination
# --where-AND item shape: {column?: "ID"|"NAME"|"SLUG"|"BODY"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"NAME"|"SLUG"|"BODY"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query page-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --name: string
  --name-like: string
  --path-like: string
  --qp-sort: string@sort-completer-1
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-1 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"BODY"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"BODY"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "name": $name, "name_like": $name_like, "path_like": $path_like, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $name: String, $name_like: String, $path_like: String, $where: QueryPagePaginationWhereWhereConditions, $sort: [PageSort!], $first: Int!, $page: Int) { pagePagination(id: $id, name: $name, name_like: $name_like, path_like: $path_like, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "pagePagination" }
}

# Returns a listing of external profile resources given fields.
#
# operationId: externalprofilePagination
# --where-AND item shape: {column?: "ID"|"NAME"|"SITE"|"VISIBILITY"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"NAME"|"SITE"|"VISIBILITY"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query externalprofile-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-2 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"NAME"|"SITE"|"VISIBILITY"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"NAME"|"SITE"|"VISIBILITY"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($where: QueryExternalprofilePaginationWhereWhereConditions, $first: Int!, $page: Int) { externalprofilePagination(first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "externalprofilePagination" }
}

# Returns a listing of playlist resources given fields.
#
# operationId: playlistPagination
# --where-AND item shape: {column?: "ID"|"NAME"|"VISIBILITY"|"DESCRIPTION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"NAME"|"VISIBILITY"|"DESCRIPTION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query playlist-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --name: string
  --name-like: string
  --search: string
  --visibility: string@visibility-completer
  --qp-sort: string@sort-completer-2
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-3 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"NAME"|"VISIBILITY"|"DESCRIPTION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"NAME"|"VISIBILITY"|"DESCRIPTION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"name": $name, "name_like": $name_like, "search": $search, "visibility": $visibility, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($name: String, $name_like: String, $search: String, $visibility: PlaylistVisibility, $where: QueryPlaylistPaginationWhereWhereConditions, $sort: [PlaylistSort!], $first: Int!, $page: Int) { playlistPagination(name: $name, name_like: $name_like, search: $search, visibility: $visibility, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "playlistPagination" }
}

# Returns a listing of playlist track resources given fields.
#
# operationId: playlisttrackPagination
# --where-AND item shape: {column?: "ID"|"POSITION"|"ENTRY_ID"|"VIDEO_ID"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"POSITION"|"ENTRY_ID"|"VIDEO_ID"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query playlisttrack-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  playlist: string
  --position: int
  --qp-sort: string@sort-completer-3
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-4 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"POSITION"|"ENTRY_ID"|"VIDEO_ID"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"POSITION"|"ENTRY_ID"|"VIDEO_ID"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"playlist": $playlist, "position": $position, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($playlist: String!, $position: Int, $where: QueryPlaylisttrackPaginationWhereWhereConditions, $sort: [PlaylistTrackSort!], $first: Int!, $page: Int) { playlisttrackPagination(playlist: $playlist, position: $position, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "playlisttrackPagination" }
}

# Returns a listing of anime resources given fields.
#
# operationId: animePagination
# --where-AND item shape: {column?: "ID"|"NAME"|"FORMAT"|"SEASON"|"SYNOPSIS"|"YEAR"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"NAME"|"FORMAT"|"SEASON"|"SYNOPSIS"|"YEAR"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query anime-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --search: string
  --name: string
  --name-like: string
  --format: string@format-completer
  --format-in: string@format-in-completer
  --season: string@season-completer
  --season-in: string@season-in-completer
  --slug: string
  --year: int
  --year-lesser: int
  --year-greater: int
  --qp-sort: string@sort-completer-4
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-5 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"NAME"|"FORMAT"|"SEASON"|"SYNOPSIS"|"YEAR"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"NAME"|"FORMAT"|"SEASON"|"SYNOPSIS"|"YEAR"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "search": $search, "name": $name, "name_like": $name_like, "format": $format, "format_in": $format_in, "season": $season, "season_in": $season_in, "slug": $slug, "year": $year, "year_lesser": $year_lesser, "year_greater": $year_greater, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $search: String, $name: String, $name_like: String, $format: AnimeFormat, $format_in: [AnimeFormat!], $season: AnimeSeason, $season_in: [AnimeSeason!], $slug: String, $year: Int, $year_lesser: Int, $year_greater: Int, $where: QueryAnimePaginationWhereWhereConditions, $sort: [AnimeSort!], $first: Int!, $page: Int) { animePagination(id: $id, search: $search, name: $name, name_like: $name_like, format: $format, format_in: $format_in, season: $season, season_in: $season_in, slug: $slug, year: $year, year_lesser: $year_lesser, year_greater: $year_greater, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "animePagination" }
}

# Returns a listing of artist resources given fields.
#
# operationId: artistPagination
# --where-AND item shape: {column?: "ID"|"NAME"|"SLUG"|"INFORMATION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"NAME"|"SLUG"|"INFORMATION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query artist-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --name: string
  --name-like: string
  --search: string
  --slug: string
  --qp-sort: string@sort-completer-5
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-6 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"INFORMATION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"INFORMATION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "name": $name, "name_like": $name_like, "search": $search, "slug": $slug, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $name: String, $name_like: String, $search: String, $slug: String, $where: QueryArtistPaginationWhereWhereConditions, $sort: [ArtistSort!], $first: Int!, $page: Int) { artistPagination(id: $id, name: $name, name_like: $name_like, search: $search, slug: $slug, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "artistPagination" }
}

# Returns a listing of audio resources given fields.
#
# operationId: audioPagination
# --where-AND item shape: {column?: "ID"|"BASENAME"|"FILENAME"|"MIMETYPE"|"SIZE"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"BASENAME"|"FILENAME"|"MIMETYPE"|"SIZE"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query audio-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --basename: string
  --filename: string
  --mimetype: string
  --path: string
  --path-like: string
  --size-lesser: int
  --size-greater: int
  --qp-sort: string@sort-completer-6
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-7 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"BASENAME"|"FILENAME"|"MIMETYPE"|"SIZE"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"BASENAME"|"FILENAME"|"MIMETYPE"|"SIZE"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "basename": $basename, "filename": $filename, "mimetype": $mimetype, "path": $path, "path_like": $path_like, "size_lesser": $size_lesser, "size_greater": $size_greater, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $basename: String, $filename: String, $mimetype: String, $path: String, $path_like: String, $size_lesser: Int, $size_greater: Int, $where: QueryAudioPaginationWhereWhereConditions, $sort: [AudioSort!], $first: Int!, $page: Int) { audioPagination(id: $id, basename: $basename, filename: $filename, mimetype: $mimetype, path: $path, path_like: $path_like, size_lesser: $size_lesser, size_greater: $size_greater, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "audioPagination" }
}

# Returns a listing of images resources given fields.
#
# operationId: imagePagination
# --where-AND item shape: {column?: "ID"|"FACET"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"FACET"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query image-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --facet: string@facet-completer
  --path: string
  --path-like: string
  --qp-sort: string@sort-completer
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-8 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"FACET"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"FACET"|"PATH"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "facet": $facet, "path": $path, "path_like": $path_like, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $facet: ImageFacet, $path: String, $path_like: String, $where: QueryImagePaginationWhereWhereConditions, $sort: [ImageSort!], $first: Int!, $page: Int) { imagePagination(id: $id, facet: $facet, path: $path, path_like: $path_like, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "imagePagination" }
}

# Returns a listing of series resources given fields.
#
# operationId: seriesPagination
# --where-AND item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query series-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --search: string
  --name: string
  --name-like: string
  --slug: string
  --qp-sort: string@sort-completer-5
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-9 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "search": $search, "name": $name, "name_like": $name_like, "slug": $slug, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $search: String, $name: String, $name_like: String, $slug: String, $where: QuerySeriesPaginationWhereWhereConditions, $sort: [SeriesSort!], $first: Int!, $page: Int) { seriesPagination(id: $id, search: $search, name: $name, name_like: $name_like, slug: $slug, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "seriesPagination" }
}

# Returns a listing of song resources given fields.
#
# operationId: songPagination
# --where-AND item shape: {column?: "ID"|"TITLE"|"TITLE_NATIVE"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"TITLE"|"TITLE_NATIVE"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query song-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --title: string
  --title-native: string
  --qp-sort: string@sort-completer-7
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-10 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"TITLE"|"TITLE_NATIVE"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"TITLE"|"TITLE_NATIVE"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "title": $title, "titleNative": $title_native, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $title: String, $titleNative: String, $where: QuerySongPaginationWhereWhereConditions, $sort: [SongSort!], $first: Int!, $page: Int) { songPagination(id: $id, title: $title, titleNative: $titleNative, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "songPagination" }
}

# Returns a listing of studio resources given fields.
#
# operationId: studioPagination
# --where-AND item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query studio-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --search: string
  --name: string
  --name-like: string
  --slug: string
  --qp-sort: string@sort-completer-5
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-9 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "search": $search, "name": $name, "name_like": $name_like, "slug": $slug, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $search: String, $name: String, $name_like: String, $slug: String, $where: QueryStudioPaginationWhereWhereConditions, $sort: [StudioSort!], $first: Int!, $page: Int) { studioPagination(id: $id, search: $search, name: $name, name_like: $name_like, slug: $slug, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "studioPagination" }
}

# Returns a listing of theme group resources given fields.
#
# operationId: themegroupPagination
# --where-AND item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query themegroup-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --name: string
  --slug: string
  --qp-sort: string@sort-completer-1
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-9 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"NAME"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "name": $name, "slug": $slug, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $name: String, $slug: String, $where: QueryThemegroupPaginationWhereWhereConditions, $sort: [ThemeGroupSort!], $first: Int!, $page: Int) { themegroupPagination(id: $id, name: $name, slug: $slug, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "themegroupPagination" }
}

# Returns a listing of video resources given fields.
#
# operationId: videoPagination
# --where-AND item shape: {column?: "ID"|"BASENAME"|"FILENAME"|"LYRICS"|"MIMETYPE"|"NC"|"OVERLAP"|"PATH"|"RESOLUTION"|"SIZE"|"SOURCE"|"SUBBED"|"UNCEN"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"BASENAME"|"FILENAME"|"LYRICS"|"MIMETYPE"|"NC"|"OVERLAP"|"PATH"|"RESOLUTION"|"SIZE"|"SOURCE"|"SUBBED"|"UNCEN"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query video-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --basename: string
  --filename: string
  --lyrics: oneof<nothing, bool>
  --mimetype: string
  --nc: oneof<nothing, bool>
  --overlap: string@overlap-completer
  --path: string
  --path-like: string
  --resolution: int
  --resolution-lesser: int
  --resolution-greater: int
  --size-lesser: int
  --size-greater: int
  --qp-source: string@source-completer
  --subbed: oneof<nothing, bool>
  --uncen: oneof<nothing, bool>
  --qp-sort: string@sort-completer-8
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-11 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"BASENAME"|"FILENAME"|"LYRICS"|"MIMETYPE"|"NC"|"OVERLAP"|"PATH"|"RESOLUTION"|"SIZE"|"SOURCE"|"SUBBED"|"UNCEN"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"BASENAME"|"FILENAME"|"LYRICS"|"MIMETYPE"|"NC"|"OVERLAP"|"PATH"|"RESOLUTION"|"SIZE"|"SOURCE"|"SUBBED"|"UNCEN"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "basename": $basename, "filename": $filename, "lyrics": $lyrics, "mimetype": $mimetype, "nc": $nc, "overlap": $overlap, "path": $path, "path_like": $path_like, "resolution": $resolution, "resolution_lesser": $resolution_lesser, "resolution_greater": $resolution_greater, "size_lesser": $size_lesser, "size_greater": $size_greater, "source": $qp_source, "subbed": $subbed, "uncen": $uncen, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $basename: String, $filename: String, $lyrics: Boolean, $mimetype: String, $nc: Boolean, $overlap: VideoOverlap, $path: String, $path_like: String, $resolution: Int, $resolution_lesser: Int, $resolution_greater: Int, $size_lesser: Int, $size_greater: Int, $source: VideoSource, $subbed: Boolean, $uncen: Boolean, $where: QueryVideoPaginationWhereWhereConditions, $sort: [VideoSort!], $first: Int!, $page: Int) { videoPagination(id: $id, basename: $basename, filename: $filename, lyrics: $lyrics, mimetype: $mimetype, nc: $nc, overlap: $overlap, path: $path, path_like: $path_like, resolution: $resolution, resolution_lesser: $resolution_lesser, resolution_greater: $resolution_greater, size_lesser: $size_lesser, size_greater: $size_greater, source: $source, subbed: $subbed, uncen: $uncen, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "videoPagination" }
}

# Returns a listing of anime themes resources given fields.
#
# operationId: animethemePagination
# --where-AND item shape: {column?: "ID"|"TYPE"|"SEQUENCE"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"TYPE"|"SEQUENCE"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query animetheme-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --id: int
  --search: string
  --type: string@type-completer
  --type-in: string@type-in-completer
  --sequence: int
  --sequence-lesser: int
  --sequence-greater: int
  --slug: string
  --qp-sort: string@sort-completer-9
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-12 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"TYPE"|"SEQUENCE"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"TYPE"|"SEQUENCE"|"SLUG"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"id": $id, "search": $search, "type": $type, "type_in": $type_in, "sequence": $sequence, "sequence_lesser": $sequence_lesser, "sequence_greater": $sequence_greater, "slug": $slug, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($id: Int, $search: String, $type: ThemeType, $type_in: [ThemeType!], $sequence: Int, $sequence_lesser: Int, $sequence_greater: Int, $slug: String, $where: QueryAnimethemePaginationWhereWhereConditions, $sort: [AnimeThemeSort!], $first: Int!, $page: Int) { animethemePagination(id: $id, search: $search, type: $type, type_in: $type_in, sequence: $sequence, sequence_lesser: $sequence_lesser, sequence_greater: $sequence_greater, slug: $slug, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "animethemePagination" }
}

# GraphQL query: animethemeentryPagination
#
# operationId: animethemeentryPagination
# --where-AND item shape: {column?: "ID"|"EPISODES"|"NOTES"|"NSFW"|"SPOILER"|"VERSION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-OR item shape: {column?: "ID"|"EPISODES"|"NOTES"|"NSFW"|"SPOILER"|"VERSION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
# --where-HAS shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
export def "query animethemeentry-pagination" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --episodes: string
  --episodes-like: string
  --nsfw: oneof<nothing, bool>
  --spoiler: oneof<nothing, bool>
  --version: int
  --version-lesser: int
  --version-greater: int
  --qp-sort: string@sort-completer-10
  --first: int # Limits number of fetched items. Maximum allowed value: 100.
  --page: int # The offset from which items are returned.
  --where-column: string@where-column-completer-13 # The column that is used for the condition.
  --where-operator: string@where-operator-completer # The operator that is used for the condition.
  --where-value: string # The value that is used for the condition.
  --where-AND: record # A set of conditions that requires all conditions to match. — item shape: {column?: "ID"|"EPISODES"|"NOTES"|"NSFW"|"SPOILER"|"VERSION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-OR: record # A set of conditions that requires at least one condition to match. — item shape: {column?: "ID"|"EPISODES"|"NOTES"|"NSFW"|"SPOILER"|"VERSION"|"CREATED_AT"|"UPDATED_AT", operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", value?: string, AND?: record, OR?: record, HAS?: record}
  --where-HAS: record # Check whether a relation exists. Extra conditions or a minimum amount can be applied. — shape: {relation: string, operator?: "EQ"|"NEQ"|"GT"|"GTE"|"LT"|"LTE"|"LIKE"|"NOT_LIKE"|"IN"|"NOT_IN"|"BETWEEN"|"NOT_BETWEEN"|"IS_NULL"|"IS_NOT_NULL", amount?: int, condition?: record}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let where = ({"column": $where_column, "operator": $where_operator, "value": $where_value, "AND": $where_AND, "OR": $where_OR, "HAS": $where_HAS} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"episodes": $episodes, "episodes_like": $episodes_like, "nsfw": $nsfw, "spoiler": $spoiler, "version": $version, "version_lesser": $version_lesser, "version_greater": $version_greater, "sort": $qp_sort, "first": $first, "page": $page, "where": $where} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("query($episodes: String, $episodes_like: String, $nsfw: Boolean, $spoiler: Boolean, $version: Int, $version_lesser: Int, $version_greater: Int, $where: QueryAnimethemeentryPaginationWhereWhereConditions, $sort: [AnimeThemeEntrySort!], $first: Int!, $page: Int) { animethemeentryPagination(episodes: $episodes, episodes_like: $episodes_like, nsfw: $nsfw, spoiler: $spoiler, version: $version, version_lesser: $version_lesser, version_greater: $version_greater, sort: $sort, first: $first, page: $page, where: $where) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "animethemeentryPagination" }
}

# GraphQL mutation: ToggleLike
#
# operationId: ToggleLike
export def "mutation toggle-like" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --entry-id: int
  --playlist-id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"entryId": $entry_id, "playlistId": $playlist_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($entryId: Int, $playlistId: String) { ToggleLike(entryId: $entryId, playlistId: $playlistId) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "ToggleLike" }
}

# Mark a video as watched.
#
# operationId: Watch
export def "mutation watch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  entry_id: int
  video_id: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"entryId": $entry_id, "videoId": $video_id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename" }
    let body = {query: ("mutation($entryId: Int!, $videoId: Int!) { Watch(entryId: $entryId, videoId: $videoId) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "Watch" }
}

# GraphQL mutation: CreatePlaylist
#
# operationId: CreatePlaylist
export def "mutation create-playlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  name: string
  visibility: string@visibility-completer
  --description: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"name": $name, "visibility": $visibility, "description": $description} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name description visibility visibilityLocalized tracksCount tracksExists likesCount createdAt updatedAt" }
    let body = {query: ("mutation($name: String!, $visibility: PlaylistVisibility!, $description: String) { CreatePlaylist(name: $name, visibility: $visibility, description: $description) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "CreatePlaylist" }
}

# GraphQL mutation: UpdatePlaylist
#
# operationId: UpdatePlaylist
export def "mutation update-playlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  --name: string
  --visibility: string@visibility-completer
  --description: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "name": $name, "visibility": $visibility, "description": $description} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id name description visibility visibilityLocalized tracksCount tracksExists likesCount createdAt updatedAt" }
    let body = {query: ("mutation($id: String!, $name: String, $visibility: PlaylistVisibility, $description: String) { UpdatePlaylist(id: $id, name: $name, visibility: $visibility, description: $description) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "UpdatePlaylist" }
}

# GraphQL mutation: DeletePlaylist
#
# operationId: DeletePlaylist
export def "mutation delete-playlist" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "message" }
    let body = {query: ("mutation($id: String!) { DeletePlaylist(id: $id) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "DeletePlaylist" }
}

# GraphQL mutation: CreatePlaylistTrack
#
# operationId: CreatePlaylistTrack
export def "mutation create-playlist-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  playlist: string
  entry_id: int
  video_id: int
  --position: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"playlist": $playlist, "entryId": $entry_id, "videoId": $video_id, "position": $position} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id position createdAt updatedAt" }
    let body = {query: ("mutation($playlist: String!, $entryId: Int!, $videoId: Int!, $position: Int) { CreatePlaylistTrack(playlist: $playlist, entryId: $entryId, videoId: $videoId, position: $position) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "CreatePlaylistTrack" }
}

# GraphQL mutation: UpdatePlaylistTrack
#
# operationId: UpdatePlaylistTrack
export def "mutation update-playlist-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  playlist: string
  --entry-id: int
  --video-id: int
  --position: int
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "playlist": $playlist, "entryId": $entry_id, "videoId": $video_id, "position": $position} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "id position createdAt updatedAt" }
    let body = {query: ("mutation($id: String!, $playlist: String!, $entryId: Int, $videoId: Int, $position: Int) { UpdatePlaylistTrack(id: $id, playlist: $playlist, entryId: $entryId, videoId: $videoId, position: $position) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "UpdatePlaylistTrack" }
}

# GraphQL mutation: DeletePlaylistTrack
#
# operationId: DeletePlaylistTrack
export def "mutation delete-playlist-track" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  id: string
  playlist: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"id": $id, "playlist": $playlist} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "message" }
    let body = {query: ("mutation($id: String!, $playlist: String!) { DeletePlaylistTrack(id: $id, playlist: $playlist) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "DeletePlaylistTrack" }
}
