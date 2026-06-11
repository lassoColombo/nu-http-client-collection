# Auto-generated client for Riot API vd1c669ee4c91f6502613da66e05c782cdb76693a
# Source: https://mingweisamuel.github.io/riotapi-schema/openapi-3.0.0.json
# Auth: --token flag or $env.RIOT_API_KEY

const BASE_URL = "https://americas.api.riotgames.com"
const DEFAULT_AUTH = "query-api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o RIOT_API_KEY | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api_key" => { {headers: {}, query: $"api_key=($token_val)"} }
    "x-riot-token" => { {headers: {X-Riot-Token: $token_val}, query: ""} }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://americas.api.riotgames.com" "https://asia.api.riotgames.com" "https://europe.api.riotgames.com" "https://br1.api.riotgames.com" "https://eun1.api.riotgames.com" "https://euw1.api.riotgames.com" "https://jp1.api.riotgames.com" "https://kr.api.riotgames.com" "https://la1.api.riotgames.com" "https://la2.api.riotgames.com" "https://me1.api.riotgames.com" "https://na1.api.riotgames.com" "https://oc1.api.riotgames.com" "https://ru.api.riotgames.com" "https://sg2.api.riotgames.com" "https://tr1.api.riotgames.com" "https://tw2.api.riotgames.com" "https://vn2.api.riotgames.com" "https://pbe1.api.riotgames.com" "https://sea.api.riotgames.com" "https://apac.api.riotgames.com" "https://esports.api.riotgames.com" "https://esportseu.api.riotgames.com" "https://ap.api.riotgames.com" "https://br.api.riotgames.com" "https://eu.api.riotgames.com" "https://latam.api.riotgames.com" "https://na.api.riotgames.com"] }
def auth-scheme-completer [] { ["query-api_key" "x-riot-token" "bearer"] }

# Completers for enum parameters
def type-completer [] { ["normal" "ranked" "tourney" "tutorial"] }
def queue-completer [] { ["RANKED_TFT" "RANKED_TFT_DOUBLE_UP"] }
def pickType-completer [] { ["ALL_RANDOM" "BLIND_PICK" "DRAFT_MODE" "TOURNAMENT_DRAFT"] }
def mapType-completer [] { ["HOWLING_ABYSS" "SUMMONERS_RIFT"] }
def spectatorType-completer [] { ["ALL" "LOBBYONLY" "NONE"] }
def region-completer [] { ["BR" "EUNE" "EUW" "JP" "KR" "LAN" "LAS" "NA" "OCE" "PBE" "RU" "TR"] }
def region-completer-1 [] { ["BR" "EUNE" "EUW" "JP" "KR" "LAN" "LAS" "NA" "OCE" "PBE" "PH" "RU" "SG" "TH" "TR" "TW" "VN"] }
def platformType-completer [] { ["playstation" "xbox"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "riot-account-accounts-by-puuid account-v1getByPuuid" } } | get name | first)
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

# Get account by puuid
#
# GET /riot/account/v1/accounts/by-puuid/{puuid}
# Docs: https://developer.riotgames.com/api-methods/#account-v1/GET_getByPuuid — Official API Reference
# operationId: account-v1.getByPuuid
export def "riot-account-accounts-by-puuid account-v1getByPuuid" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, gameName: string, tagLine: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/riot/account/v1/accounts/by-puuid/($puuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account by riot id
#
# GET /riot/account/v1/accounts/by-riot-id/{gameName}/{tagLine}
# Docs: https://developer.riotgames.com/api-methods/#account-v1/GET_getByRiotId — Official API Reference
# operationId: account-v1.getByRiotId
export def "riot-account-accounts-by-riot-id account-v1getByRiotId" [
  tagLine: string
  gameName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, gameName: string, tagLine: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/riot/account/v1/accounts/by-riot-id/($gameName)/($tagLine)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account by access token
#
# GET /riot/account/v1/accounts/me
# Docs: https://developer.riotgames.com/api-methods/#account-v1/GET_getByAccessToken — Official API Reference
# operationId: account-v1.getByAccessToken
export def "riot-account-accounts-me account-v1getByAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, gameName: string, tagLine: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/riot/account/v1/accounts/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get active shard for a player
#
# GET /riot/account/v1/active-shards/by-game/{game}/by-puuid/{puuid}
# Docs: https://developer.riotgames.com/api-methods/#account-v1/GET_getActiveShard — Official API Reference
# operationId: account-v1.getActiveShard
export def "riot-account-active-shards-by-game-by-puuid account-v1getActiveShard" [
  game: string
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, game: string, activeShard: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/riot/account/v1/active-shards/by-game/($game)/by-puuid/($puuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get active region (lol and tft)
#
# GET /riot/account/v1/region/by-game/{game}/by-puuid/{puuid}
# Docs: https://developer.riotgames.com/api-methods/#account-v1/GET_getActiveRegion — Official API Reference
# operationId: account-v1.getActiveRegion
export def "riot-account-region-by-game-by-puuid account-v1getActiveRegion" [
  puuid: string
  game: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, game: string, region: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/riot/account/v1/region/by-game/($game)/by-puuid/($puuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all champion mastery entries sorted by number of champion points descending.
#
# GET /lol/champion-mastery/v4/champion-masteries/by-puuid/{encryptedPUUID}
# Docs: https://developer.riotgames.com/api-methods/#champion-mastery-v4/GET_getAllChampionMasteriesByPUUID — Official API Reference
# operationId: champion-mastery-v4.getAllChampionMasteriesByPUUID
export def "lol-champion-mastery-champion-masteries-by-puuid champion-mastery-v4getAllChampionMasteriesByPUUID" [
  encryptedPUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<puuid: string, championPointsUntilNextLevel: int, chestGranted: bool, championId: int, lastPlayTime: int, championLevel: int, championPoints: int, championPointsSinceLastLevel: int, markRequiredForNextLevel: int, championSeasonMilestone: int, nextSeasonMilestone: record<requireGradeCounts: record, rewardMarks: int, bonus: bool, rewardConfig: record, totalGamesRequires: int>, tokensEarned: int, milestoneGrades: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/champion-mastery/v4/champion-masteries/by-puuid/($encryptedPUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a champion mastery by puuid and champion ID.
#
# GET /lol/champion-mastery/v4/champion-masteries/by-puuid/{encryptedPUUID}/by-champion/{championId}
# Docs: https://developer.riotgames.com/api-methods/#champion-mastery-v4/GET_getChampionMasteryByPUUID — Official API Reference
# operationId: champion-mastery-v4.getChampionMasteryByPUUID
export def "lol-champion-mastery-champion-masteries-by-puuid-by-champion champion-mastery-v4getChampionMasteryByPUUID" [
  encryptedPUUID: string
  championId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, championPointsUntilNextLevel: int, chestGranted: bool, championId: int, lastPlayTime: int, championLevel: int, championPoints: int, championPointsSinceLastLevel: int, markRequiredForNextLevel: int, championSeasonMilestone: int, nextSeasonMilestone: record<requireGradeCounts: record, rewardMarks: int, bonus: bool, rewardConfig: record<rewardValue: string, rewardType: string, maximumReward: int>, totalGamesRequires: int>, tokensEarned: int, milestoneGrades: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/champion-mastery/v4/champion-masteries/by-puuid/($encryptedPUUID)/by-champion/($championId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get specified number of top champion mastery entries sorted by number of champion points descending.
#
# GET /lol/champion-mastery/v4/champion-masteries/by-puuid/{encryptedPUUID}/top
# Docs: https://developer.riotgames.com/api-methods/#champion-mastery-v4/GET_getTopChampionMasteriesByPUUID — Official API Reference
# operationId: champion-mastery-v4.getTopChampionMasteriesByPUUID
export def "lol-champion-mastery-champion-masteries-by-puuid-top champion-mastery-v4getTopChampionMasteriesByPUUID" [
  encryptedPUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Number of entries to retrieve, defaults to 3. (format: int32)
]: nothing -> table<puuid: string, championPointsUntilNextLevel: int, chestGranted: bool, championId: int, lastPlayTime: int, championLevel: int, championPoints: int, championPointsSinceLastLevel: int, markRequiredForNextLevel: int, championSeasonMilestone: int, nextSeasonMilestone: record<requireGradeCounts: record, rewardMarks: int, bonus: bool, rewardConfig: record, totalGamesRequires: int>, tokensEarned: int, milestoneGrades: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lol/champion-mastery/v4/champion-masteries/by-puuid/($encryptedPUUID)/top" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a player's total champion mastery score, which is the sum of individual champion mastery levels.
#
# GET /lol/champion-mastery/v4/scores/by-puuid/{encryptedPUUID}
# Docs: https://developer.riotgames.com/api-methods/#champion-mastery-v4/GET_getChampionMasteryScoreByPUUID — Official API Reference
# operationId: champion-mastery-v4.getChampionMasteryScoreByPUUID
export def "lol-champion-mastery-scores-by-puuid champion-mastery-v4getChampionMasteryScoreByPUUID" [
  encryptedPUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/champion-mastery/v4/scores/by-puuid/($encryptedPUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns champion rotations, including free-to-play and low-level free-to-play rotations (REST)
#
# GET /lol/platform/v3/champion-rotations
# Docs: https://developer.riotgames.com/api-methods/#champion-v3/GET_getChampionInfo — Official API Reference
# operationId: champion-v3.getChampionInfo
export def "lol-platform-champion-rotations champion-v3getChampionInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<maxNewPlayerLevel: int, freeChampionIdsForNewPlayers: list<int>, freeChampionIds: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/platform/v3/champion-rotations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get players by puuid
#
# GET /lol/clash/v1/players/by-puuid/{puuid}
# Docs: https://developer.riotgames.com/api-methods/#clash-v1/GET_getPlayersByPUUID — Official API Reference
# operationId: clash-v1.getPlayersByPUUID
export def "lol-clash-players-by-puuid clash-v1getPlayersByPUUID" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<puuid: string, teamId: string, position: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/clash/v1/players/by-puuid/($puuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get team by ID.
#
# GET /lol/clash/v1/teams/{teamId}
# Docs: https://developer.riotgames.com/api-methods/#clash-v1/GET_getTeamById — Official API Reference
# operationId: clash-v1.getTeamById
export def "lol-clash-teams clash-v1getTeamById" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, tournamentId: int, name: string, iconId: int, tier: int, captain: string, abbreviation: string, players: table<puuid: string, teamId: string, position: string, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/clash/v1/teams/($teamId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all active or upcoming tournaments.
#
# GET /lol/clash/v1/tournaments
# Docs: https://developer.riotgames.com/api-methods/#clash-v1/GET_getTournaments — Official API Reference
# operationId: clash-v1.getTournaments
export def "lol-clash-tournaments clash-v1getTournaments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, themeId: int, nameKey: string, nameKeySecondary: string, schedule: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/clash/v1/tournaments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tournament by team ID.
#
# GET /lol/clash/v1/tournaments/by-team/{teamId}
# Docs: https://developer.riotgames.com/api-methods/#clash-v1/GET_getTournamentByTeam — Official API Reference
# operationId: clash-v1.getTournamentByTeam
export def "lol-clash-tournaments-by-team clash-v1getTournamentByTeam" [
  teamId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, themeId: int, nameKey: string, nameKeySecondary: string, schedule: table<id: int, registrationTime: int, startTime: int, cancelled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/clash/v1/tournaments/by-team/($teamId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get tournament by ID.
#
# GET /lol/clash/v1/tournaments/{tournamentId}
# Docs: https://developer.riotgames.com/api-methods/#clash-v1/GET_getTournamentById — Official API Reference
# operationId: clash-v1.getTournamentById
export def "lol-clash-tournaments clash-v1getTournamentById" [
  tournamentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, themeId: int, nameKey: string, nameKeySecondary: string, schedule: table<id: int, registrationTime: int, startTime: int, cancelled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/clash/v1/tournaments/($tournamentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the league entries.
#
# GET /lol/league-exp/v4/entries/{queue}/{tier}/{division}
# Docs: https://developer.riotgames.com/api-methods/#league-exp-v4/GET_getLeagueEntries — Official API Reference
# operationId: league-exp-v4.getLeagueEntries
export def "lol-league-exp-entries league-exp-v4getLeagueEntries" [
  queue: string
  tier: string
  division: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Defaults to 1. Starts with page 1. (format: int32)
]: nothing -> table<leagueId: string, summonerId: string, puuid: string, queueType: string, tier: string, rank: string, leaguePoints: int, wins: int, losses: int, hotStreak: bool, veteran: bool, freshBlood: bool, inactive: bool, miniSeries: record<losses: int, progress: string, target: int, wins: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lol/league-exp/v4/entries/($queue)/($tier)/($division)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the challenger league for given queue.
#
# GET /lol/league/v4/challengerleagues/by-queue/{queue}
# Docs: https://developer.riotgames.com/api-methods/#league-v4/GET_getChallengerLeague — Official API Reference
# operationId: league-v4.getChallengerLeague
export def "lol-league-challengerleagues-by-queue league-v4getChallengerLeague" [
  queue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<leagueId: string, entries: table<freshBlood: bool, wins: int, miniSeries: record, inactive: bool, veteran: bool, hotStreak: bool, rank: string, leaguePoints: int, losses: int, puuid: string, summonerId: string>, tier: string, name: string, queue: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/league/v4/challengerleagues/by-queue/($queue)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get league entries in all queues for a given puuid
#
# GET /lol/league/v4/entries/by-puuid/{encryptedPUUID}
# Docs: https://developer.riotgames.com/api-methods/#league-v4/GET_getLeagueEntriesByPUUID — Official API Reference
# operationId: league-v4.getLeagueEntriesByPUUID
export def "lol-league-entries-by-puuid league-v4getLeagueEntriesByPUUID" [
  encryptedPUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<leagueId: string, puuid: string, queueType: string, tier: string, rank: string, leaguePoints: int, wins: int, losses: int, hotStreak: bool, veteran: bool, freshBlood: bool, inactive: bool, miniSeries: record<losses: int, progress: string, target: int, wins: int>, summonerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/league/v4/entries/by-puuid/($encryptedPUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the league entries.
#
# GET /lol/league/v4/entries/{queue}/{tier}/{division}
# Docs: https://developer.riotgames.com/api-methods/#league-v4/GET_getLeagueEntries — Official API Reference
# operationId: league-v4.getLeagueEntries
export def "lol-league-entries league-v4getLeagueEntries" [
  division: string
  tier: string
  queue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Defaults to 1. Starts with page 1. (format: int32)
]: nothing -> table<leagueId: string, puuid: string, queueType: string, tier: string, rank: string, leaguePoints: int, wins: int, losses: int, hotStreak: bool, veteran: bool, freshBlood: bool, inactive: bool, miniSeries: record<losses: int, progress: string, target: int, wins: int>, summonerId: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lol/league/v4/entries/($queue)/($tier)/($division)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the grandmaster league of a specific queue.
#
# GET /lol/league/v4/grandmasterleagues/by-queue/{queue}
# Docs: https://developer.riotgames.com/api-methods/#league-v4/GET_getGrandmasterLeague — Official API Reference
# operationId: league-v4.getGrandmasterLeague
export def "lol-league-grandmasterleagues-by-queue league-v4getGrandmasterLeague" [
  queue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<leagueId: string, entries: table<freshBlood: bool, wins: int, miniSeries: record, inactive: bool, veteran: bool, hotStreak: bool, rank: string, leaguePoints: int, losses: int, puuid: string, summonerId: string>, tier: string, name: string, queue: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/league/v4/grandmasterleagues/by-queue/($queue)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the master league for given queue.
#
# GET /lol/league/v4/masterleagues/by-queue/{queue}
# Docs: https://developer.riotgames.com/api-methods/#league-v4/GET_getMasterLeague — Official API Reference
# operationId: league-v4.getMasterLeague
export def "lol-league-masterleagues-by-queue league-v4getMasterLeague" [
  queue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<leagueId: string, entries: table<freshBlood: bool, wins: int, miniSeries: record, inactive: bool, veteran: bool, hotStreak: bool, rank: string, leaguePoints: int, losses: int, puuid: string, summonerId: string>, tier: string, name: string, queue: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/league/v4/masterleagues/by-queue/($queue)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List of all basic challenge configuration information (includes all translations for names and descriptions)
#
# GET /lol/challenges/v1/challenges/config
# Docs: https://developer.riotgames.com/api-methods/#lol-challenges-v1/GET_getAllChallengeConfigs — Official API Reference
# operationId: lol-challenges-v1.getAllChallengeConfigs
export def "lol-challenges-challenges-config lol-challenges-v1getAllChallengeConfigs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, localizedNames: record, state: string, tracking: string, startTimestamp: int, endTimestamp: int, leaderboard: bool, thresholds: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/challenges/v1/challenges/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Map of level to percentile of players who have achieved it - keys: ChallengeId -> Season -> Level -> percentile of players who achieved it
#
# GET /lol/challenges/v1/challenges/percentiles
# Docs: https://developer.riotgames.com/api-methods/#lol-challenges-v1/GET_getAllChallengePercentiles — Official API Reference
# operationId: lol-challenges-v1.getAllChallengePercentiles
export def "lol-challenges-challenges-percentiles lol-challenges-v1getAllChallengePercentiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/challenges/v1/challenges/percentiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get challenge configuration (REST)
#
# GET /lol/challenges/v1/challenges/{challengeId}/config
# Docs: https://developer.riotgames.com/api-methods/#lol-challenges-v1/GET_getChallengeConfigs — Official API Reference
# operationId: lol-challenges-v1.getChallengeConfigs
export def "lol-challenges-challenges-config lol-challenges-v1getChallengeConfigs" [
  challengeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, localizedNames: record, state: string, tracking: string, startTimestamp: int, endTimestamp: int, leaderboard: bool, thresholds: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/challenges/v1/challenges/($challengeId)/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return top players for each level. Level must be MASTER, GRANDMASTER or CHALLENGER.
#
# GET /lol/challenges/v1/challenges/{challengeId}/leaderboards/by-level/{level}
# Docs: https://developer.riotgames.com/api-methods/#lol-challenges-v1/GET_getChallengeLeaderboards — Official API Reference
# operationId: lol-challenges-v1.getChallengeLeaderboards
export def "lol-challenges-challenges-leaderboards-by-level lol-challenges-v1getChallengeLeaderboards" [
  level: string
  challengeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # format: int32
]: nothing -> table<puuid: string, value: float, position: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lol/challenges/v1/challenges/($challengeId)/leaderboards/by-level/($level)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Map of level to percentile of players who have achieved it
#
# GET /lol/challenges/v1/challenges/{challengeId}/percentiles
# Docs: https://developer.riotgames.com/api-methods/#lol-challenges-v1/GET_getChallengePercentiles — Official API Reference
# operationId: lol-challenges-v1.getChallengePercentiles
export def "lol-challenges-challenges-percentiles lol-challenges-v1getChallengePercentiles" [
  challengeId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/challenges/v1/challenges/($challengeId)/percentiles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns player information with list of all progressed challenges (REST)
#
# GET /lol/challenges/v1/player-data/{puuid}
# Docs: https://developer.riotgames.com/api-methods/#lol-challenges-v1/GET_getPlayerData — Official API Reference
# operationId: lol-challenges-v1.getPlayerData
export def "lol-challenges-player-data lol-challenges-v1getPlayerData" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<challenges: table<percentile: float, playersInLevel: int, achievedTime: int, value: float, challengeId: int, level: string, position: int>, preferences: record<bannerAccent: string, title: string, challengeIds: list<int>, crestBorder: string, prestigeCrestBorderLevel: int>, totalPoints: record<level: string, current: int, max: int, percentile: float, position: int>, categoryPoints: record> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/challenges/v1/player-data/($puuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of match ids by player access token - Includes custom matches
#
# GET /lol/rso-match/v1/matches/ids
# Docs: https://developer.riotgames.com/api-methods/#lol-rso-match-v1/GET_getMatchIds — Official API Reference
# operationId: lol-rso-match-v1.getMatchIds
export def "lol-rso-match-matches-ids lol-rso-match-v1getMatchIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # Defaults to 20. Valid values: 0 to 100. Number of match ids to return. (format: int32)
  --start: int # Defaults to 0. Start index. (format: int32)
  --type: string@type-completer # Filter the list of match ids by the type of match. This filter is mutually inclusive of the queue filter meaning any match ids returned must match both the queue and type filters.
  --queue: int # Filter the list of match ids by a specific queue id. This filter is mutually inclusive of the type filter meaning any match ids returned must match both the queue and type filters. (format: int32)
  --endTime: int # Epoch timestamp in seconds. (format: int64)
  --startTime: int # Epoch timestamp in seconds. The matchlist started storing timestamps on June 16th, 2021. Any matches played before June 16th, 2021 won't be included in the results if the startTime filter is set. (format: int64)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "queue" $queue "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "startTime" $startTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lol/rso-match/v1/matches/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a match by match id
#
# GET /lol/rso-match/v1/matches/{matchId}
# Docs: https://developer.riotgames.com/api-methods/#lol-rso-match-v1/GET_getMatch — Official API Reference
# operationId: lol-rso-match-v1.getMatch
export def "lol-rso-match-matches lol-rso-match-v1getMatch" [
  matchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record<dataVersion: string, matchId: string, participants: list<string>>, info: record<endOfGameResult: string, gameCreation: int, gameDuration: int, gameEndTimestamp: int, gameId: int, gameMode: string, gameName: string, gameStartTimestamp: int, gameType: string, gameVersion: string, mapId: int, participants: list<record>, platformId: string, queueId: int, teams: list<record>, tournamentCode: string, gameModeMutators: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/rso-match/v1/matches/($matchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a match timeline by match id
#
# GET /lol/rso-match/v1/matches/{matchId}/timeline
# Docs: https://developer.riotgames.com/api-methods/#lol-rso-match-v1/GET_getTimeline — Official API Reference
# operationId: lol-rso-match-v1.getTimeline
export def "lol-rso-match-matches-timeline lol-rso-match-v1getTimeline" [
  matchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record<dataVersion: string, matchId: string, participants: list<string>>, info: record<endOfGameResult: string, frameInterval: int, gameId: int, participants: list<record>, frames: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/rso-match/v1/matches/($matchId)/timeline")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get League of Legends status for the given platform.
#
# GET /lol/status/v4/platform-data
# Docs: https://developer.riotgames.com/api-methods/#lol-status-v4/GET_getPlatformData — Official API Reference
# operationId: lol-status-v4.getPlatformData
export def "lol-status-platform-data lol-status-v4getPlatformData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, locales: list<string>, maintenances: table<id: int, maintenance_status: string, incident_severity: string, titles: list, updates: list, created_at: string, archive_at: string, updated_at: string, platforms: list>, incidents: table<id: int, maintenance_status: string, incident_severity: string, titles: list, updates: list, created_at: string, archive_at: string, updated_at: string, platforms: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/status/v4/platform-data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of the calling user's decks.
#
# GET /lor/deck/v1/decks/me
# Docs: https://developer.riotgames.com/api-methods/#lor-deck-v1/GET_getDecks — Official API Reference
# operationId: lor-deck-v1.getDecks
export def "lor-deck-decks-me lor-deck-v1getDecks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lor/deck/v1/decks/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new deck for the calling user.
#
# POST /lor/deck/v1/decks/me
# Docs: https://developer.riotgames.com/api-methods/#lor-deck-v1/POST_createDeck — Official API Reference
# operationId: lor-deck-v1.createDeck
export def "lor-deck-decks-me lor-deck-v1createDeck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  code: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lor/deck/v1/decks/me")
  let body = {name: $name, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Return a list of cards owned by the calling user.
#
# GET /lor/inventory/v1/cards/me
# Docs: https://developer.riotgames.com/api-methods/#lor-inventory-v1/GET_getCards — Official API Reference
# operationId: lor-inventory-v1.getCards
export def "lor-inventory-cards-me lor-inventory-v1getCards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<code: string, count: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lor/inventory/v1/cards/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of match ids by PUUID
#
# GET /lor/match/v1/matches/by-puuid/{puuid}/ids
# Docs: https://developer.riotgames.com/api-methods/#lor-match-v1/GET_getMatchIdsByPUUID — Official API Reference
# operationId: lor-match-v1.getMatchIdsByPUUID
export def "lor-match-matches-by-puuid-ids lor-match-v1getMatchIdsByPUUID" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lor/match/v1/matches/by-puuid/($puuid)/ids")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get match by id
#
# GET /lor/match/v1/matches/{matchId}
# Docs: https://developer.riotgames.com/api-methods/#lor-match-v1/GET_getMatch — Official API Reference
# operationId: lor-match-v1.getMatch
export def "lor-match-matches lor-match-v1getMatch" [
  matchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record<data_version: string, match_id: string, participants: list<string>>, info: record<game_mode: string, game_type: string, game_start_time_utc: string, game_version: string, game_format: string, players: list<record>, total_turn_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lor/match/v1/matches/($matchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the players in Master tier.
#
# GET /lor/ranked/v1/leaderboards
# Docs: https://developer.riotgames.com/api-methods/#lor-ranked-v1/GET_getLeaderboards — Official API Reference
# operationId: lor-ranked-v1.getLeaderboards
export def "lor-ranked-leaderboards lor-ranked-v1getLeaderboards" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<players: table<name: string, rank: int, lp: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lor/ranked/v1/leaderboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Legends of Runeterra status for the given platform.
#
# GET /lor/status/v1/platform-data
# Docs: https://developer.riotgames.com/api-methods/#lor-status-v1/GET_getPlatformData — Official API Reference
# operationId: lor-status-v1.getPlatformData
export def "lor-status-platform-data lor-status-v1getPlatformData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, locales: list<string>, maintenances: table<id: int, maintenance_status: string, incident_severity: string, titles: list, updates: list, created_at: string, archive_at: string, updated_at: string, platforms: list>, incidents: table<id: int, maintenance_status: string, incident_severity: string, titles: list, updates: list, created_at: string, archive_at: string, updated_at: string, platforms: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lor/status/v1/platform-data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of match ids by puuid
#
# GET /lol/match/v5/matches/by-puuid/{puuid}/ids
# Docs: https://developer.riotgames.com/api-methods/#match-v5/GET_getMatchIdsByPUUID — Official API Reference
# operationId: match-v5.getMatchIdsByPUUID
export def "lol-match-matches-by-puuid-ids match-v5getMatchIdsByPUUID" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: int # Epoch timestamp in seconds. The matchlist started storing timestamps on June 16th, 2021. Any matches played before June 16th, 2021 won't be included in the results if the startTime filter is set. (format: int64)
  --endTime: int # Epoch timestamp in seconds. (format: int64)
  --queue: int # Filter the list of match ids by a specific queue id. This filter is mutually inclusive of the type filter meaning any match ids returned must match both the queue and type filters. (format: int32)
  --type: string@type-completer # Filter the list of match ids by the type of match. This filter is mutually inclusive of the queue filter meaning any match ids returned must match both the queue and type filters.
  --start: int # Defaults to 0. Start index. (format: int32)
  --count: int # Defaults to 20. Valid values: 0 to 100. Number of match ids to return. (format: int32)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "queue" $queue "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lol/match/v5/matches/by-puuid/($puuid)/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get player replays
#
# GET /lol/match/v5/matches/by-puuid/{puuid}/replays
# Docs: https://developer.riotgames.com/api-methods/#match-v5/GET_getReplay — Official API Reference
# operationId: match-v5.getReplay
export def "lol-match-matches-by-puuid-replays match-v5getReplay" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total: int, matchFileURLs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/match/v5/matches/by-puuid/($puuid)/replays")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a match by match id
#
# GET /lol/match/v5/matches/{matchId}
# Docs: https://developer.riotgames.com/api-methods/#match-v5/GET_getMatch — Official API Reference
# operationId: match-v5.getMatch
export def "lol-match-matches match-v5getMatch" [
  matchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record<dataVersion: string, matchId: string, participants: list<string>>, info: record<endOfGameResult: string, gameCreation: int, gameDuration: int, gameEndTimestamp: int, gameId: int, gameMode: string, gameName: string, gameStartTimestamp: int, gameType: string, gameVersion: string, mapId: int, participants: list<record>, platformId: string, queueId: int, teams: list<record>, tournamentCode: string, gameModeMutators: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/match/v5/matches/($matchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a match timeline by match id
#
# GET /lol/match/v5/matches/{matchId}/timeline
# Docs: https://developer.riotgames.com/api-methods/#match-v5/GET_getTimeline — Official API Reference
# operationId: match-v5.getTimeline
export def "lol-match-matches-timeline match-v5getTimeline" [
  matchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record<dataVersion: string, matchId: string, participants: list<string>>, info: record<endOfGameResult: string, frameInterval: int, gameId: int, participants: list<record>, frames: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/match/v5/matches/($matchId)/timeline")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get riftbound content
#
# GET /riftbound/content/v1/contents
# Docs: https://developer.riotgames.com/api-methods/#riftbound-content-v1/GET_getContent — Official API Reference
# operationId: riftbound-content-v1.getContent
export def "riftbound-content-contents riftbound-content-v1getContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Defaults to en. Optional. Specifies the language and regional settings for the response. Use a locale code. During beta only en available.
]: nothing -> record<game: string, version: string, lastUpdated: string, sets: table<id: string, name: string, cards: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/riftbound/content/v1/contents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current game information for the given puuid.
#
# GET /lol/spectator/tft/v5/active-games/by-puuid/{encryptedPUUID}
# Docs: https://developer.riotgames.com/api-methods/#spectator-tft-v5/GET_getCurrentGameInfoByPuuid — Official API Reference
# operationId: spectator-tft-v5.getCurrentGameInfoByPuuid
export def "lol-spectator-tft-active-games-by-puuid spectator-tft-v5getCurrentGameInfoByPuuid" [
  encryptedPUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<gameId: int, gameType: string, gameStartTime: int, mapId: int, gameLength: int, platformId: string, gameMode: string, bannedChampions: table<pickTurn: int, championId: int, teamId: int>, gameQueueConfigId: int, observers: record<encryptionKey: string>, participants: table<championId: int, perks: record, profileIconId: int, teamId: int, puuid: string, spell1Id: int, spell2Id: int, gameCustomizationObjects: list, riotId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/spectator/tft/v5/active-games/by-puuid/($encryptedPUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get current game information for the given puuid.
#
# GET /lol/spectator/v5/active-games/by-summoner/{encryptedPUUID}
# Docs: https://developer.riotgames.com/api-methods/#spectator-v5/GET_getCurrentGameInfoByPuuid — Official API Reference
# operationId: spectator-v5.getCurrentGameInfoByPuuid
export def "lol-spectator-active-games-by-summoner spectator-v5getCurrentGameInfoByPuuid" [
  encryptedPUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<gameId: int, gameType: string, gameStartTime: int, mapId: int, gameLength: int, platformId: string, gameMode: string, bannedChampions: table<pickTurn: int, championId: int, teamId: int>, gameQueueConfigId: int, observers: record<encryptionKey: string>, participants: table<championId: int, perks: record, profileIconId: int, bot: bool, teamId: int, puuid: string, spell1Id: int, spell2Id: int, gameCustomizationObjects: list, riotId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/spectator/v5/active-games/by-summoner/($encryptedPUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a summoner by PUUID.
#
# GET /lol/summoner/v4/summoners/by-puuid/{encryptedPUUID}
# Docs: https://developer.riotgames.com/api-methods/#summoner-v4/GET_getByPUUID — Official API Reference
# operationId: summoner-v4.getByPUUID
export def "lol-summoner-summoners-by-puuid summoner-v4getByPUUID" [
  encryptedPUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<profileIconId: int, revisionDate: int, puuid: string, summonerLevel: int, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/summoner/v4/summoners/by-puuid/($encryptedPUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a summoner by access token.
#
# GET /lol/summoner/v4/summoners/me
# Docs: https://developer.riotgames.com/api-methods/#summoner-v4/GET_getByAccessToken — Official API Reference
# operationId: summoner-v4.getByAccessToken
export def "lol-summoner-summoners-me summoner-v4getByAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<profileIconId: int, revisionDate: int, puuid: string, summonerLevel: int, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/summoner/v4/summoners/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get league entries in all queues for a given puuid
#
# GET /tft/league/v1/by-puuid/{puuid}
# Docs: https://developer.riotgames.com/api-methods/#tft-league-v1/GET_getLeagueEntriesByPUUID — Official API Reference
# operationId: tft-league-v1.getLeagueEntriesByPUUID
export def "tft-league-by-puuid tft-league-v1getLeagueEntriesByPUUID" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<puuid: string, leagueId: string, queueType: string, ratedTier: string, ratedRating: int, tier: string, rank: string, leaguePoints: int, wins: int, losses: int, hotStreak: bool, veteran: bool, freshBlood: bool, inactive: bool, miniSeries: record<losses: int, progress: string, target: int, wins: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tft/league/v1/by-puuid/($puuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the challenger league.
#
# GET /tft/league/v1/challenger
# Docs: https://developer.riotgames.com/api-methods/#tft-league-v1/GET_getChallengerLeague — Official API Reference
# operationId: tft-league-v1.getChallengerLeague
export def "tft-league-challenger tft-league-v1getChallengerLeague" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --queue: string@queue-completer # Defaults to RANKED_TFT.
]: nothing -> record<leagueId: string, entries: table<freshBlood: bool, wins: int, miniSeries: record, inactive: bool, veteran: bool, hotStreak: bool, rank: string, leaguePoints: int, losses: int, puuid: string>, tier: string, name: string, queue: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queue" $queue "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tft/league/v1/challenger" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all the league entries.
#
# GET /tft/league/v1/entries/{tier}/{division}
# Docs: https://developer.riotgames.com/api-methods/#tft-league-v1/GET_getLeagueEntries — Official API Reference
# operationId: tft-league-v1.getLeagueEntries
export def "tft-league-entries tft-league-v1getLeagueEntries" [
  tier: string
  division: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --queue: string@queue-completer # Defaults to RANKED_TFT.
  --page: int # Defaults to 1. Starts with page 1. (format: int32)
]: nothing -> table<puuid: string, leagueId: string, queueType: string, ratedTier: string, ratedRating: int, tier: string, rank: string, leaguePoints: int, wins: int, losses: int, hotStreak: bool, veteran: bool, freshBlood: bool, inactive: bool, miniSeries: record<losses: int, progress: string, target: int, wins: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queue" $queue "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tft/league/v1/entries/($tier)/($division)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the grandmaster league.
#
# GET /tft/league/v1/grandmaster
# Docs: https://developer.riotgames.com/api-methods/#tft-league-v1/GET_getGrandmasterLeague — Official API Reference
# operationId: tft-league-v1.getGrandmasterLeague
export def "tft-league-grandmaster tft-league-v1getGrandmasterLeague" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --queue: string@queue-completer # Defaults to RANKED_TFT.
]: nothing -> record<leagueId: string, entries: table<freshBlood: bool, wins: int, miniSeries: record, inactive: bool, veteran: bool, hotStreak: bool, rank: string, leaguePoints: int, losses: int, puuid: string>, tier: string, name: string, queue: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queue" $queue "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tft/league/v1/grandmaster" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the master league.
#
# GET /tft/league/v1/master
# Docs: https://developer.riotgames.com/api-methods/#tft-league-v1/GET_getMasterLeague — Official API Reference
# operationId: tft-league-v1.getMasterLeague
export def "tft-league-master tft-league-v1getMasterLeague" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --queue: string@queue-completer # Defaults to RANKED_TFT.
]: nothing -> record<leagueId: string, entries: table<freshBlood: bool, wins: int, miniSeries: record, inactive: bool, veteran: bool, hotStreak: bool, rank: string, leaguePoints: int, losses: int, puuid: string>, tier: string, name: string, queue: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "queue" $queue "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/tft/league/v1/master" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the top rated ladder for given queue
#
# GET /tft/league/v1/rated-ladders/{queue}/top
# Docs: https://developer.riotgames.com/api-methods/#tft-league-v1/GET_getTopRatedLadder — Official API Reference
# operationId: tft-league-v1.getTopRatedLadder
export def "tft-league-rated-ladders-top tft-league-v1getTopRatedLadder" [
  queue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<puuid: string, ratedTier: string, ratedRating: int, wins: int, previousUpdateLadderPosition: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tft/league/v1/rated-ladders/($queue)/top")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of match ids by PUUID
#
# GET /tft/match/v1/matches/by-puuid/{puuid}/ids
# Docs: https://developer.riotgames.com/api-methods/#tft-match-v1/GET_getMatchIdsByPUUID — Official API Reference
# operationId: tft-match-v1.getMatchIdsByPUUID
export def "tft-match-matches-by-puuid-ids tft-match-v1getMatchIdsByPUUID" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # Defaults to 0. Start index. (format: int32)
  --endTime: int # Epoch timestamp in seconds. (format: int64)
  --startTime: int # Epoch timestamp in seconds. The matchlist started storing timestamps on June 16th, 2021. Any matches played before June 16th, 2021 won't be included in the results if the startTime filter is set. (format: int64)
  --count: int # Defaults to 20. Number of match ids to return. (format: int32)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "startTime" $startTime "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/tft/match/v1/matches/by-puuid/($puuid)/ids" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a match by match id
#
# GET /tft/match/v1/matches/{matchId}
# Docs: https://developer.riotgames.com/api-methods/#tft-match-v1/GET_getMatch — Official API Reference
# operationId: tft-match-v1.getMatch
export def "tft-match-matches tft-match-v1getMatch" [
  matchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metadata: record<data_version: string, match_id: string, participants: list<string>>, info: record<endOfGameResult: string, gameCreation: int, gameId: int, game_datetime: int, game_length: float, game_version: string, game_variation: string, mapId: int, participants: list<record>, queue_id: int, queueId: int, tft_game_type: string, tft_set_core_name: string, tft_set_number: int>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tft/match/v1/matches/($matchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Teamfight Tactics status for the given platform.
#
# GET /tft/status/v1/platform-data
# Docs: https://developer.riotgames.com/api-methods/#tft-status-v1/GET_getPlatformData — Official API Reference
# operationId: tft-status-v1.getPlatformData
export def "tft-status-platform-data tft-status-v1getPlatformData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, locales: list<string>, maintenances: table<id: int, maintenance_status: string, incident_severity: string, titles: list, updates: list, created_at: string, archive_at: string, updated_at: string, platforms: list>, incidents: table<id: int, maintenance_status: string, incident_severity: string, titles: list, updates: list, created_at: string, archive_at: string, updated_at: string, platforms: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tft/status/v1/platform-data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a summoner by PUUID.
#
# GET /tft/summoner/v1/summoners/by-puuid/{encryptedPUUID}
# Docs: https://developer.riotgames.com/api-methods/#tft-summoner-v1/GET_getByPUUID — Official API Reference
# operationId: tft-summoner-v1.getByPUUID
export def "tft-summoner-summoners-by-puuid tft-summoner-v1getByPUUID" [
  encryptedPUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, profileIconId: int, revisionDate: int, summonerLevel: int, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/tft/summoner/v1/summoners/by-puuid/($encryptedPUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a summoner by access token.
#
# GET /tft/summoner/v1/summoners/me
# Docs: https://developer.riotgames.com/api-methods/#tft-summoner-v1/GET_getByAccessToken — Official API Reference
# operationId: tft-summoner-v1.getByAccessToken
export def "tft-summoner-summoners-me tft-summoner-v1getByAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, profileIconId: int, revisionDate: int, summonerLevel: int, id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/tft/summoner/v1/summoners/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a tournament code for the given tournament - Stub method
#
# POST /lol/tournament-stub/v5/codes
# Docs: https://developer.riotgames.com/api-methods/#tournament-stub-v5/POST_createTournamentCode — Official API Reference
# operationId: tournament-stub-v5.createTournamentCode
export def "lol-tournament-stub-codes tournament-stub-v5createTournamentCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --count: int # The number of codes to create (max 1000) (format: int32)
  --tournamentId: int # The tournament ID (format: int64)
  --allowedParticipants: list # Optional list of encrypted puuids in order to validate the players eligible to join the lobby. NOTE: We currently do not enforce participants at the team level, but rather the aggregate of teamOne and teamTwo. We may add the ability to enforce at the team level in the future.
  --metadata: string # Optional string that may contain any data in any format, if specified at all. Used to denote any custom information about the game.
  teamSize: int # The team size of the game. Valid values are 1-5. (format: int32)
  pickType: string@pickType-completer # The pick type of the game.              (Legal values:  BLIND_PICK,  DRAFT_MODE,  ALL_RANDOM,  TOURNAMENT_DRAFT)
  mapType: string@mapType-completer # The map type of the game.              (Legal values:  SUMMONERS_RIFT,  HOWLING_ABYSS)
  spectatorType: string@spectatorType-completer # The spectator type of the game.              (Legal values:  NONE,  LOBBYONLY,  ALL)
  --enoughPlayers: string@bool-completer # Checks if allowed participants are enough to make full teams.
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "tournamentId" $tournamentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lol/tournament-stub/v5/codes" $qp)
  let body = {allowedParticipants: $allowedParticipants, metadata: $metadata, teamSize: $teamSize, pickType: $pickType, mapType: $mapType, spectatorType: $spectatorType, enoughPlayers: $enoughPlayers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the tournament code DTO associated with a tournament code string - Stub Method
#
# GET /lol/tournament-stub/v5/codes/{tournamentCode}
# Docs: https://developer.riotgames.com/api-methods/#tournament-stub-v5/GET_getTournamentCode — Official API Reference
# operationId: tournament-stub-v5.getTournamentCode
export def "lol-tournament-stub-codes tournament-stub-v5getTournamentCode" [
  tournamentCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, lobbyName: string, metaData: string, password: string, teamSize: int, providerId: int, pickType: string, tournamentId: int, id: int, region: string, map: string, participants: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/tournament-stub/v5/codes/($tournamentCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of lobby events by tournament code - Stub method
#
# GET /lol/tournament-stub/v5/lobby-events/by-code/{tournamentCode}
# Docs: https://developer.riotgames.com/api-methods/#tournament-stub-v5/GET_getLobbyEventsByCode — Official API Reference
# operationId: tournament-stub-v5.getLobbyEventsByCode
export def "lol-tournament-stub-lobby-events-by-code tournament-stub-v5getLobbyEventsByCode" [
  tournamentCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<eventList: table<timestamp: string, eventType: string, puuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/tournament-stub/v5/lobby-events/by-code/($tournamentCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a tournament provider and returns its ID - Stub method
#
# POST /lol/tournament-stub/v5/providers
# Docs: https://developer.riotgames.com/api-methods/#tournament-stub-v5/POST_registerProviderData — Official API Reference
# operationId: tournament-stub-v5.registerProviderData
export def "lol-tournament-stub-providers tournament-stub-v5registerProviderData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  region: string@region-completer # The region in which the provider will be running tournaments.              (Legal values:  BR,  EUNE,  EUW,  JP,  LAN,  LAS,  NA,  OCE,  PBE,  RU,  TR,  KR)
  --body-url: string # The provider's callback URL to which tournament game results in this region should be posted. The URL must be well-formed, use the http or https protocol, and use the default port for the protocol (http URLs must use port 80, https URLs must use port 443).
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/tournament-stub/v5/providers")
  let body = {region: $region, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a tournament and returns its ID - Stub method
#
# POST /lol/tournament-stub/v5/tournaments
# Docs: https://developer.riotgames.com/api-methods/#tournament-stub-v5/POST_registerTournament — Official API Reference
# operationId: tournament-stub-v5.registerTournament
export def "lol-tournament-stub-tournaments tournament-stub-v5registerTournament" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  providerId: int # The provider ID to specify the regional registered provider data to associate this tournament. (format: int32)
  --name: string # The optional name of the tournament.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/tournament-stub/v5/tournaments")
  let body = {providerId: $providerId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a tournament code for the given tournament.
#
# POST /lol/tournament/v5/codes
# Docs: https://developer.riotgames.com/api-methods/#tournament-v5/POST_createTournamentCode — Official API Reference
# operationId: tournament-v5.createTournamentCode
export def "lol-tournament-codes tournament-v5createTournamentCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tournamentId: int # The tournament ID (format: int64)
  --count: int # The number of codes to create (max 1000) (format: int32)
  --allowedParticipants: list # Optional list of encrypted puuids in order to validate the players eligible to join the lobby. NOTE: We currently do not enforce participants at the team level, but rather the aggregate of teamOne and teamTwo. We may add the ability to enforce at the team level in the future.
  --metadata: string # Optional string that may contain any data in any format, if specified at all. Used to denote any custom information about the game.
  teamSize: int # The team size of the game. Valid values are 1-5. (format: int32)
  pickType: string@pickType-completer # The pick type of the game.              (Legal values:  BLIND_PICK,  DRAFT_MODE,  ALL_RANDOM,  TOURNAMENT_DRAFT)
  mapType: string@mapType-completer # The map type of the game.              (Legal values:  SUMMONERS_RIFT,  HOWLING_ABYSS)
  spectatorType: string@spectatorType-completer # The spectator type of the game.              (Legal values:  NONE,  LOBBYONLY,  ALL)
  --enoughPlayers: string@bool-completer # Checks if allowed participants are enough to make full teams.
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tournamentId" $tournamentId "scalar") (serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/lol/tournament/v5/codes" $qp)
  let body = {allowedParticipants: $allowedParticipants, metadata: $metadata, teamSize: $teamSize, pickType: $pickType, mapType: $mapType, spectatorType: $spectatorType, enoughPlayers: $enoughPlayers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns the tournament code DTO associated with a tournament code string.
#
# GET /lol/tournament/v5/codes/{tournamentCode}
# Docs: https://developer.riotgames.com/api-methods/#tournament-v5/GET_getTournamentCode — Official API Reference
# operationId: tournament-v5.getTournamentCode
export def "lol-tournament-codes tournament-v5getTournamentCode" [
  tournamentCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, providerId: int, tournamentId: int, code: string, region: string, map: string, teamSize: int, spectators: string, pickType: string, lobbyName: string, password: string, metaData: string, participants: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/tournament/v5/codes/($tournamentCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the pick type, map, spectator type, or allowed puuids for a code.
#
# PUT /lol/tournament/v5/codes/{tournamentCode}
# Docs: https://developer.riotgames.com/api-methods/#tournament-v5/PUT_updateCode — Official API Reference
# operationId: tournament-v5.updateCode
export def "lol-tournament-codes tournament-v5updateCode" [
  tournamentCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowedParticipants: list # Optional list of encrypted puuids in order to validate the players eligible to join the lobby. NOTE: We currently do not enforce participants at the team level, but rather the aggregate of teamOne and teamTwo. We may add the ability to enforce at the team level in the future.
  pickType: string@pickType-completer # The pick type              (Legal values:  BLIND_PICK,  DRAFT_MODE,  ALL_RANDOM,  TOURNAMENT_DRAFT)
  mapType: string@mapType-completer # The map type              (Legal values:  SUMMONERS_RIFT,  HOWLING_ABYSS)
  spectatorType: string@spectatorType-completer # The spectator type              (Legal values:  NONE,  LOBBYONLY,  ALL)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/tournament/v5/codes/($tournamentCode)")
  let body = {allowedParticipants: $allowedParticipants, pickType: $pickType, mapType: $mapType, spectatorType: $spectatorType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get games details
#
# GET /lol/tournament/v5/games/by-code/{tournamentCode}
# Docs: https://developer.riotgames.com/api-methods/#tournament-v5/GET_getGames — Official API Reference
# operationId: tournament-v5.getGames
export def "lol-tournament-games-by-code tournament-v5getGames" [
  tournamentCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<startTime: int, winningTeam: list<record>, losingTeam: list<record>, shortCode: string, metaData: string, gameId: int, gameName: string, gameType: string, gameMap: int, gameMode: string, region: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/tournament/v5/games/by-code/($tournamentCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a list of lobby events by tournament code.
#
# GET /lol/tournament/v5/lobby-events/by-code/{tournamentCode}
# Docs: https://developer.riotgames.com/api-methods/#tournament-v5/GET_getLobbyEventsByCode — Official API Reference
# operationId: tournament-v5.getLobbyEventsByCode
export def "lol-tournament-lobby-events-by-code tournament-v5getLobbyEventsByCode" [
  tournamentCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<eventList: table<timestamp: string, eventType: string, puuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lol/tournament/v5/lobby-events/by-code/($tournamentCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a tournament provider and returns its ID.
#
# POST /lol/tournament/v5/providers
# Docs: https://developer.riotgames.com/api-methods/#tournament-v5/POST_registerProviderData — Official API Reference
# operationId: tournament-v5.registerProviderData
export def "lol-tournament-providers tournament-v5registerProviderData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  region: string@region-completer-1 # The region in which the provider will be running tournaments.              (Legal values:  BR,  EUNE,  EUW,  JP,  LAN,  LAS,  NA,  OCE,  PBE,  RU,  TR,  KR,  PH,  SG,  TH,  TW,  VN)
  --body-url: string # The provider's callback URL to which tournament game results in this region should be posted. The URL must be well-formed, use the http or https protocol, and use the default port for the protocol (http URLs must use port 80, https URLs must use port 443).
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/tournament/v5/providers")
  let body = {region: $region, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a tournament and returns its ID.
#
# POST /lol/tournament/v5/tournaments
# Docs: https://developer.riotgames.com/api-methods/#tournament-v5/POST_registerTournament — Official API Reference
# operationId: tournament-v5.registerTournament
export def "lol-tournament-tournaments tournament-v5registerTournament" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  providerId: int # The provider ID to specify the regional registered provider data to associate this tournament. (format: int32)
  --name: string # The optional name of the tournament.
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lol/tournament/v5/tournaments")
  let body = {providerId: $providerId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get match by id
#
# GET /val/match/console/v1/matches/{matchId}
# Docs: https://developer.riotgames.com/api-methods/#val-console-match-v1/GET_getMatch — Official API Reference
# operationId: val-console-match-v1.getMatch
export def "val-match-console-matches val-console-match-v1getMatch" [
  matchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<matchInfo: record<matchId: string, mapId: string, gameLengthMillis: int, gameStartMillis: int, provisioningFlowId: string, isCompleted: bool, customGameName: string, queueId: string, gameMode: string, isRanked: bool, seasonId: string>, players: table<puuid: string, gameName: string, tagLine: string, teamId: string, partyId: string, characterId: string, stats: record, competitiveTier: int, playerCard: string, playerTitle: string>, coaches: table<puuid: string, teamId: string>, teams: table<teamId: string, won: bool, roundsPlayed: int, roundsWon: int, numPoints: int>, roundResults: table<roundNum: int, roundResult: string, roundCeremony: string, winningTeam: string, bombPlanter: string, bombDefuser: string, plantRoundTime: int, plantPlayerLocations: list, plantLocation: record, plantSite: string, defuseRoundTime: int, defusePlayerLocations: list, defuseLocation: record, playerStats: list, roundResultCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/val/match/console/v1/matches/($matchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get matchlist for games played by puuid and platform type
#
# GET /val/match/console/v1/matchlists/by-puuid/{puuid}
# Docs: https://developer.riotgames.com/api-methods/#val-console-match-v1/GET_getMatchlist — Official API Reference
# operationId: val-console-match-v1.getMatchlist
export def "val-match-console-matchlists-by-puuid val-console-match-v1getMatchlist" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --platformType: string@platformType-completer
]: nothing -> record<puuid: string, history: table<matchId: string, gameStartTimeMillis: int, queueId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platformType" $platformType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/val/match/console/v1/matchlists/by-puuid/($puuid)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get recent matches
#
# GET /val/match/console/v1/recent-matches/by-queue/{queue}
# Docs: https://developer.riotgames.com/api-methods/#val-console-match-v1/GET_getRecent — Official API Reference
# operationId: val-console-match-v1.getRecent
export def "val-match-console-recent-matches-by-queue val-console-match-v1getRecent" [
  queue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<currentTime: int, matchIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/val/match/console/v1/recent-matches/by-queue/($queue)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get leaderboard for the competitive queue
#
# GET /val/console/ranked/v1/leaderboards/by-act/{actId}
# Docs: https://developer.riotgames.com/api-methods/#val-console-ranked-v1/GET_getLeaderboard — Official API Reference
# operationId: val-console-ranked-v1.getLeaderboard
export def "val-console-ranked-leaderboards-by-act val-console-ranked-v1getLeaderboard" [
  actId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --platformType: string@platformType-completer
  --startIndex: int # Defaults to 0. (format: int32)
  --size: int # Defaults to 200. Valid values: 1 to 200. (format: int32)
]: nothing -> record<actId: string, totalPlayers: int, query: string, shard: string, players: table<puuid: string, gameName: string, tagLine: string, leaderboardRank: int, rankedRating: int, numberOfWins: int>, tierDetails: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platformType" $platformType "scalar") (serialize-qp "startIndex" $startIndex "scalar") (serialize-qp "size" $size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/val/console/ranked/v1/leaderboards/by-act/($actId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get content optionally filtered by locale
#
# GET /val/content/v1/contents
# Docs: https://developer.riotgames.com/api-methods/#val-content-v1/GET_getContent — Official API Reference
# operationId: val-content-v1.getContent
export def "val-content-contents val-content-v1getContent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string
]: nothing -> record<version: string, characters: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, maps: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, chromas: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, skins: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, skinLevels: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, equips: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, gameModes: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, sprays: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, sprayLevels: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, charms: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, charmLevels: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, playerCards: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, playerTitles: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, acts: table<name: string, localizedNames: record, id: string, isActive: bool, parentId: string, type: string>, ceremonies: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>, totems: table<name: string, localizedNames: record, id: string, assetName: string, assetPath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/val/content/v1/contents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get match by id
#
# GET /val/match/v1/matches/{matchId}
# Docs: https://developer.riotgames.com/api-methods/#val-match-v1/GET_getMatch — Official API Reference
# operationId: val-match-v1.getMatch
export def "val-match-matches val-match-v1getMatch" [
  matchId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<matchInfo: record<matchId: string, mapId: string, gameVersion: string, gameLengthMillis: int, region: string, gameStartMillis: int, provisioningFlowId: string, isCompleted: bool, customGameName: string, queueId: string, gameMode: string, isRanked: bool, seasonId: string, premierMatchInfo: record>, players: table<puuid: string, gameName: string, tagLine: string, teamId: string, partyId: string, characterId: string, stats: record, competitiveTier: int, isObserver: bool, playerCard: string, playerTitle: string, accountLevel: int>, coaches: table<puuid: string, teamId: string>, teams: table<teamId: string, won: bool, roundsPlayed: int, roundsWon: int, numPoints: int>, roundResults: table<roundNum: int, roundResult: string, roundCeremony: string, winningTeam: string, winningTeamRole: string, bombPlanter: string, bombDefuser: string, plantRoundTime: int, plantPlayerLocations: list, plantLocation: record, plantSite: string, defuseRoundTime: int, defusePlayerLocations: list, defuseLocation: record, playerStats: list, roundResultCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/val/match/v1/matches/($matchId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get matchlist for games played by puuid
#
# GET /val/match/v1/matchlists/by-puuid/{puuid}
# Docs: https://developer.riotgames.com/api-methods/#val-match-v1/GET_getMatchlist — Official API Reference
# operationId: val-match-v1.getMatchlist
export def "val-match-matchlists-by-puuid val-match-v1getMatchlist" [
  puuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<puuid: string, history: table<matchId: string, gameStartTimeMillis: int, queueId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/val/match/v1/matchlists/by-puuid/($puuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get recent matches
#
# GET /val/match/v1/recent-matches/by-queue/{queue}
# Docs: https://developer.riotgames.com/api-methods/#val-match-v1/GET_getRecent — Official API Reference
# operationId: val-match-v1.getRecent
export def "val-match-recent-matches-by-queue val-match-v1getRecent" [
  queue: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<currentTime: int, matchIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/val/match/v1/recent-matches/by-queue/($queue)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get leaderboard for the competitive queue
#
# GET /val/ranked/v1/leaderboards/by-act/{actId}
# Docs: https://developer.riotgames.com/api-methods/#val-ranked-v1/GET_getLeaderboard — Official API Reference
# operationId: val-ranked-v1.getLeaderboard
export def "val-ranked-leaderboards-by-act val-ranked-v1getLeaderboard" [
  actId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --size: int # Defaults to 200. Valid values: 1 to 200. (format: int32)
  --startIndex: int # Defaults to 0. (format: int32)
]: nothing -> record<shard: string, actId: string, totalPlayers: int, players: table<puuid: string, gameName: string, tagLine: string, leaderboardRank: int, rankedRating: int, numberOfWins: int, competitiveTier: int, prefix: string, premierRosterType: string>, immortalStartingPage: int, immortalStartingIndex: int, topTierRRThreshold: int, tierDetails: record, startIndex: int, query: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "size" $size "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/val/ranked/v1/leaderboards/by-act/($actId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get VALORANT status for the given platform.
#
# GET /val/status/v1/platform-data
# Docs: https://developer.riotgames.com/api-methods/#val-status-v1/GET_getPlatformData — Official API Reference
# operationId: val-status-v1.getPlatformData
export def "val-status-platform-data val-status-v1getPlatformData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, locales: list<string>, maintenances: table<id: int, maintenance_status: string, incident_severity: string, titles: list, updates: list, created_at: string, archive_at: string, updated_at: string, platforms: list>, incidents: table<id: int, maintenance_status: string, incident_severity: string, titles: list, updates: list, created_at: string, archive_at: string, updated_at: string, platforms: list>> {
  let auth = (build-auth $token ($auth_scheme | default "query-api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/val/status/v1/platform-data")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
