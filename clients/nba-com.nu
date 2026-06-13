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
  --PointCap: string
  --WestPlayer1: string
  --WestPlayer2: string
  --WestPlayer3: string
  --WestPlayer4: string
  --WestPlayer5: string
  --EastPlayer1: string
  --EastPlayer2: string
  --EastPlayer3: string
  --EastPlayer4: string
  --EastPlayer5: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PointCap" $PointCap "scalar") (serialize-qp "WestPlayer1" $WestPlayer1 "scalar") (serialize-qp "WestPlayer2" $WestPlayer2 "scalar") (serialize-qp "WestPlayer3" $WestPlayer3 "scalar") (serialize-qp "WestPlayer4" $WestPlayer4 "scalar") (serialize-qp "WestPlayer5" $WestPlayer5 "scalar") (serialize-qp "EastPlayer1" $EastPlayer1 "scalar") (serialize-qp "EastPlayer2" $EastPlayer2 "scalar") (serialize-qp "EastPlayer3" $EastPlayer3 "scalar") (serialize-qp "EastPlayer4" $EastPlayer4 "scalar") (serialize-qp "EastPlayer5" $EastPlayer5 "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
  --StartRange: string
  --EndRange: string
  --RangeType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar") (serialize-qp "StartRange" $StartRange "scalar") (serialize-qp "EndRange" $EndRange "scalar") (serialize-qp "RangeType" $RangeType "scalar")] | flatten | str join "&"
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
  --LeagueID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --Season: string
  --IsOnlyCurrentSeason: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "IsOnlyCurrentSeason" $IsOnlyCurrentSeason "scalar")] | flatten | str join "&"
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
  --PlayerID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $PlayerID "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --Season: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "Season" $Season "scalar")] | flatten | str join "&"
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
  --Season: string
  --TeamID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $Season "scalar") (serialize-qp "TeamID" $TeamID "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --SeasonYear: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "SeasonYear" $SeasonYear "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --SeasonYear: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "SeasonYear" $SeasonYear "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --SeasonYear: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "SeasonYear" $SeasonYear "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --SeasonYear: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "SeasonYear" $SeasonYear "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --SeasonYear: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "SeasonYear" $SeasonYear "scalar")] | flatten | str join "&"
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
  --LeagueID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar")] | flatten | str join "&"
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
  --LeagueID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar")] | flatten | str join "&"
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
  --StatCategory: string
  --LeagueID: string
  --Season: string
  --SeasonType: string
  --PlayerOrTeam: string
  --Game: string
  --Player: string
  --PlayerScope: string
  --GameScope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StatCategory" $StatCategory "scalar") (serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerOrTeam" $PlayerOrTeam "scalar") (serialize-qp "Game" $Game "scalar") (serialize-qp "Player" $Player "scalar") (serialize-qp "PlayerScope" $PlayerScope "scalar") (serialize-qp "GameScope" $GameScope "scalar")] | flatten | str join "&"
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
  --StatType: string
  --LeagueID: string
  --Season: string
  --SeasonType: string
  --PlayerOrTeam: string
  --Game: string
  --Player: string
  --PlayerScope: string
  --GameScope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "StatType" $StatType "scalar") (serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerOrTeam" $PlayerOrTeam "scalar") (serialize-qp "Game" $Game "scalar") (serialize-qp "Player" $Player "scalar") (serialize-qp "PlayerScope" $PlayerScope "scalar") (serialize-qp "GameScope" $GameScope "scalar")] | flatten | str join "&"
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
  --Stat: string
  --LeagueID: string
  --Season: string
  --SeasonType: string
  --PlayerOrTeam: string
  --Game: string
  --Player: string
  --PlayerScope: string
  --GameScope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Stat" $Stat "scalar") (serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerOrTeam" $PlayerOrTeam "scalar") (serialize-qp "Game" $Game "scalar") (serialize-qp "Player" $Player "scalar") (serialize-qp "PlayerScope" $PlayerScope "scalar") (serialize-qp "GameScope" $GameScope "scalar")] | flatten | str join "&"
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
  --GroupQuantity: string
  --SeasonType: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GroupQuantity" $GroupQuantity "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --LeagueID: string
  --Season: string
  --SeasonType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar")] | flatten | str join "&"
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
  --ClutchTime: string
  --AheadBehind: string
  --PointDiff: string
  --GameScope: string
  --PlayerExperience: string
  --PlayerPosition: string
  --StarterBench: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClutchTime" $ClutchTime "scalar") (serialize-qp "AheadBehind" $AheadBehind "scalar") (serialize-qp "PointDiff" $PointDiff "scalar") (serialize-qp "GameScope" $GameScope "scalar") (serialize-qp "PlayerExperience" $PlayerExperience "scalar") (serialize-qp "PlayerPosition" $PlayerPosition "scalar") (serialize-qp "StarterBench" $StarterBench "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --PerMode: string
  --Season: string
  --SeasonType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
  --DistanceRange: string
  --GameScope: string
  --PlayerExperience: string
  --PlayerPosition: string
  --StarterBench: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar") (serialize-qp "DistanceRange" $DistanceRange "scalar") (serialize-qp "GameScope" $GameScope "scalar") (serialize-qp "PlayerExperience" $PlayerExperience "scalar") (serialize-qp "PlayerPosition" $PlayerPosition "scalar") (serialize-qp "StarterBench" $StarterBench "scalar")] | flatten | str join "&"
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
  --GameScope: string
  --PlayerExperience: string
  --PlayerPosition: string
  --StarterBench: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameScope" $GameScope "scalar") (serialize-qp "PlayerExperience" $PlayerExperience "scalar") (serialize-qp "PlayerPosition" $PlayerPosition "scalar") (serialize-qp "StarterBench" $StarterBench "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --PerMode: string
  --Season: string
  --SeasonType: string
  --DefenseCategory: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "DefenseCategory" $DefenseCategory "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --PerMode: string
  --Season: string
  --SeasonType: string
  --DefenseCategory: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "DefenseCategory" $DefenseCategory "scalar")] | flatten | str join "&"
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
  --ClutchTime: string
  --AheadBehind: string
  --PointDiff: string
  --GameScope: string
  --PlayerExperience: string
  --PlayerPosition: string
  --StarterBench: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ClutchTime" $ClutchTime "scalar") (serialize-qp "AheadBehind" $AheadBehind "scalar") (serialize-qp "PointDiff" $PointDiff "scalar") (serialize-qp "GameScope" $GameScope "scalar") (serialize-qp "PlayerExperience" $PlayerExperience "scalar") (serialize-qp "PlayerPosition" $PlayerPosition "scalar") (serialize-qp "StarterBench" $StarterBench "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --PerMode: string
  --Season: string
  --SeasonType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
  --DistanceRange: string
  --GameScope: string
  --PlayerExperience: string
  --PlayerPosition: string
  --StarterBench: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar") (serialize-qp "DistanceRange" $DistanceRange "scalar") (serialize-qp "GameScope" $GameScope "scalar") (serialize-qp "PlayerExperience" $PlayerExperience "scalar") (serialize-qp "PlayerPosition" $PlayerPosition "scalar") (serialize-qp "StarterBench" $StarterBench "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --PerMode: string
  --StatCategory: string
  --Season: string
  --SeasonType: string
  --Scope: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "StatCategory" $StatCategory "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Scope" $Scope "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar")] | flatten | str join "&"
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
  --GameID: string
  --StartPeriod: string
  --EndPeriod: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameID" $GameID "scalar") (serialize-qp "StartPeriod" $StartPeriod "scalar") (serialize-qp "EndPeriod" $EndPeriod "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --PlayerID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlayerID" $PlayerID "scalar")] | flatten | str join "&"
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
  --PlayerIDList: string
  --VsPlayerIDList: string
  --SeasonType: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerIDList" $PlayerIDList "scalar") (serialize-qp "VsPlayerIDList" $VsPlayerIDList "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --TeamID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "TeamID" $TeamID "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --Season: string
  --SeasonType: string
  --PlayerID: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PlayerID: string
  --Season: string
  --SeasonType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --PlayerID: string
  --Season: string
  --SeasonType: string
  --GraphStartSeason: string
  --GraphEndSeason: string
  --GraphStat: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "GraphStartSeason" $GraphStartSeason "scalar") (serialize-qp "GraphEndSeason" $GraphEndSeason "scalar") (serialize-qp "GraphStat" $GraphStat "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --PlayerID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlayerID" $PlayerID "scalar")] | flatten | str join "&"
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
  --PlayerTeamID: string
  --PlayerID1: string
  --PlayerID2: string
  --PlayerID3: string
  --PlayerID4: string
  --PlayerID5: string
  --VsTeamID: string
  --VsPlayerID1: string
  --VsPlayerID2: string
  --VsPlayerID3: string
  --VsPlayerID4: string
  --VsPlayerID5: string
  --SeasonType: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerTeamID" $PlayerTeamID "scalar") (serialize-qp "PlayerID1" $PlayerID1 "scalar") (serialize-qp "PlayerID2" $PlayerID2 "scalar") (serialize-qp "PlayerID3" $PlayerID3 "scalar") (serialize-qp "PlayerID4" $PlayerID4 "scalar") (serialize-qp "PlayerID5" $PlayerID5 "scalar") (serialize-qp "VsTeamID" $VsTeamID "scalar") (serialize-qp "VsPlayerID1" $VsPlayerID1 "scalar") (serialize-qp "VsPlayerID2" $VsPlayerID2 "scalar") (serialize-qp "VsPlayerID3" $VsPlayerID3 "scalar") (serialize-qp "VsPlayerID4" $VsPlayerID4 "scalar") (serialize-qp "VsPlayerID5" $VsPlayerID5 "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PlayerID: string
  --VsPlayerID: string
  --SeasonType: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "VsPlayerID" $VsPlayerID "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --SeasonID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "SeasonID" $SeasonID "scalar")] | flatten | str join "&"
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
  --GameDate: string
  --LeagueID: string
  --DayOffset: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameDate" $GameDate "scalar") (serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "DayOffset" $DayOffset "scalar")] | flatten | str join "&"
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
  --GameDate: string
  --LeagueID: string
  --DayOffset: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GameDate" $GameDate "scalar") (serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "DayOffset" $DayOffset "scalar")] | flatten | str join "&"
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
  --SeasonType: string
  --TeamID: string
  --PlayerID: string
  --GameID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --Position: string
  --RookieYear: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
  --ContextMeasure: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "PlayerID" $PlayerID "scalar") (serialize-qp "GameID" $GameID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "Position" $Position "scalar") (serialize-qp "RookieYear" $RookieYear "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar") (serialize-qp "ContextMeasure" $ContextMeasure "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --Season: string
  --SeasonType: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
  --GameID: string
  --GROUP-ID: string
  --ContextMeasure: string
  --ContextFilter: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar") (serialize-qp "GameID" $GameID "scalar") (serialize-qp "GROUP_ID" $GROUP_ID "scalar") (serialize-qp "ContextMeasure" $ContextMeasure "scalar") (serialize-qp "ContextFilter" $ContextFilter "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --SeasonType: string
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --GroupQuantity: string
  --GameID: string
  --SeasonType: string
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "GroupQuantity" $GroupQuantity "scalar") (serialize-qp "GameID" $GameID "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --Season: string
  --SeasonType: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --Season: string
  --SeasonType: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --PerMode: string
  --Season: string
  --SeasonType: string
  --TeamID: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --Season: string
  --SeasonType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar")] | flatten | str join "&"
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
  --Season: string
  --TeamID: string
  --LeagueID: string
  --SeasonType: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Season" $Season "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "SeasonType" $SeasonType "scalar")] | flatten | str join "&"
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
  --SeasonType: string
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --SeasonType: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --TeamID: string
  --VsPlayerID: string
  --SeasonType: string
  --MeasureType: string
  --PerMode: string
  --PlusMinus: string
  --PaceAdjust: string
  --Rank: string
  --Season: string
  --Outcome: string
  --Location: string
  --Month: string
  --SeasonSegment: string
  --DateFrom: string
  --DateTo: string
  --OpponentTeamID: string
  --VsConference: string
  --VsDivision: string
  --GameSegment: string
  --Period: string
  --LastNGames: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "TeamID" $TeamID "scalar") (serialize-qp "VsPlayerID" $VsPlayerID "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "MeasureType" $MeasureType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "PlusMinus" $PlusMinus "scalar") (serialize-qp "PaceAdjust" $PaceAdjust "scalar") (serialize-qp "Rank" $Rank "scalar") (serialize-qp "Season" $Season "scalar") (serialize-qp "Outcome" $Outcome "scalar") (serialize-qp "Location" $Location "scalar") (serialize-qp "Month" $Month "scalar") (serialize-qp "SeasonSegment" $SeasonSegment "scalar") (serialize-qp "DateFrom" $DateFrom "scalar") (serialize-qp "DateTo" $DateTo "scalar") (serialize-qp "OpponentTeamID" $OpponentTeamID "scalar") (serialize-qp "VsConference" $VsConference "scalar") (serialize-qp "VsDivision" $VsDivision "scalar") (serialize-qp "GameSegment" $GameSegment "scalar") (serialize-qp "Period" $Period "scalar") (serialize-qp "LastNGames" $LastNGames "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --SeasonType: string
  --PerMode: string
  --TeamID: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "SeasonType" $SeasonType "scalar") (serialize-qp "PerMode" $PerMode "scalar") (serialize-qp "TeamID" $TeamID "scalar")] | flatten | str join "&"
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
  --LeagueID: string
  --GameDate: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "LeagueID" $LeagueID "scalar") (serialize-qp "GameDate" $GameDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/videoStatus" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
