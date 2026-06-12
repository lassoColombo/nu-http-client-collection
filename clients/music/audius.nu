# Auto-generated client for API v1.0
# Source: https://raw.githubusercontent.com/AudiusProject/api-docs/master/swagger/swagger.json
# Auth: --token flag or $env.API_TOKEN

const BASE_URL = "https://localhost/AUDIUS_API_HOST/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o API_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost/AUDIUS_API_HOST/v1"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["date" "plays"] }
def sort-method-completer [] { ["added_date" "artist_name" "last_listen_date" "length" "most_listens_by_user" "plays" "release_date" "reposts" "saves" "title"] }
def sort-direction-completer [] { ["asc" "desc"] }
def filter-tracks-completer [] { ["all" "public" "unlisted"] }
def time-completer [] { ["allTime" "month" "week" "year"] }
def current-user-follows-completer [] { ["receiver" "sender" "sender_or_receiver"] }
def unique-by-completer [] { ["receiver" "sender"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "users Get-User" } } | get name | first)
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

# Gets a single user by their user ID
#
# GET /users/{id}
# operationId: Get User
export def "users Get-User" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: record<album_count: int, artist_pick_track_id: string, bio: string, cover_photo: record<640x: string, 2000x: string>, followee_count: int, follower_count: int, does_follow_current_user: bool, handle: string, id: string, is_verified: bool, location: string, name: string, playlist_count: int, profile_picture: record<150x150: string, 480x480: string, 1000x1000: string>, repost_count: int, track_count: int, is_deactivated: bool, is_available: bool, erc_wallet: string, spl_wallet: string, supporter_count: int, supporting_count: int, total_audio_balance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a User ID from an associated wallet address
#
# GET /users/id
# operationId: Get User ID from Wallet
export def "users-id Get-User-ID-from-Wallet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --associated-wallet: string # Wallet address (e.g. 0x087F08462BbD30fC1775bBA3E58821F4CaD47b6b)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: record<user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "associated_wallet" $associated_wallet "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/id" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for users that match the given query
#
# GET /users/search
# operationId: Search Users
export def "users-search Search-Users" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query (e.g. Brownies)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<album_count: int, artist_pick_track_id: string, bio: string, cover_photo: record, followee_count: int, follower_count: int, does_follow_current_user: bool, handle: string, id: string, is_verified: bool, location: string, name: string, playlist_count: int, profile_picture: record, repost_count: int, track_count: int, is_deactivated: bool, is_available: bool, erc_wallet: string, spl_wallet: string, supporter_count: int, supporting_count: int, total_audio_balance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify if the given jwt ID token was signed by the subject (user) in the payload
#
# GET /users/verify_token
# operationId: Verify ID Token
export def "users-verify-token Verify-ID-Token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # JWT to verify (e.g. eyJ0eXAiOiJKV1QiLCJhbGciOiJrZWNjYWsyNTYifQ.eyJ1c2VySWQiOjE0MTYxMTUsImVtYWlsIjoiaXNhYWN0ZXN0NDUxQGdtYWlsLmNvbSIsIm5hbWUiOiJ0ZXN0aW5nMTIiLCJoYW5kbGUiOiJ0ZXN0dGVzdDQ1MSIsInZlcmlmaWVkIjpmYWxzZSwic3ViIjoxNDE2MTE1LCJpYXQiOjE2NTY1MTgzMzN9.MHhkZmYyYWY5ZThmNDAxZDUyZDlhNjUxNGRiOTg0ZjM5YjFhOTZkYmNmZmViZjMzZjNkNmEzMTk4OTVlZWE2MTZjNjg0NWIwOGEyOGQ4MTA4OTEyMTc4ZDU0ODRhZGU4M2I1Yzg4ZTUwM2Y3OGYzMDYzZjYxMmQxZDQwYTYwMGZmZDFi)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: record<userId: string, email: string, name: string, handle: string, verified: bool, profilePicture: record<150x150: string, 480x480: string, 1000x1000: string>, sub: string, iat: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/verify_token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the User's ERC and SPL connected wallets
#
# GET /users/{id}/connected_wallets
# operationId: Get User's Connected Wallets
export def "users-connected-wallets Get-Users-Connected-Wallets" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: record<erc_wallets: list<string>, spl_wallets: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/connected_wallets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a user's favorite tracks
#
# GET /users/{id}/favorites
# operationId: Get User's Favorite Tracks
export def "users-favorites Get-Users-Favorite-Tracks" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<favorite_item_id: string, favorite_type: string, user_id: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/favorites" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the given user's reposts
#
# GET /users/{id}/reposts
# operationId: Get User's Reposts
export def "users-reposts Get-Users-Reposts" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<timestamp: string, item_type: record, item: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/reposts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All users that follow the provided user
#
# GET /users/{id}/followers
# operationId: Get Followers
export def "users-followers Get-Followers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<album_count: int, artist_pick_track_id: string, bio: string, cover_photo: record, followee_count: int, follower_count: int, does_follow_current_user: bool, handle: string, id: string, is_verified: bool, location: string, name: string, playlist_count: int, profile_picture: record, repost_count: int, track_count: int, is_deactivated: bool, is_available: bool, erc_wallet: string, spl_wallet: string, supporter_count: int, supporting_count: int, total_audio_balance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/followers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All users that the provided user follows
#
# GET /users/{id}/following
# operationId: Get Following
export def "users-following Get-Following" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<album_count: int, artist_pick_track_id: string, bio: string, cover_photo: record, followee_count: int, follower_count: int, does_follow_current_user: bool, handle: string, id: string, is_verified: bool, location: string, name: string, playlist_count: int, profile_picture: record, repost_count: int, track_count: int, is_deactivated: bool, is_available: bool, erc_wallet: string, spl_wallet: string, supporter_count: int, supporting_count: int, total_audio_balance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/following" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the supporters of the given user
#
# GET /users/{id}/supporters
# operationId: Get Supporters
export def "users-supporters Get-Supporters" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<rank: int, amount: string, sender: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/supporters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the users that the given user supports
#
# GET /users/{id}/supporting
# operationId: Get Supportings
export def "users-supporting Get-Supportings" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<rank: int, amount: string, receiver: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/supporting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the tracks created by a user using their user ID
#
# GET /users/{id}/tracks
# operationId: Get User's Tracks
export def "users-tracks Get-Users-Tracks" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --qp-sort: string@sort-completer # [Deprecated] Field to sort by (default: date)
  --qp-query: string # The filter query
  --sort-method: string@sort-method-completer # The sort method
  --sort-direction: string@sort-direction-completer # The sort direction
  --filter-tracks: string@filter-tracks-completer # Filter by unlisted or public tracks (default: all)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, genre: string, id: string, track_cid: string, mood: string, release_date: string, remix_of: record, repost_count: int, favorite_count: int, tags: string, title: string, user: record, duration: int, downloadable: bool, play_count: int, permalink: string, is_streamable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort_method" $sort_method "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "filter_tracks" $filter_tracks "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/tracks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of users that might be of interest to followers of this user.
#
# GET /users/{id}/related
# operationId: Get Related Users
export def "users-related Get-Related-Users" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<album_count: int, artist_pick_track_id: string, bio: string, cover_photo: record, followee_count: int, follower_count: int, does_follow_current_user: bool, handle: string, id: string, is_verified: bool, location: string, name: string, playlist_count: int, profile_picture: record, repost_count: int, track_count: int, is_deactivated: bool, is_available: bool, erc_wallet: string, spl_wallet: string, supporter_count: int, supporting_count: int, total_audio_balance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/related" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# All users that subscribe to the provided user
#
# GET /users/{id}/subscribers
# operationId: Get Subscribers
export def "users-subscribers Get-Subscribers" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<album_count: int, artist_pick_track_id: string, bio: string, cover_photo: record, followee_count: int, follower_count: int, does_follow_current_user: bool, handle: string, id: string, is_verified: bool, location: string, name: string, playlist_count: int, profile_picture: record, repost_count: int, track_count: int, is_deactivated: bool, is_available: bool, erc_wallet: string, spl_wallet: string, supporter_count: int, supporting_count: int, total_audio_balance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch most used tags in a user's tracks
#
# GET /users/{id}/tags
# operationId: Get User's Most Used Track Tags
export def "users-tags Get-Users-Most-Used-Track-Tags" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/($id)/tags" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a single user by their handle
#
# GET /users/handle/{handle}
# operationId: Get User by Handle
export def "users-handle Get-User-by-Handle" [
  handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # The user ID of the user making the request
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: record<album_count: int, artist_pick_track_id: string, bio: string, cover_photo: record<640x: string, 2000x: string>, followee_count: int, follower_count: int, does_follow_current_user: bool, handle: string, id: string, is_verified: bool, location: string, name: string, playlist_count: int, profile_picture: record<150x150: string, 480x480: string, 1000x1000: string>, repost_count: int, track_count: int, is_deactivated: bool, is_available: bool, erc_wallet: string, spl_wallet: string, supporter_count: int, supporting_count: int, total_audio_balance: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/handle/($handle)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the AI generated tracks attributed to a user using the user's handle
#
# GET /users/handle/{handle}/tracks/ai_attributed
# operationId: Get AI Tracks by Handle
export def "users-handle-tracks-ai-attributed Get-AI-Tracks-by-Handle" [
  handle: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --qp-sort: string@sort-completer # [Deprecated] Field to sort by (default: date)
  --qp-query: string # The filter query
  --sort-method: string@sort-method-completer # The sort method
  --sort-direction: string@sort-direction-completer # The sort direction
  --filter-tracks: string@filter-tracks-completer # Filter by unlisted or public tracks (default: all)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, genre: string, id: string, track_cid: string, mood: string, release_date: string, remix_of: record, repost_count: int, favorite_count: int, tags: string, title: string, user: record, duration: int, downloadable: bool, play_count: int, permalink: string, is_streamable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "sort_method" $sort_method "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "filter_tracks" $filter_tracks "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/handle/($handle)/tracks/ai_attributed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a playlist by ID
#
# GET /playlists/{playlist_id}
# operationId: Get Playlist
export def "playlists Get-Playlist" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, permalink: string, id: string, is_album: bool, playlist_name: string, repost_count: int, favorite_count: int, total_play_count: int, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($playlist_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for a playlist
#
# GET /playlists/search
# operationId: Search Playlists
export def "playlists-search Search-Playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query (e.g. Hot & New)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, permalink: string, id: string, is_album: bool, playlist_name: string, repost_count: int, favorite_count: int, total_play_count: int, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playlists/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets trending playlists for a time period
#
# GET /playlists/trending
# operationId: Get Trending Playlists
export def "playlists-trending Get-Trending-Playlists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --time: string@time-completer # Calculate trending over a specified time range
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, permalink: string, id: string, is_album: bool, playlist_name: string, repost_count: int, favorite_count: int, total_play_count: int, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "time" $time "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playlists/trending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch tracks within a playlist.
#
# GET /playlists/{playlist_id}/tracks
# operationId: Get Playlist Tracks
export def "playlists-tracks Get-Playlist-Tracks" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, genre: string, id: string, track_cid: string, mood: string, release_date: string, remix_of: record, repost_count: int, favorite_count: int, tags: string, title: string, user: record, duration: int, downloadable: bool, play_count: int, permalink: string, is_streamable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/playlists/($playlist_id)/tracks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a track by ID
#
# GET /tracks/{track_id}
# operationId: Get Track
export def "tracks Get-Track" [
  track_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: record<artwork: record<150x150: string, 480x480: string, 1000x1000: string>, description: string, genre: string, id: string, track_cid: string, mood: string, release_date: string, remix_of: record<tracks: list>, repost_count: int, favorite_count: int, tags: string, title: string, user: record<album_count: int, artist_pick_track_id: string, bio: string, cover_photo: record, followee_count: int, follower_count: int, does_follow_current_user: bool, handle: string, id: string, is_verified: bool, location: string, name: string, playlist_count: int, profile_picture: record, repost_count: int, track_count: int, is_deactivated: bool, is_available: bool, erc_wallet: string, spl_wallet: string, supporter_count: int, supporting_count: int, total_audio_balance: int>, duration: int, downloadable: bool, play_count: int, permalink: string, is_streamable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($track_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of tracks using their IDs or permalinks
#
# GET /tracks
# operationId: Get Bulk Tracks
export def "tracks Get-Bulk-Tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permalink: list # The permalink of the track(s) (e.g. /TeamBandL/paauer-|-baauer-b2b-party-favor-|-bl-block-party-la-live-set-725)
  --id: list # The ID of the track(s)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, genre: string, id: string, track_cid: string, mood: string, release_date: string, remix_of: record, repost_count: int, favorite_count: int, tags: string, title: string, user: record, duration: int, downloadable: bool, play_count: int, permalink: string, is_streamable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permalink" $permalink "multi") (serialize-qp "id" $id "multi") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tracks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for a track or tracks
#
# GET /tracks/search
# operationId: Search Tracks
export def "tracks-search Search-Tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string # The search query (e.g. baauer b2b)
  --only-downloadable: string # Return only downloadable tracks (default: false)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, genre: string, id: string, track_cid: string, mood: string, release_date: string, remix_of: record, repost_count: int, favorite_count: int, tags: string, title: string, user: record, duration: int, downloadable: bool, play_count: int, permalink: string, is_streamable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "only_downloadable" $only_downloadable "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tracks/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the top 100 trending (most popular) tracks on Audius
#
# GET /tracks/trending
# operationId: Get Trending Tracks
export def "tracks-trending Get-Trending-Tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --genre: string # Filter trending to a specified genre
  --time: string@time-completer # Calculate trending over a specified time range
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, genre: string, id: string, track_cid: string, mood: string, release_date: string, remix_of: record, repost_count: int, favorite_count: int, tags: string, title: string, user: record, duration: int, downloadable: bool, play_count: int, permalink: string, is_streamable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "genre" $genre "scalar") (serialize-qp "time" $time "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tracks/trending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the top 100 trending underground tracks on Audius
#
# GET /tracks/trending/underground
# operationId: Get Underground Trending Tracks
export def "tracks-trending-underground Get-Underground-Trending-Tracks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<artwork: record, description: string, genre: string, id: string, track_cid: string, mood: string, release_date: string, remix_of: record, repost_count: int, favorite_count: int, tags: string, title: string, user: record, duration: int, downloadable: bool, play_count: int, permalink: string, is_streamable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tracks/trending/underground" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the streamable MP3 file of a track
#
# GET /tracks/{track_id}/stream
# operationId: Stream Track
export def "tracks-stream Stream-Track" [
  track_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-signature: string # Optional - signature from the requesting user's wallet.         This is needed to authenticate the user and verify access in case the track is premium.
  --user-data: string # Optional - data which was used to generate the optional signature argument.
  --premium-content-signature: string # Optional - premium content signature for this track which was previously generated by a registered DN.         This is so that track access won't have to be check; instead, we check that the user which generated the         user signature and the user for whom the DN signed are the same.
  --filename: string # Optional - Filename in case user is trying to download track.         This is needed by the CN in order to set the Content-Disposition response header.
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_signature" $user_signature "scalar") (serialize-qp "user_data" $user_data "scalar") (serialize-qp "premium_content_signature" $premium_content_signature "scalar") (serialize-qp "filename" $filename "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tracks/($track_id)/stream" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the most recent tips on the network
#
# GET /tips
# operationId: Get Tips
export def "tips Get-Tips" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int # The number of items to skip. Useful for pagination (page number * limit)
  --limit: int # The number of items to fetch
  --user-id: string # The user ID of the user making the request
  --receiver-min-followers: int # Only include tips to recipients that have this many followers (default: 0)
  --receiver-is-verified: oneof<nothing, bool> # Only include tips to recipients that are verified (default: false)
  --current-user-follows: string@current-user-follows-completer # Only include tips involving the user's followers in the given capacity. Requires user_id to be set.
  --unique-by: string@unique-by-completer # Only include the most recent tip for a user was involved in the given capacity.  Eg. 'sender' will ensure that each tip returned has a unique sender, using the most recent tip sent by a user if that user has sent multiple tips.     
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> record<data: table<amount: string, sender: record, receiver: record, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "receiver_min_followers" $receiver_min_followers "scalar") (serialize-qp "receiver_is_verified" $receiver_is_verified "scalar") (serialize-qp "current_user_follows" $current_user_follows "scalar") (serialize-qp "unique_by" $unique_by "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tips" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolves and redirects a provided Audius app URL to the API resource URL it represents
#
# GET /resolve
# operationId: Resolve
export def "resolve Resolve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-url: string # URL to resolve. Either fully formed URL (https://audius.co) or just the absolute path (e.g. https://audius.co/camouflybeats/hypermantra-86216)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
  --app-name: string # Your app name (e.g. EXAMPLEAPP)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $qp_url "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar") (serialize-qp "app_name" $app_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/resolve" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
