# Auto-generated client for NBA Stats API vversion
# Source: https://api.apis.guru/v2/specs/nba.com/version/swagger.json
# Auth: --token flag or $env.NBA_STATS_API_TOKEN

const BASE_URL = "https://stats.nba.com/stats"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NBA_STATS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://stats.nba.com/stats"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/html" "text/xml"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "allstarballotpredictor get" } } | get name | first)
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

# GET /allstarballotpredictor
export def "allstarballotpredictor get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --point-cap: string
  --west-player1: string
  --west-player2: string
  --west-player3: string
  --west-player4: string
  --west-player5: string
  --east-player1: string
  --east-player2: string
  --east-player3: string
  --east-player4: string
  --east-player5: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PointCap" $point_cap "scalar") (serialize-qp "WestPlayer1" $west_player1 "scalar") (serialize-qp "WestPlayer2" $west_player2 "scalar") (serialize-qp "WestPlayer3" $west_player3 "scalar") (serialize-qp "WestPlayer4" $west_player4 "scalar") (serialize-qp "WestPlayer5" $west_player5 "scalar") (serialize-qp "EastPlayer1" $east_player1 "scalar") (serialize-qp "EastPlayer2" $east_player2 "scalar") (serialize-qp "EastPlayer3" $east_player3 "scalar") (serialize-qp "EastPlayer4" $east_player4 "scalar") (serialize-qp "EastPlayer5" $east_player5 "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/allstarballotpredictor" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscore
#
# DEPRECATED
@deprecated
export def "boxscore get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscore" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoreadvanced
#
# DEPRECATED
@deprecated
export def "boxscoreadvanced get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreadvanced" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoreadvancedv2
export def "boxscoreadvancedv2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreadvancedv2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscorefourfactors
#
# DEPRECATED
@deprecated
export def "boxscorefourfactors get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscorefourfactors" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscorefourfactorsv2
export def "boxscorefourfactorsv2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscorefourfactorsv2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoremisc
#
# DEPRECATED
@deprecated
export def "boxscoremisc get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoremisc" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoremiscv2
export def "boxscoremiscv2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoremiscv2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoreplayertrackv2
export def "boxscoreplayertrackv2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreplayertrackv2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscorescoring
#
# DEPRECATED
@deprecated
export def "boxscorescoring get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscorescoring" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscorescoringv2
export def "boxscorescoringv2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscorescoringv2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoresummaryv2
export def "boxscoresummaryv2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoresummaryv2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoretraditionalv2
export def "boxscoretraditionalv2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoretraditionalv2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoreusage
#
# DEPRECATED
@deprecated
export def "boxscoreusage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreusage" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /boxscoreusagev2
export def "boxscoreusagev2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
  --start-range: string
  --end-range: string
  --range-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar") (serialize-qp "StartRange" $start_range "scalar") (serialize-qp "EndRange" $end_range "scalar") (serialize-qp "RangeType" $range_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/boxscoreusagev2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /commonTeamYears
export def "common-team-years get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonTeamYears" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /commonallplayers
export def "commonallplayers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season: string
  --is-only-current-season: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "IsOnlyCurrentSeason" $is_only_current_season "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonallplayers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /commonplayerinfo
export def "commonplayerinfo get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $player_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonplayerinfo" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /commonplayoffseries
export def "commonplayoffseries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonplayoffseries" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /commonteamroster
export def "commonteamroster get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season: string
  --team-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $season "scalar") (serialize-qp "TeamID" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/commonteamroster" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /draftcombinedrillresults
export def "draftcombinedrillresults get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombinedrillresults" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /draftcombinenonstationaryshooting
export def "draftcombinenonstationaryshooting get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombinenonstationaryshooting" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /draftcombineplayeranthro
export def "draftcombineplayeranthro get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombineplayeranthro" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /draftcombinespotshooting
export def "draftcombinespotshooting get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombinespotshooting" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /draftcombinestats
export def "draftcombinestats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season-year: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonYear" $season_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/draftcombinestats" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /drafthistory
export def "drafthistory get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/drafthistory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /franchisehistory
export def "franchisehistory get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/franchisehistory" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /homepageleaders
export def "homepageleaders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stat-category: string
  --league-id: string
  --season: string
  --season-type: string
  --player-or-team: string
  --game: string
  --player: string
  --player-scope: string
  --game-scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StatCategory" $stat_category "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerOrTeam" $player_or_team "scalar") (serialize-qp "Game" $game "scalar") (serialize-qp "Player" $player "scalar") (serialize-qp "PlayerScope" $player_scope "scalar") (serialize-qp "GameScope" $game_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/homepageleaders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /homepagev2
export def "homepagev2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stat-type: string
  --league-id: string
  --season: string
  --season-type: string
  --player-or-team: string
  --game: string
  --player: string
  --player-scope: string
  --game-scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StatType" $stat_type "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerOrTeam" $player_or_team "scalar") (serialize-qp "Game" $game "scalar") (serialize-qp "Player" $player "scalar") (serialize-qp "PlayerScope" $player_scope "scalar") (serialize-qp "GameScope" $game_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/homepagev2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaderstiles
export def "leaderstiles get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --stat: string
  --league-id: string
  --season: string
  --season-type: string
  --player-or-team: string
  --game: string
  --player: string
  --player-scope: string
  --game-scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Stat" $stat "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerOrTeam" $player_or_team "scalar") (serialize-qp "Game" $game "scalar") (serialize-qp "Player" $player "scalar") (serialize-qp "PlayerScope" $player_scope "scalar") (serialize-qp "GameScope" $game_scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaderstiles" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashlineups
export def "leaguedashlineups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --group-quantity: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GroupQuantity" $group_quantity "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashlineups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashplayerbiostats
export def "leaguedashplayerbiostats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --league-id: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayerbiostats" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashplayerclutch
export def "leaguedashplayerclutch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clutch-time: string
  --ahead-behind: string
  --point-diff: string
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClutchTime" $clutch_time "scalar") (serialize-qp "AheadBehind" $ahead_behind "scalar") (serialize-qp "PointDiff" $point_diff "scalar") (serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayerclutch" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashplayerptshot
export def "leaguedashplayerptshot get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --per-mode: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayerptshot" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashplayershotlocations
export def "leaguedashplayershotlocations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
  --distance-range: string
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar") (serialize-qp "DistanceRange" $distance_range "scalar") (serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayershotlocations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashplayerstats
export def "leaguedashplayerstats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashplayerstats" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashptdefend
export def "leaguedashptdefend get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --per-mode: string
  --season: string
  --season-type: string
  --defense-category: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "DefenseCategory" $defense_category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashptdefend" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashptteamdefend
export def "leaguedashptteamdefend get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --per-mode: string
  --season: string
  --season-type: string
  --defense-category: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "DefenseCategory" $defense_category "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashptteamdefend" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashteamclutch
export def "leaguedashteamclutch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --clutch-time: string
  --ahead-behind: string
  --point-diff: string
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClutchTime" $clutch_time "scalar") (serialize-qp "AheadBehind" $ahead_behind "scalar") (serialize-qp "PointDiff" $point_diff "scalar") (serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashteamclutch" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashteamptshot
export def "leaguedashteamptshot get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --per-mode: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashteamptshot" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashteamshotlocations
export def "leaguedashteamshotlocations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
  --distance-range: string
  --game-scope: string
  --player-experience: string
  --player-position: string
  --starter-bench: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar") (serialize-qp "DistanceRange" $distance_range "scalar") (serialize-qp "GameScope" $game_scope "scalar") (serialize-qp "PlayerExperience" $player_experience "scalar") (serialize-qp "PlayerPosition" $player_position "scalar") (serialize-qp "StarterBench" $starter_bench "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashteamshotlocations" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leaguedashteamstats
export def "leaguedashteamstats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leaguedashteamstats" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /leagueleaders
export def "leagueleaders get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --per-mode: string
  --stat-category: string
  --season: string
  --season-type: string
  --scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "StatCategory" $stat_category "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Scope" $scope "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/leagueleaders" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playbyplay
export def "playbyplay get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playbyplay" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playbyplayv2
export def "playbyplayv2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-id: string
  --start-period: string
  --end-period: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $game_id "scalar") (serialize-qp "StartPeriod" $start_period "scalar") (serialize-qp "EndPeriod" $end_period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playbyplayv2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playercareerstats
export def "playercareerstats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --player-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlayerID" $player_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playercareerstats" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playercompare
export def "playercompare get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-id-list: string
  --vs-player-id-list: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerIDList" $player_id_list "scalar") (serialize-qp "VsPlayerIDList" $vs_player_id_list "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playercompare" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashboardbyclutch
export def "playerdashboardbyclutch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyclutch" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashboardbygamesplits
export def "playerdashboardbygamesplits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbygamesplits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashboardbygeneralsplits
export def "playerdashboardbygeneralsplits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbygeneralsplits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashboardbylastngames
export def "playerdashboardbylastngames get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbylastngames" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashboardbyopponent
export def "playerdashboardbyopponent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyopponent" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashboardbyshootingsplits
export def "playerdashboardbyshootingsplits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyshootingsplits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashboardbyteamperformance
export def "playerdashboardbyteamperformance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyteamperformance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashboardbyyearoveryear
export def "playerdashboardbyyearoveryear get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --player-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashboardbyyearoveryear" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashptpass
export def "playerdashptpass get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptpass" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashptreb
export def "playerdashptreb get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptreb" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashptreboundlogs
#
# DEPRECATED
@deprecated
export def "playerdashptreboundlogs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptreboundlogs" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashptshotdefend
export def "playerdashptshotdefend get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptshotdefend" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashptshotlog
#
# DEPRECATED
@deprecated
export def "playerdashptshotlog get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptshotlog" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerdashptshots
export def "playerdashptshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --season: string
  --season-type: string
  --player-id: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerdashptshots" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playergamelog
export def "playergamelog get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-id: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playergamelog" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerprofile
export def "playerprofile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --player-id: string
  --season: string
  --season-type: string
  --graph-start-season: string
  --graph-end-season: string
  --graph-stat: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "GraphStartSeason" $graph_start_season "scalar") (serialize-qp "GraphEndSeason" $graph_end_season "scalar") (serialize-qp "GraphStat" $graph_stat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerprofile" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playerprofilev2
export def "playerprofilev2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --player-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlayerID" $player_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playerprofilev2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playersvsplayers
export def "playersvsplayers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-team-id: string
  --player-id1: string
  --player-id2: string
  --player-id3: string
  --player-id4: string
  --player-id5: string
  --vs-team-id: string
  --vs-player-id1: string
  --vs-player-id2: string
  --vs-player-id3: string
  --vs-player-id4: string
  --vs-player-id5: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerTeamID" $player_team_id "scalar") (serialize-qp "PlayerID1" $player_id1 "scalar") (serialize-qp "PlayerID2" $player_id2 "scalar") (serialize-qp "PlayerID3" $player_id3 "scalar") (serialize-qp "PlayerID4" $player_id4 "scalar") (serialize-qp "PlayerID5" $player_id5 "scalar") (serialize-qp "VsTeamID" $vs_team_id "scalar") (serialize-qp "VsPlayerID1" $vs_player_id1 "scalar") (serialize-qp "VsPlayerID2" $vs_player_id2 "scalar") (serialize-qp "VsPlayerID3" $vs_player_id3 "scalar") (serialize-qp "VsPlayerID4" $vs_player_id4 "scalar") (serialize-qp "VsPlayerID5" $vs_player_id5 "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playersvsplayers" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playervsplayer
export def "playervsplayer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --player-id: string
  --vs-player-id: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "VsPlayerID" $vs_player_id "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playervsplayer" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /playoffpicture
export def "playoffpicture get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonID" $season_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/playoffpicture" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /scoreboard
export def "scoreboard get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-date: string
  --league-id: string
  --day-offset: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameDate" $game_date "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "DayOffset" $day_offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scoreboard" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /scoreboardV2
export def "scoreboard-v2 get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --game-date: string
  --league-id: string
  --day-offset: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameDate" $game_date "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "DayOffset" $day_offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/scoreboardV2" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /shotchartdetail
export def "shotchartdetail get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season-type: string
  --team-id: string
  --player-id: string
  --game-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --position: string
  --rookie-year: string
  --game-segment: string
  --period: string
  --last-n-games: string
  --context-measure: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "PlayerID" $player_id "scalar") (serialize-qp "GameID" $game_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "Position" $position "scalar") (serialize-qp "RookieYear" $rookie_year "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar") (serialize-qp "ContextMeasure" $context_measure "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shotchartdetail" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /shotchartlineupdetail
export def "shotchartlineupdetail get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season: string
  --season-type: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
  --game-id: string
  --group-id: string
  --context-measure: string
  --context-filter: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar") (serialize-qp "GameID" $game_id "scalar") (serialize-qp "GROUP_ID" $group_id "scalar") (serialize-qp "ContextMeasure" $context_measure "scalar") (serialize-qp "ContextFilter" $context_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/shotchartlineupdetail" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashboardbyclutch
export def "teamdashboardbyclutch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyclutch" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashboardbygamesplits
export def "teamdashboardbygamesplits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbygamesplits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashboardbygeneralsplits
export def "teamdashboardbygeneralsplits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season-type: string
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbygeneralsplits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashboardbylastngames
export def "teamdashboardbylastngames get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbylastngames" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashboardbyopponent
export def "teamdashboardbyopponent get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyopponent" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashboardbyshootingsplits
export def "teamdashboardbyshootingsplits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyshootingsplits" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashboardbyteamperformance
export def "teamdashboardbyteamperformance get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyteamperformance" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashboardbyyearoveryear
export def "teamdashboardbyyearoveryear get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashboardbyyearoveryear" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashlineups
export def "teamdashlineups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --group-quantity: string
  --game-id: string
  --season-type: string
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GroupQuantity" $group_quantity "scalar") (serialize-qp "GameID" $game_id "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashlineups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashptpass
export def "teamdashptpass get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --season: string
  --season-type: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashptpass" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashptreb
export def "teamdashptreb get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --season: string
  --season-type: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashptreb" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamdashptshots
export def "teamdashptshots get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --per-mode: string
  --season: string
  --season-type: string
  --team-id: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamdashptshots" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamgamelog
export def "teamgamelog get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --season: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamgamelog" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teaminfocommon
export def "teaminfocommon get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season: string
  --team-id: string
  --league-id: string
  --season-type: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $season "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonType" $season_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teaminfocommon" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamplayerdashboard
export def "teamplayerdashboard get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --season-type: string
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamplayerdashboard" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamplayeronoffdetails
export def "teamplayeronoffdetails get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamplayeronoffdetails" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamplayeronoffsummary
export def "teamplayeronoffsummary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --season-type: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamplayeronoffsummary" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamvsplayer
export def "teamvsplayer get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --team-id: string
  --vs-player-id: string
  --season-type: string
  --measure-type: string
  --per-mode: string
  --plus-minus: string
  --pace-adjust: string
  --rank: string
  --season: string
  --outcome: string
  --location: string
  --month: string
  --season-segment: string
  --date-from: string
  --date-to: string
  --opponent-team-id: string
  --vs-conference: string
  --vs-division: string
  --game-segment: string
  --period: string
  --last-n-games: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $team_id "scalar") (serialize-qp "VsPlayerID" $vs_player_id "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "MeasureType" $measure_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "PlusMinus" $plus_minus "scalar") (serialize-qp "PaceAdjust" $pace_adjust "scalar") (serialize-qp "Rank" $rank "scalar") (serialize-qp "Season" $season "scalar") (serialize-qp "Outcome" $outcome "scalar") (serialize-qp "Location" $location "scalar") (serialize-qp "Month" $month "scalar") (serialize-qp "SeasonSegment" $season_segment "scalar") (serialize-qp "DateFrom" $date_from "scalar") (serialize-qp "DateTo" $date_to "scalar") (serialize-qp "OpponentTeamID" $opponent_team_id "scalar") (serialize-qp "VsConference" $vs_conference "scalar") (serialize-qp "VsDivision" $vs_division "scalar") (serialize-qp "GameSegment" $game_segment "scalar") (serialize-qp "Period" $period "scalar") (serialize-qp "LastNGames" $last_n_games "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamvsplayer" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /teamyearbyyearstats
export def "teamyearbyyearstats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --season-type: string
  --per-mode: string
  --team-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "SeasonType" $season_type "scalar") (serialize-qp "PerMode" $per_mode "scalar") (serialize-qp "TeamID" $team_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teamyearbyyearstats" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /videoStatus
export def "video-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --league-id: string
  --game-date: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $league_id "scalar") (serialize-qp "GameDate" $game_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videoStatus" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
