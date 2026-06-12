# Auto-generated client for Apple Music API v1.0.0
# Source: https://raw.githubusercontent.com/schroedan/apple-music-api/main/openapi.yaml
# Auth: --token flag or $env.APPLE_MUSIC_API_TOKEN

const BASE_URL = "https://api.music.apple.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APPLE_MUSIC_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "bearer" => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
    "music-user-token" => { {headers: {music-user-token: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.music.apple.com"] }
def auth-scheme-completer [] { ["bearer" "music-user-token"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "catalog-albums get-by-storefront" } } | get name | first)
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

# Get Multiple Catalog Albums
#
# GET /v1/catalog/{storefront}/albums
# operationId: getAlbumsFromCatalog
export def "catalog-albums get-by-storefront" [
  storefront: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The unique identifiers for the albums.
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --filter: list # A filter to apply to the request.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --restrict: list # A set of restrictions (for example, to restrict explicit content).
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record, views: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "extend" $extend "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "restrict" $restrict "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/albums" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Catalog Album
#
# GET /v1/catalog/{storefront}/albums/{id}
# operationId: getAlbumFromCatalog
export def "catalog-albums get-by-storefront-id" [
  storefront: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --views: list # The views to activate for the albums resource.
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record, views: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "views" $views "multi") (serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/albums/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Catalog Album's Relationship Directly by Name
#
# GET /v1/catalog/{storefront}/albums/{id}/{relationship}
# operationId: getAlbumRelationshipFromCatalog
export def "catalog-albums get-by-storefront-id-relationship" [
  storefront: any
  id: any
  relationship: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record, views: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/albums/($id)/($relationship)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Catalog Album's Relationship View Directly by Name
#
# GET /v1/catalog/{storefront}/albums/{id}/view/{view}
# operationId: getAlbumViewFromCatalog
export def "catalog-albums-view get" [
  storefront: any
  id: any
  view: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
  --with: list # A list of modifications to apply to the request.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record, views: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/albums/($id)/view/($view)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Multiple Catalog Artists
#
# GET /v1/catalog/{storefront}/artists
# operationId: getArtistsFromCatalog
export def "catalog-artists get-by-storefront" [
  storefront: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The unique identifiers for the artists.
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --filter: list # A filter to apply to the request.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --restrict: list # A set of restrictions (for example, to restrict explicit content).
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record, views: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "extend" $extend "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "restrict" $restrict "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/artists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Catalog Artist
#
# GET /v1/catalog/{storefront}/artists/{id}
# operationId: getArtistFromCatalog
export def "catalog-artists get-by-storefront-id" [
  storefront: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --views: list # The views to activate for the artists resource.
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record, views: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "views" $views "multi") (serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/artists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Catalog Artist's Relationship Directly by Name
#
# GET /v1/catalog/{storefront}/artists/{id}/{relationship}
# operationId: getArtistRelationshipFromCatalog
export def "catalog-artists get-by-storefront-id-relationship" [
  storefront: any
  id: any
  relationship: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record, views: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/artists/($id)/($relationship)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Catalog Artist's Relationship View Directly by Name
#
# GET /v1/catalog/{storefront}/artists/{id}/view/{view}
# operationId: getArtistViewFromCatalog
export def "catalog-artists-view get" [
  storefront: any
  id: any
  view: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
  --with: list # A list of modifications to apply to the request.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record, views: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/artists/($id)/view/($view)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for Catalog Resources
#
# GET /v1/catalog/{storefront}/search
# operationId: getSearchResponseFromCatalog
export def "catalog-search get" [
  storefront: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
  --offset: string # The next page or group of objects to fetch.
  --term: string # The entered text for the search with `+` characters between each word, to replace spaces (for example `term=james+br`).
  --types: list # The list of the types of resources to include in the results.
  --with: list # A list of modifications to apply to the request.
]: nothing -> record<results: record<albums: record<data: list, meta: record, next: string>, artists: record<data: list, meta: record, next: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "term" $term "scalar") (serialize-qp "types" $types "multi") (serialize-qp "with" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Multiple Catalog Songs by ID
#
# GET /v1/catalog/{storefront}/songs
# operationId: getSongsFromCatalog
export def "catalog-songs get-by-storefront" [
  storefront: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The unique identifiers for the songs.
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --filter: list # A filter to apply to the request.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --restrict: list # A set of restrictions (for example, to restrict explicit content).
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "extend" $extend "multi") (serialize-qp "filter" $filter "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "restrict" $restrict "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/songs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Catalog Song
#
# GET /v1/catalog/{storefront}/songs/{id}
# operationId: getSongFromCatalog
export def "catalog-songs get-by-storefront-id" [
  storefront: any
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/songs/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Catalog Song's Relationship Directly by Name
#
# GET /v1/catalog/{storefront}/songs/{id}/{relationship}
# operationId: getSongsRelationshipFromCatalog
export def "catalog-songs get-by-storefront-id-relationship" [
  storefront: any
  id: any
  relationship: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/catalog/($storefront)/songs/($id)/($relationship)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a Resource to a Library
#
# POST /v1/me/library
# operationId: addToLibrary
export def "me-library addToLibrary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The unique catalog identifiers for the resources. To indicate the type of resource to be added, ids must be followed by one of the allowed values. Add multiple types in the same request.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/library" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Library Albums
#
# GET /v1/me/library/albums
# operationId: getAlbumsFromLibrary
export def "me-library-albums get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The unique identifiers for the albums.
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
  --offset: string # The next page or group of objects to fetch.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/library/albums" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Library Album
#
# GET /v1/me/library/albums/{id}
# operationId: getAlbumFromLibrary
export def "me-library-albums get-by-id" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/library/albums/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Library Album's Relationship Directly by Name
#
# GET /v1/me/library/albums/{id}/{relationship}
# operationId: getAlbumRelationshipFromLibrary
export def "me-library-albums get-by-id-relationship" [
  id: any
  relationship: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/library/albums/($id)/($relationship)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Library Artists
#
# GET /v1/me/library/artists
# operationId: getArtistsFromLibrary
export def "me-library-artists get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The unique identifiers for the artists.
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
  --offset: string # The next page or group of objects to fetch.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/library/artists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Library Artist
#
# GET /v1/me/library/artists/{id}
# operationId: getArtistFromLibrary
export def "me-library-artists get-by-id" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/library/artists/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Library Artist's Relationship Directly by Name
#
# GET /v1/me/library/artists/{id}/{relationship}
# operationId: getArtistRelationshipFromLibrary
export def "me-library-artists get-by-id-relationship" [
  id: any
  relationship: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/library/artists/($id)/($relationship)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get All Library Songs
#
# GET /v1/me/library/songs
# operationId: getSongsFromLibrary
export def "me-library-songs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: list # The unique identifiers for the songs.
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
  --offset: string # The next page or group of objects to fetch.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "multi") (serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/me/library/songs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Library Song
#
# GET /v1/me/library/songs/{id}
# operationId: getSongFromLibrary
export def "me-library-songs get-by-id" [
  id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/library/songs/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Library Song's Relationship Directly by Name
#
# GET /v1/me/library/songs/{id}/{relationship}
# operationId: getSongsRelationshipFromLibrary
export def "me-library-songs get-by-id-relationship" [
  id: any
  relationship: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --extend: list # A list of attribute extensions to apply to resources in the response.
  --include: list # Additional relationships to include in the fetch.
  --l: string # The localization to use, specified by a language tag. The possible values are in the `supportedLanguageTags` array belonging to the `Storefront` object specified by `storefront`. Otherwise, the default is `defaultLanguageTag` in `Storefront`.
  --limit: int # The number of objects or number of objects in the specified relationship returned. (default: 5)
]: nothing -> record<data: table<id: string, type: string, href: string, attributes: record, relationships: record, meta: record>, meta: record, next: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "extend" $extend "multi") (serialize-qp "include" $include "multi") (serialize-qp "l" $l "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/me/library/songs/($id)/($relationship)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
