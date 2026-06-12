# Auto-generated client for OverFast API v4.5.0
# Source: https://overfast-api.tekrop.fr/openapi.json
# Auth: --token flag or $env.OVERFAST_API_TOKEN

const BASE_URL = "https://overfast-api.tekrop.fr"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OVERFAST_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://overfast-api.tekrop.fr"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def locale-completer [] { ["de-de" "en-gb" "en-us" "es-es" "es-mx" "fr-fr" "it-it" "ja-jp" "ko-kr" "pl-pl" "pt-br" "ru-ru" "zh-tw"] }
def platform-completer [] { ["console" "pc"] }
def gamemode-completer [] { ["competitive" "quickplay"] }
def region-completer [] { ["americas" "asia" "europe"] }
def hero-completer [] { ["all-heroes" "ana" "anran" "ashe" "baptiste" "bastion" "brigitte" "cassidy" "domina" "doomfist" "dva" "echo" "emre" "freja" "genji" "hanzo" "hazard" "illari" "jetpack-cat" "junker-queen" "junkrat" "juno" "kiriko" "lifeweaver" "lucio" "mauga" "mei" "mercy" "mizuki" "moira" "orisa" "pharah" "ramattra" "reaper" "reinhardt" "roadhog" "shion" "sierra" "sigma" "sojourn" "soldier-76" "sombra" "symmetra" "torbjorn" "tracer" "vendetta" "venture" "widowmaker" "winston" "wrecking-ball" "wuyang" "zarya" "zenyatta"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "heroes heroes" } } | get name | first)
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

# Get a list of heroes
#
# GET /heroes
# operationId: list_heroes
export def "heroes heroes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --role: string
  --locale: string@locale-completer
  --gamemode: string
]: nothing -> table<key: string, name: string, portrait: string, role: string, subrole: string, gamemodes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "role" $role "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "gamemode" $gamemode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/heroes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hero stats
#
# GET /heroes/stats
# operationId: get_hero_stats
export def "heroes-stats stats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --platform: string@platform-completer
  --gamemode: string@gamemode-completer # Filter on a specific gamemode.
  --region: string@region-completer # Filter on a specific player region.
  --role: string
  --map: string
  --competitive-division: string
  --order-by: string # default: hero:asc
]: nothing -> table<hero: string, pickrate: float, winrate: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "platform" $platform "scalar") (serialize-qp "gamemode" $gamemode "scalar") (serialize-qp "region" $region "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "map" $map "scalar") (serialize-qp "competitive_division" $competitive_division "scalar") (serialize-qp "order_by" $order_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/heroes/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get hero data
#
# GET /heroes/{hero_key}
# operationId: get_hero
export def "heroes hero" [
  hero_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string@locale-completer
]: nothing -> record<name: string, description: string, portrait: any, backgrounds: table<url: string, sizes: list>, role: string, subrole: string, location: string, age: any, birthday: any, hitpoints: any, abilities: table<name: string, description: string, icon: string, video: record>, perks: record<minor: list<record>, major: list<record>>, stadium_powers: any, story: record<summary: string, media: any, chapters: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/heroes/($hero_key)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of roles
#
# GET /roles
# operationId: list_roles
export def "roles roles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string@locale-completer
]: nothing -> table<key: string, name: string, icon: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of gamemodes
#
# GET /gamemodes
# operationId: list_map_gamemodes
export def "gamemodes gamemodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<key: string, name: string, icon: string, description: string, screenshot: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gamemodes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of maps
#
# GET /maps
# operationId: list_maps
export def "maps maps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gamemode: string # Filter maps available for a specific gamemode
]: nothing -> table<key: string, name: string, screenshot: string, gamemodes: list<string>, location: string, country_code: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gamemode" $gamemode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/maps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search for a specific player
#
# GET /players
# operationId: search_players
export def "players players" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --order-by: string # default: name:asc
  --offset: int # default: 0
  --limit: int # default: 20
]: nothing -> record<total: int, results: table<player_id: string, name: string, avatar: any, namecard: any, title: any, career_url: string, blizzard_id: string, last_updated_at: any, is_public: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/players" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get player summary
#
# GET /players/{player_id}/summary
# operationId: get_player_summary
export def "players-summary summary" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<username: string, avatar: any, namecard: any, title: any, endorsement: any, competitive: any, last_updated_at: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/players/($player_id)/summary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get player stats summary
#
# GET /players/{player_id}/stats/summary
# operationId: get_player_stats_summary
export def "players-stats-summary summary" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gamemode: string # Filter on a specific gamemode. If not specified, the data of every gamemode will be combined.
  --platform: string # Filter on a specific platform. If not specified, the data of every platform will be combined.
]: nothing -> record<general: any, roles: any, heroes: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gamemode" $gamemode "scalar") (serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($player_id)/stats/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get player career stats
#
# GET /players/{player_id}/stats/career
# operationId: get_player_career_stats
export def "players-stats-career stats" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gamemode: string@gamemode-completer # Filter on a specific gamemode.
  --platform: string@platform-completer # Filter on a specific platform. If not specified, the only platform the player played on will be selected. If the player has already played on both PC and console, the PC stats will be displayed by default.
  --hero: string@hero-completer # Filter on a specific hero in order to only get his statistics. You also can specify 'all-heroes' for general stats.
]: nothing -> record<all_heroes: any, ana: any, anran: any, ashe: any, baptiste: any, bastion: any, brigitte: any, cassidy: any, dva: any, domina: any, doomfist: any, echo: any, emre: any, freja: any, genji: any, hazard: any, hanzo: any, illari: any, jetpack_cat: any, junker_queen: any, junkrat: any, juno: any, kiriko: any, lifeweaver: any, lucio: any, mauga: any, mei: any, mercy: any, mizuki: any, moira: any, orisa: any, pharah: any, ramattra: any, reaper: any, reinhardt: any, roadhog: any, shion: any, sigma: any, sierra: any, sojourn: any, soldier_76: any, sombra: any, symmetra: any, torbjorn: any, tracer: any, vendetta: any, venture: any, widowmaker: any, winston: any, wrecking_ball: any, wuyang: any, zarya: any, zenyatta: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gamemode" $gamemode "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "hero" $hero "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($player_id)/stats/career" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get player stats with labels
#
# GET /players/{player_id}/stats
# operationId: get_player_stats
export def "players-stats stats" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gamemode: string@gamemode-completer # Filter on a specific gamemode.
  --platform: string@platform-completer # Filter on a specific platform. If not specified, the only platform the player played on will be selected. If the player has already played on both PC and console, the PC stats will be displayed by default.
  --hero: string@hero-completer # Filter on a specific hero in order to only get his statistics. You also can specify 'all-heroes' for general stats.
]: nothing -> record<all_heroes: any, ana: any, anran: any, ashe: any, baptiste: any, bastion: any, brigitte: any, cassidy: any, dva: any, domina: any, doomfist: any, echo: any, emre: any, freja: any, genji: any, hazard: any, hanzo: any, illari: any, jetpack_cat: any, junker_queen: any, junkrat: any, juno: any, kiriko: any, lifeweaver: any, lucio: any, mauga: any, mei: any, mercy: any, mizuki: any, moira: any, orisa: any, pharah: any, ramattra: any, reaper: any, reinhardt: any, roadhog: any, shion: any, sigma: any, sierra: any, sojourn: any, soldier_76: any, sombra: any, symmetra: any, torbjorn: any, tracer: any, vendetta: any, venture: any, widowmaker: any, winston: any, wrecking_ball: any, wuyang: any, zarya: any, zenyatta: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gamemode" $gamemode "scalar") (serialize-qp "platform" $platform "scalar") (serialize-qp "hero" $hero "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($player_id)/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all player data
#
# GET /players/{player_id}
# operationId: get_player_career
export def "players career" [
  player_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --gamemode: string # Filter on a specific gamemode. All gamemodes are displayed by default.
  --platform: string # Filter on a specific platform. All platforms are displayed by default.
]: nothing -> record<summary: record<username: string, avatar: any, namecard: any, title: any, endorsement: any, competitive: any, last_updated_at: any>, stats: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "gamemode" $gamemode "scalar") (serialize-qp "platform" $platform "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/players/($player_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
