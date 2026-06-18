# Auto-generated client for Stats v1.0
# Source: https://api.apis.guru/v2/specs/haloapi.com/stats/1.0/swagger.json
# Auth: --token flag or $env.STATS_TOKEN

const BASE_URL = "https://www.haloapi.com/stats"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STATS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
    "query-subscription-key" => { {headers: {}, query: $"subscription-key=($token_val)"} }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://www.haloapi.com/stats"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key" "query-subscription-key"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "h5-arena-matches get-halo-5-match-result" } } | get name | first)
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

# Halo 5 - Match Result - Arena
#
# GET /h5/arena/matches/{matchId}
# operationId: Halo-5-Match-Result-Arena
export def "h5-arena-matches get-halo-5-match-result" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/arena/matches/{match_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Match Result - Campaign
#
# GET /h5/campaign/matches/{matchId}
# operationId: Halo-5-Match-Result-Campaign
export def "h5-campaign-matches get-halo-5-match-result" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/campaign/matches/{match_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Company
#
# GET /h5/companies/{companyId}
# operationId: Halo-5-Company
export def "h5-companies get-halo-5-company" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/h5/companies/{company_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Company Commendations
#
# GET /h5/companies/{companyId}/commendations
# operationId: Halo-5-Company-Commendations
export def "h5-companies-commendations get-halo-5-company" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/h5/companies/{company_id}/commendations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Match Result - Custom
#
# GET /h5/custom/matches/{matchId}
# operationId: Halo-5-Match-Result-Custom
export def "h5-custom-matches get-halo-5-match-result" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/custom/matches/{match_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Match Result - Custom Local
#
# GET /h5/customlocal/matches/{matchId}
# operationId: Halo-5-Match-Result-Custom-Local
export def "h5-customlocal-matches get-halo-5-match-result-custom-local" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/customlocal/matches/{match_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Match Events
#
# GET /h5/matches/{matchId}/events
# operationId: Halo-5-Match-Events
export def "h5-matches-events get-halo-5-match" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/matches/{match_id}/events"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Leaderboard - Player CSR
#
# GET /h5/player-leaderboards/csr/{seasonId}/{playlistId}
# operationId: Halo-5-Leaderboard-Player-CSR
export def "h5-player-leaderboards-csr get-halo-5" [
  season_id: string
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 200 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,250], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({season_id: (encode-path-segment $season_id), playlist_id: (encode-path-segment $playlist_id)} | format pattern "/h5/player-leaderboards/csr/{season_id}/{playlist_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Player Commendations
#
# GET /h5/players/{player}/commendations
# operationId: Halo-5-Player-Commendations
export def "h5-players-commendations get-halo-5" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/h5/players/{player}/commendations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Player Match History
#
# GET /h5/players/{player}/matches
# operationId: Halo-5-Player-Match-History
export def "h5-players-matches get-halo-5-match-history" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modes: string # Indicates what Game Mode(s) the client is interested in getting Matches for (arena, campaign, custom, customlocal, or warzone). When the parameter is omitted or empty, Matches from all modes are returned. When a client would like to receive Matches spanning multiple Modes, separate the Modes with a comma (e.g. "arena,custom"). There is no significance to the order the Modes are specified in this parameter. When an invalid Mode is specified, HTTP 400 ("Bad Request") is returned. When a valid Mode is specified more than once, HTTP 400 ("Bad Request") is returned.
  --start: float # When specified, this indicates the starting index (0-based) for which the batch of results will begin at. For example, "start=0" indicates that the first qualifying result will be returned, no items are 'skipped'. Passing "start=10" indicates that the result will begin with the 11th item, the first 10 will be 'skipped'. When omitted, zero is assumed. When the value contains a non-digit, HTTP 400 ("Bad Request") is returned.
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 25 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,25], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
  --include-times: oneof<nothing, bool> # When set to "true", this indicates that the time component of the "MatchCompletedDate" field should be populated. Otherwise, when set to "false" or when omitted, the time component will be set to "00:00:00". When the value contains a non-boolean, HTTP 400 ("Bad Request") is returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modes" $modes "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "include-times" $include_times "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/h5/players/{player}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Player Service Records - Arena
#
# GET /h5/servicerecords/arena
# operationId: Halo-5-Player-Service-Records-Arena
export def "h5-servicerecords-arena get-halo-5-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
  --season-id: string # When specified, this indicates the Season to request the Arena Playlist Stats for. If this is not specified, the default is the current Season. Seasons are available via the Metadata API. Social (Unranked) Arena Playlist Stats can be retrieved by specifying "NonSeasonal".
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar") (serialize-qp "seasonId" $season_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/arena" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Player Service Records - Campaign
#
# GET /h5/servicerecords/campaign
# operationId: Halo-5-Player-Service-Records-Campaign
export def "h5-servicerecords-campaign get-halo-5-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/campaign" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Player Service Records - Custom
#
# GET /h5/servicerecords/custom
# operationId: Halo-5-Player-Service-Records-Custom
export def "h5-servicerecords-custom get-halo-5-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/custom" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Player Service Records - Custom Local
#
# GET /h5/servicerecords/customlocal
# operationId: Halo-5-Player-Service-Records-Custom-Local
export def "h5-servicerecords-customlocal get-halo-5-player-service-records-custom-local" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/customlocal" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Player Service Records - Warzone
#
# GET /h5/servicerecords/warzone
# operationId: Halo-5-Player-Service-Records-Warzone
export def "h5-servicerecords-warzone get-halo-5-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5/servicerecords/warzone" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 - Match Result - Warzone
#
# GET /h5/warzone/matches/{matchId}
# operationId: Halo-5-Match-Result-Warzone
export def "h5-warzone-matches get-halo-5-match-result" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5/warzone/matches/{match_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 PC - Match Result - Custom
#
# GET /h5pc/custom/matches/{matchId}
# operationId: Halo-5-PC-Match-Result-Custom
export def "h5pc-custom-matches get-halo-5-pc-match-result" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/h5pc/custom/matches/{match_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 PC - Player Match History
#
# GET /h5pc/players/{player}/matches
# operationId: Halo-5-PC-Player-Match-History
export def "h5pc-players-matches get-halo-5-pc-match-history" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --modes: string # Indicates what Game Mode(s) the client is interested in getting Matches for (arena, campaign, custom, or warzone). When the parameter is omitted or empty, Matches from all modes are returned. When a client would like to receive Matches spanning multiple Modes, separate the Modes with a comma (e.g. "arena,custom"). There is no significance to the order the Modes are specified in this parameter. When an invalid Mode is specified, HTTP 400 ("Bad Request") is returned. When a valid Mode is specified more than once, HTTP 400 ("Bad Request") is returned.
  --start: float # When specified, this indicates the starting index (0-based) for which the batch of results will begin at. For example, "start=0" indicates that the first qualifying result will be returned, no items are 'skipped'. Passing "start=10" indicates that the result will begin with the 11th item, the first 10 will be 'skipped'. When omitted, zero is assumed. When the value contains a non-digit, HTTP 400 ("Bad Request") is returned.
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 25 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,25], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
  --include-times: oneof<nothing, bool> # When set to "true", this indicates that the time component of the "MatchCompletedDate" field should be populated. Otherwise, when set to "false" or when omitted, the time component will be set to "00:00:00". When the value contains a non-boolean, HTTP 400 ("Bad Request") is returned.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "modes" $modes "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "include-times" $include_times "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/h5pc/players/{player}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo 5 PC - Player Service Records - Custom
#
# GET /h5pc/servicerecords/custom
# operationId: Halo-5-PC-Player-Service-Records-Custom
export def "h5pc-servicerecords-custom get-halo-5-pc-player-service-records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 32 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/h5pc/servicerecords/custom" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Match Result
#
# GET /hw2/matches/{matchId}
# operationId: Halo-Wars-2-Match-Result
export def "hw2-matches get-halo-wars-2-match-result" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/hw2/matches/{match_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Match Events
#
# GET /hw2/matches/{matchId}/events
# operationId: Halo-Wars-2-Match-Events
export def "hw2-matches-events get-halo-wars-2-match" [
  match_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({match_id: (encode-path-segment $match_id)} | format pattern "/hw2/matches/{match_id}/events"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Leaderboard - Player CSR
#
# GET /hw2/player-leaderboards/csr/{seasonId}/{playlistId}
# operationId: Halo-Wars-2-Leaderboard-Player-CSR
export def "hw2-player-leaderboards-csr get-halo-wars-2" [
  season_id: string
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 200 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,250], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({season_id: (encode-path-segment $season_id), playlist_id: (encode-path-segment $playlist_id)} | format pattern "/hw2/player-leaderboards/csr/{season_id}/{playlist_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Player Campaign Progress
#
# GET /hw2/players/{player}/campaign-progress
# operationId: Halo-Wars-2-Player-Campaign-Progress
export def "hw2-players-campaign-progress get-halo-wars-2" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/hw2/players/{player}/campaign-progress"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Player Match History
#
# GET /hw2/players/{player}/matches
# operationId: Halo-Wars-2-Player-Match-History
export def "hw2-players-matches get-halo-wars-2-match-history" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --match-type: string # Indicates what Match Type the client is interested in getting Matches for ("custom" or "matchmaking"). When the parameter is omitted or empty, Matches from all Match Types are returned. When an invalid Mode is specified, HTTP 400 ("Bad Request") is returned.
  --start: float # When specified, this indicates the starting index (0-based) for which the batch of results will begin at. For example, "start=0" indicates that the first qualifying result will be returned, no items are 'skipped'. Passing "start=10" indicates that the result will begin with the 11th item, the first 10 will be 'skipped'. When omitted, zero is assumed. When the value contains a non-digit, HTTP 400 ("Bad Request") is returned.
  --count: float # When specified, this indicates the maximum quantity of items the client would like returned in the response. When omitted, 25 is assumed. When the value contains a non-digit or is exactly "0", HTTP 400 ("Bad Request") is returned. When the value is greater than the allowed range [1,25], the maximum allowed value is used instead. The "Count" field in the response will confirm the actual value that was used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "matchType" $match_type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/hw2/players/{player}/matches") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Player Stats Summary
#
# GET /hw2/players/{player}/stats
# operationId: Halo-Wars-2-Player-Stats-Summary
export def "hw2-players-stats stats-halo-wars-2-summary" [
  player: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player: (encode-path-segment $player)} | format pattern "/hw2/players/{player}/stats"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Player Season Stats Summary
#
# GET /hw2/players/{player}/stats/seasons/{seasonId}
# operationId: Halo-Wars-2-Player-Season-Stats-Summary
export def "hw2-players-stats-seasons stats-halo-wars-2-summary" [
  player: string
  season_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({player: (encode-path-segment $player), season_id: (encode-path-segment $season_id)} | format pattern "/hw2/players/{player}/stats/seasons/{season_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Player Playlist Ratings
#
# GET /hw2/playlist/{playlistId}/rating
# operationId: Halo-Wars-2-Player-Playlist-Ratings
export def "hw2-playlist-rating get-halo-wars-2-player" [
  playlist_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 6 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({playlist_id: (encode-path-segment $playlist_id)} | format pattern "/hw2/playlist/{playlist_id}/rating") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Halo Wars 2 - Player XPs
#
# GET /hw2/xp
# operationId: Halo-Wars-2-Player-XPs
export def "hw2-xp get-halo-wars-2-player-x-ps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --players: string # A comma-separated list of Gamertags. Up to 6 Gamertags may be specified.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "players" $players "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/hw2/xp" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
