# Auto-generated client for OpenDota API v31.1.0
# Source: https://api.opendota.com/api
# Auth: --token flag or $env.OPENDOTA_API_TOKEN

const BASE_URL = "https://api.opendota.com/api"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPENDOTA_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
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

def base-url-completer [] { ["https://api.opendota.com/api"] }
def auth-scheme-completer [] { ["query-api_key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "matches id" } } | get name | first)
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

# GET /matches/{match_id}
#
# GET /matches/{match_id}
# operationId: get_matches_by_match_id
export def "matches id" [
  match_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/matches/($match_id)")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}
#
# GET /players/{account_id}
# operationId: get_players_by_account_id
export def "players id" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($account_id)")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/wl
#
# GET /players/{account_id}/wl
# operationId: get_players_by_account_id_select_wl
export def "players-wl wl" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/wl" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/recentMatches
#
# GET /players/{account_id}/recentMatches
# operationId: get_players_by_account_id_select_recent_matches
export def "players-recent-matches matches" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($account_id)/recentMatches")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/matches
#
# GET /players/{account_id}/matches
# operationId: get_players_by_account_id_select_matches
export def "players-matches matches" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
  --project: string # Fields to project (array)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/matches" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/heroes
#
# GET /players/{account_id}/heroes
# operationId: get_players_by_account_id_select_heroes
export def "players-heroes heroes" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/heroes" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/peers
#
# GET /players/{account_id}/peers
# operationId: get_players_by_account_id_select_peers
export def "players-peers peers" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/peers" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/pros
#
# GET /players/{account_id}/pros
# operationId: get_players_by_account_id_select_pros
export def "players-pros pros" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/pros" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/totals
#
# GET /players/{account_id}/totals
# operationId: get_players_by_account_id_select_totals
export def "players-totals totals" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/totals" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/counts
#
# GET /players/{account_id}/counts
# operationId: get_players_by_account_id_select_counts
export def "players-counts counts" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/counts" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/histograms
#
# GET /players/{account_id}/histograms/{field}
# operationId: get_players_by_account_id_histograms_by_field
export def "players-histograms field" [
  account_id: int
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/histograms/($field)" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/wardmap
#
# GET /players/{account_id}/wardmap
# operationId: get_players_by_account_id_select_wardmap
export def "players-wardmap wardmap" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/wardmap" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/wordcloud
#
# GET /players/{account_id}/wordcloud
# operationId: get_players_by_account_id_select_wordcloud
export def "players-wordcloud wordcloud" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of matches to limit to
  --offset: int # Number of matches to offset start by
  --win: int # Whether the player won
  --patch: int # Patch ID, from dotaconstants
  --game-mode: int # Game Mode ID
  --lobby-type: int # Lobby type ID
  --region: int # Region ID
  --date: int # Days previous
  --lane-role: int # Lane Role ID
  --hero-id: int # Hero ID
  --is-radiant: int # Whether the player was radiant
  --included-account-id: int # Account IDs in the match (array)
  --excluded-account-id: int # Account IDs not in the match (array)
  --with-hero-id: int # Hero IDs on the player's team (array)
  --against-hero-id: int # Hero IDs against the player's team (array)
  --significant: int # Whether the match was significant for aggregation purposes. Defaults to 1 (true), set this to 0 to return data for non-standard modes/matches.
  --having: int # The minimum number of games played, for filtering hero stats
  --qp-sort: string # The field to return matches sorted by in descending order
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "win" $win "scalar") (serialize-qp "patch" $patch "scalar") (serialize-qp "game_mode" $game_mode "scalar") (serialize-qp "lobby_type" $lobby_type "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "date" $date "scalar") (serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar") (serialize-qp "is_radiant" $is_radiant "scalar") (serialize-qp "included_account_id" $included_account_id "scalar") (serialize-qp "excluded_account_id" $excluded_account_id "scalar") (serialize-qp "with_hero_id" $with_hero_id "scalar") (serialize-qp "against_hero_id" $against_hero_id "scalar") (serialize-qp "significant" $significant "scalar") (serialize-qp "having" $having "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($account_id)/wordcloud" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/ratings
#
# GET /players/{account_id}/ratings
# operationId: get_players_by_account_id_select_ratings
export def "players-ratings ratings" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($account_id)/ratings")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /players/{account_id}/rankings
#
# GET /players/{account_id}/rankings
# operationId: get_players_by_account_id_select_rankings
export def "players-rankings rankings" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($account_id)/rankings")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /players/{account_id}/refresh
#
# POST /players/{account_id}/refresh
# operationId: post_refresh
export def "players-refresh refresh" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($account_id)/refresh")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /topPlayers
#
# GET /topPlayers
# operationId: get_top_players
export def "top-players players" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --turbo: int # Get ratings based on turbo matches
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "turbo" $turbo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/topPlayers" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /proPlayers
#
# GET /proPlayers
# operationId: get_pro_players
export def "pro-players players" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/proPlayers")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /proMatches
#
# GET /proMatches
# operationId: get_pro_matches
export def "pro-matches matches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --less-than-match-id: int # Get matches with a match ID lower than this value
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "less_than_match_id" $less_than_match_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/proMatches" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /publicMatches
#
# GET /publicMatches
# operationId: get_public_matches
export def "public-matches matches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --less-than-match-id: int # Get matches with a match ID lower than this value
  --min-rank: int # Minimum rank for the matches. Ranks are represented by integers (10-15: Herald, 20-25: Guardian, 30-35: Crusader, 40-45: Archon, 50-55: Legend, 60-65: Ancient, 70-75: Divine, 80: Immortal). Each increment represents an additional star.
  --max-rank: int # Maximum rank for the matches. Ranks are represented by integers (10-15: Herald, 20-25: Guardian, 30-35: Crusader, 40-45: Archon, 50-55: Legend, 60-65: Ancient, 70-75: Divine, 80: Immortal). Each increment represents an additional star.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "less_than_match_id" $less_than_match_id "scalar") (serialize-qp "min_rank" $min_rank "scalar") (serialize-qp "max_rank" $max_rank "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/publicMatches" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /parsedMatches
#
# GET /parsedMatches
# operationId: get_parsed_matches
export def "parsed-matches matches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --less-than-match-id: int # Get matches with a match ID lower than this value
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "less_than_match_id" $less_than_match_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/parsedMatches" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /explorer
#
# GET /explorer
# operationId: get_explorer
export def "explorer explorer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sql: string # The PostgreSQL query as percent-encoded string.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sql" $sql "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/explorer" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /metadata
#
# GET /metadata
# operationId: get_metadata
export def "metadata metadata" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/metadata")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /distributions
#
# GET /distributions
# operationId: get_distributions
export def "distributions distributions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/distributions")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /search
#
# GET /search
# operationId: get_search
export def "search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # Search string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /rankings
#
# GET /rankings
# operationId: get_rankings
export def "rankings rankings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hero-id: string # Hero ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hero_id" $hero_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rankings" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /benchmarks
#
# GET /benchmarks
# operationId: get_benchmarks
export def "benchmarks benchmarks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --hero-id: string # Hero ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hero_id" $hero_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/benchmarks" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /health
#
# GET /health
# operationId: get_health
export def "health health" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /request/{jobId}
#
# GET /request/{jobId}
# operationId: get_request_by_job_id
export def "request id-by-jobId" [
  jobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/request/($jobId)")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /request/{match_id}
#
# POST /request/{match_id}
# operationId: post_request_by_job_id
export def "request id-by-match_id" [
  match_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/request/($match_id)")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /
#
# GET /findMatches
# operationId: get_find_matches
export def "find-matches matches" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --teamA: list # Hero IDs on first team (array)
  --teamB: list # Hero IDs on second team (array)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "teamA" $teamA "csv") (serialize-qp "teamB" $teamB "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/findMatches" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /heroes
#
# GET /heroes
# operationId: get_heroes
export def "heroes heroes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/heroes")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /heroStats
#
# GET /heroStats
# operationId: get_hero_stats
export def "hero-stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/heroStats")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /heroes/{hero_id}/matches
#
# GET /heroes/{hero_id}/matches
# operationId: get_heroes_by_hero_id_select_matches
export def "heroes-matches matches" [
  hero_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heroes/($hero_id)/matches")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /heroes/{hero_id}/matchups
#
# GET /heroes/{hero_id}/matchups
# operationId: get_heroes_by_hero_id_select_matchups
export def "heroes-matchups matchups" [
  hero_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heroes/($hero_id)/matchups")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /heroes/{hero_id}/durations
#
# GET /heroes/{hero_id}/durations
# operationId: get_heroes_by_hero_id_select_durations
export def "heroes-durations durations" [
  hero_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heroes/($hero_id)/durations")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /heroes/{hero_id}/players
#
# GET /heroes/{hero_id}/players
# operationId: get_heroes_by_hero_id_select_players
export def "heroes-players players" [
  hero_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heroes/($hero_id)/players")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /heroes/{hero_id}/itemPopularity
#
# GET /heroes/{hero_id}/itemPopularity
# operationId: get_heroes_by_hero_id_select_item_popularity
export def "heroes-item-popularity popularity" [
  hero_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/heroes/($hero_id)/itemPopularity")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leagues
#
# GET /leagues
# operationId: get_leagues
export def "leagues leagues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/leagues")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leagues/{league_id}
#
# GET /leagues/{league_id}
# operationId: get_leagues_by_league_id
export def "leagues id" [
  league_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leagues/($league_id)")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leagues/{league_id}/matches
#
# GET /leagues/{league_id}/matches
# operationId: get_leagues_by_league_id_select_matches
export def "leagues-matches matches" [
  league_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leagues/($league_id)/matches")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leagues/{league_id}/matchIds
#
# GET /leagues/{league_id}/matchIds
# operationId: get_leagues_by_league_id_select_match_ids
export def "leagues-match-ids ids" [
  league_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leagues/($league_id)/matchIds")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leagues/{league_id}/teams
#
# GET /leagues/{league_id}/teams
# operationId: get_leagues_by_league_id_select_teams
export def "leagues-teams teams" [
  league_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/leagues/($league_id)/teams")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teams
#
# GET /teams
# operationId: get_teams
export def "teams teams" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number, zero indexed. Each page returns up to 1000 entries.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teams/{team_id}
#
# GET /teams/{team_id}
# operationId: get_teams_by_team_id
export def "teams id" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teams/{team_id}/matches
#
# GET /teams/{team_id}/matches
# operationId: get_teams_by_team_id_select_matches
export def "teams-matches matches" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)/matches")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teams/{team_id}/players
#
# GET /teams/{team_id}/players
# operationId: get_teams_by_team_id_select_players
export def "teams-players players" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)/players")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teams/{team_id}/heroes
#
# GET /teams/{team_id}/heroes
# operationId: get_teams_by_team_id_select_heroes
export def "teams-heroes heroes" [
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/teams/($team_id)/heroes")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /records/{field}
#
# GET /records/{field}
# operationId: get_records_by_field
export def "records field" [
  field: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/records/($field)")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /live
#
# GET /live
# operationId: get_live
export def "live live" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/live")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /scenarios/itemTimings
#
# GET /scenarios/itemTimings
# operationId: get_scenarios_item_timings
export def "scenarios-item-timings timings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --item: string # Filter by item name e.g. "spirit_vessel"
  --hero-id: int # Hero ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "item" $item "scalar") (serialize-qp "hero_id" $hero_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios/itemTimings" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /scenarios/laneRoles
#
# GET /scenarios/laneRoles
# operationId: get_scenarios_lane_roles
export def "scenarios-lane-roles roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lane-role: string # Filter by lane role 1-4 (Safe, Mid, Off, Jungle)
  --hero-id: int # Hero ID
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lane_role" $lane_role "scalar") (serialize-qp "hero_id" $hero_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios/laneRoles" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /scenarios/misc
#
# GET /scenarios/misc
# operationId: get_scenarios_misc
export def "scenarios-misc misc" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scenario: string # Name of the scenario (see teamScenariosQueryParams)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "scenario" $scenario "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scenarios/misc" $qp)
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /schema
#
# GET /schema
# operationId: get_schema
export def "schema schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schema")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /constants
#
# GET /constants/{resource}
# operationId: get_constants_by_resource
export def "constants resource" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/constants/($resource)")
  let accept_val = "application/json; charset=utf-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
