# Auto-generated client for Scryfall API vv1
# Source: https://raw.githubusercontent.com/jdharmon/scryfallapi/master/swagger.yaml
# Auth: --token flag or $env.SCRYFALL_API_TOKEN

const BASE_URL = "https://api.scryfall.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SCRYFALL_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.scryfall.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def unique-completer [] { ["art" "cards" "prints"] }
def order-completer [] { ["artist" "cmc" "color" "edhrec" "eur" "name" "power" "rarity" "released" "set" "tix" "toughness" "usd"] }
def dir-completer [] { ["asc" "auto" "desc"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "sets GetAll" } } | get name | first)
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

# GET /sets
#
# operationId: Sets_GetAll
export def "sets GetAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<code: string, mtgo_code: string, name: string, set_type: string, released_at: string, block_code: string, block: string, parent_set_code: string, card_count: int, digital: bool, foil: bool, icon_svg_uri: string, search_uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /sets/{code}
#
# operationId: Sets_GetByCode
export def "sets GetByCode" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, mtgo_code: string, name: string, set_type: string, released_at: string, block_code: string, block: string, parent_set_code: string, card_count: int, digital: bool, foil: bool, icon_svg_uri: string, search_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sets/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/search
#
# operationId: Cards_Search
export def "cards-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string
  --unique: string@unique-completer
  --order: string@order-completer
  --dir: string@dir-completer
  --include-extras: oneof<nothing, bool>
  --page: int # format: int32
]: nothing -> record<total_cards: int, has_more: bool, next_page: string, data: table<id: string, oracle_id: string, multiverse_ids: list, mtgo_id: int, arena_id: int, mtgo_foil_id: int, uri: string, scryfall_uri: string, prints_search_uri: string, rulings_uri: string, name: string, layout: string, cmc: float, type_line: string, oracle_text: string, mana_cost: string, power: string, toughness: string, loyalty: string, life_modifier: string, hand_modifier: string, colors: list, color_indicator: list, color_identity: list, all_parts: list, card_faces: list, legalities: record, reserved: bool, edhrec_rank: int, set: string, set_name: string, collector_number: string, set_search_uri: string, scryfall_set_uri: string, image_uris: record, highres_image: bool, reprint: bool, digital: bool, rarity: string, flavor_text: string, artist: string, illustration_id: string, frame: string, full_art: bool, watermark: string, border_color: string, story_spotlight_number: int, story_spotlight_uri: string, timeshifted: bool, colorshifted: bool, futureshifted: bool, purchase_uris: record, related_uris: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "unique" $unique "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "dir" $dir "scalar") (serialize-qp "include_extras" $include_extras "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cards/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/named
#
# operationId: Cards_GetNamed
export def "cards-named GetNamed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --exact: string
  --fuzzy: string
  --set: string
  --format: string
  --face: string
  --version: string
  --pretty: oneof<nothing, bool>
]: nothing -> record<id: string, oracle_id: string, multiverse_ids: list<int>, mtgo_id: int, arena_id: int, mtgo_foil_id: int, uri: string, scryfall_uri: string, prints_search_uri: string, rulings_uri: string, name: string, layout: string, cmc: float, type_line: string, oracle_text: string, mana_cost: string, power: string, toughness: string, loyalty: string, life_modifier: string, hand_modifier: string, colors: list<string>, color_indicator: list<string>, color_identity: list<string>, all_parts: table<id: string, name: string, uri: string>, card_faces: table<name: string, type_line: string, oracle_text: string, mana_cost: string, colors: list, color_indicator: list, power: string, toughness: string, loyalty: string, flavor_text: string, illustration_id: string, image_uris: record>, legalities: record<standard: string, future: string, frontier: string, modern: string, legacy: string, pauper: string, vintage: string, penny: string, commander: string, 1v1: string, duel: string, brawl: string>, reserved: bool, edhrec_rank: int, set: string, set_name: string, collector_number: string, set_search_uri: string, scryfall_set_uri: string, image_uris: record<small: string, normal: string, large: string, png: string, art_crop: string, border_crop: string>, highres_image: bool, reprint: bool, digital: bool, rarity: string, flavor_text: string, artist: string, illustration_id: string, frame: string, full_art: bool, watermark: string, border_color: string, story_spotlight_number: int, story_spotlight_uri: string, timeshifted: bool, colorshifted: bool, futureshifted: bool, purchase_uris: record, related_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "exact" $exact "scalar") (serialize-qp "fuzzy" $fuzzy "scalar") (serialize-qp "set" $set "scalar") (serialize-qp "format" $format "scalar") (serialize-qp "face" $face "scalar") (serialize-qp "version" $version "scalar") (serialize-qp "pretty" $pretty "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cards/named" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/autocomplete
#
# operationId: Cards_Autocomplete
export def "cards-autocomplete Autocomplete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cards/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/random
#
# operationId: Cards_GetRandom
export def "cards-random GetRandom" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, oracle_id: string, multiverse_ids: list<int>, mtgo_id: int, arena_id: int, mtgo_foil_id: int, uri: string, scryfall_uri: string, prints_search_uri: string, rulings_uri: string, name: string, layout: string, cmc: float, type_line: string, oracle_text: string, mana_cost: string, power: string, toughness: string, loyalty: string, life_modifier: string, hand_modifier: string, colors: list<string>, color_indicator: list<string>, color_identity: list<string>, all_parts: table<id: string, name: string, uri: string>, card_faces: table<name: string, type_line: string, oracle_text: string, mana_cost: string, colors: list, color_indicator: list, power: string, toughness: string, loyalty: string, flavor_text: string, illustration_id: string, image_uris: record>, legalities: record<standard: string, future: string, frontier: string, modern: string, legacy: string, pauper: string, vintage: string, penny: string, commander: string, 1v1: string, duel: string, brawl: string>, reserved: bool, edhrec_rank: int, set: string, set_name: string, collector_number: string, set_search_uri: string, scryfall_set_uri: string, image_uris: record<small: string, normal: string, large: string, png: string, art_crop: string, border_crop: string>, highres_image: bool, reprint: bool, digital: bool, rarity: string, flavor_text: string, artist: string, illustration_id: string, frame: string, full_art: bool, watermark: string, border_color: string, story_spotlight_number: int, story_spotlight_uri: string, timeshifted: bool, colorshifted: bool, futureshifted: bool, purchase_uris: record, related_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cards/random")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/multiverse/{id}
#
# operationId: Cards_GetByMultiverseId
export def "cards-multiverse GetByMultiverseId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, oracle_id: string, multiverse_ids: list<int>, mtgo_id: int, arena_id: int, mtgo_foil_id: int, uri: string, scryfall_uri: string, prints_search_uri: string, rulings_uri: string, name: string, layout: string, cmc: float, type_line: string, oracle_text: string, mana_cost: string, power: string, toughness: string, loyalty: string, life_modifier: string, hand_modifier: string, colors: list<string>, color_indicator: list<string>, color_identity: list<string>, all_parts: table<id: string, name: string, uri: string>, card_faces: table<name: string, type_line: string, oracle_text: string, mana_cost: string, colors: list, color_indicator: list, power: string, toughness: string, loyalty: string, flavor_text: string, illustration_id: string, image_uris: record>, legalities: record<standard: string, future: string, frontier: string, modern: string, legacy: string, pauper: string, vintage: string, penny: string, commander: string, 1v1: string, duel: string, brawl: string>, reserved: bool, edhrec_rank: int, set: string, set_name: string, collector_number: string, set_search_uri: string, scryfall_set_uri: string, image_uris: record<small: string, normal: string, large: string, png: string, art_crop: string, border_crop: string>, highres_image: bool, reprint: bool, digital: bool, rarity: string, flavor_text: string, artist: string, illustration_id: string, frame: string, full_art: bool, watermark: string, border_color: string, story_spotlight_number: int, story_spotlight_uri: string, timeshifted: bool, colorshifted: bool, futureshifted: bool, purchase_uris: record, related_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/multiverse/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/mtgo/{id}
#
# operationId: Cards_GetByMtgoId
export def "cards-mtgo GetByMtgoId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, oracle_id: string, multiverse_ids: list<int>, mtgo_id: int, arena_id: int, mtgo_foil_id: int, uri: string, scryfall_uri: string, prints_search_uri: string, rulings_uri: string, name: string, layout: string, cmc: float, type_line: string, oracle_text: string, mana_cost: string, power: string, toughness: string, loyalty: string, life_modifier: string, hand_modifier: string, colors: list<string>, color_indicator: list<string>, color_identity: list<string>, all_parts: table<id: string, name: string, uri: string>, card_faces: table<name: string, type_line: string, oracle_text: string, mana_cost: string, colors: list, color_indicator: list, power: string, toughness: string, loyalty: string, flavor_text: string, illustration_id: string, image_uris: record>, legalities: record<standard: string, future: string, frontier: string, modern: string, legacy: string, pauper: string, vintage: string, penny: string, commander: string, 1v1: string, duel: string, brawl: string>, reserved: bool, edhrec_rank: int, set: string, set_name: string, collector_number: string, set_search_uri: string, scryfall_set_uri: string, image_uris: record<small: string, normal: string, large: string, png: string, art_crop: string, border_crop: string>, highres_image: bool, reprint: bool, digital: bool, rarity: string, flavor_text: string, artist: string, illustration_id: string, frame: string, full_art: bool, watermark: string, border_color: string, story_spotlight_number: int, story_spotlight_uri: string, timeshifted: bool, colorshifted: bool, futureshifted: bool, purchase_uris: record, related_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/mtgo/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/arena/{id}
#
# operationId: Cards_GetByArenaId
export def "cards-arena GetByArenaId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, oracle_id: string, multiverse_ids: list<int>, mtgo_id: int, arena_id: int, mtgo_foil_id: int, uri: string, scryfall_uri: string, prints_search_uri: string, rulings_uri: string, name: string, layout: string, cmc: float, type_line: string, oracle_text: string, mana_cost: string, power: string, toughness: string, loyalty: string, life_modifier: string, hand_modifier: string, colors: list<string>, color_indicator: list<string>, color_identity: list<string>, all_parts: table<id: string, name: string, uri: string>, card_faces: table<name: string, type_line: string, oracle_text: string, mana_cost: string, colors: list, color_indicator: list, power: string, toughness: string, loyalty: string, flavor_text: string, illustration_id: string, image_uris: record>, legalities: record<standard: string, future: string, frontier: string, modern: string, legacy: string, pauper: string, vintage: string, penny: string, commander: string, 1v1: string, duel: string, brawl: string>, reserved: bool, edhrec_rank: int, set: string, set_name: string, collector_number: string, set_search_uri: string, scryfall_set_uri: string, image_uris: record<small: string, normal: string, large: string, png: string, art_crop: string, border_crop: string>, highres_image: bool, reprint: bool, digital: bool, rarity: string, flavor_text: string, artist: string, illustration_id: string, frame: string, full_art: bool, watermark: string, border_color: string, story_spotlight_number: int, story_spotlight_uri: string, timeshifted: bool, colorshifted: bool, futureshifted: bool, purchase_uris: record, related_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/arena/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/{code}/{number}
#
# operationId: Cards_GetByCodeByNumber
export def "cards GetByCodeByNumber" [
  code: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, oracle_id: string, multiverse_ids: list<int>, mtgo_id: int, arena_id: int, mtgo_foil_id: int, uri: string, scryfall_uri: string, prints_search_uri: string, rulings_uri: string, name: string, layout: string, cmc: float, type_line: string, oracle_text: string, mana_cost: string, power: string, toughness: string, loyalty: string, life_modifier: string, hand_modifier: string, colors: list<string>, color_indicator: list<string>, color_identity: list<string>, all_parts: table<id: string, name: string, uri: string>, card_faces: table<name: string, type_line: string, oracle_text: string, mana_cost: string, colors: list, color_indicator: list, power: string, toughness: string, loyalty: string, flavor_text: string, illustration_id: string, image_uris: record>, legalities: record<standard: string, future: string, frontier: string, modern: string, legacy: string, pauper: string, vintage: string, penny: string, commander: string, 1v1: string, duel: string, brawl: string>, reserved: bool, edhrec_rank: int, set: string, set_name: string, collector_number: string, set_search_uri: string, scryfall_set_uri: string, image_uris: record<small: string, normal: string, large: string, png: string, art_crop: string, border_crop: string>, highres_image: bool, reprint: bool, digital: bool, rarity: string, flavor_text: string, artist: string, illustration_id: string, frame: string, full_art: bool, watermark: string, border_color: string, story_spotlight_number: int, story_spotlight_uri: string, timeshifted: bool, colorshifted: bool, futureshifted: bool, purchase_uris: record, related_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($code)/($number)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/{id}
#
# operationId: Cards_GetById
export def "cards GetById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, oracle_id: string, multiverse_ids: list<int>, mtgo_id: int, arena_id: int, mtgo_foil_id: int, uri: string, scryfall_uri: string, prints_search_uri: string, rulings_uri: string, name: string, layout: string, cmc: float, type_line: string, oracle_text: string, mana_cost: string, power: string, toughness: string, loyalty: string, life_modifier: string, hand_modifier: string, colors: list<string>, color_indicator: list<string>, color_identity: list<string>, all_parts: table<id: string, name: string, uri: string>, card_faces: table<name: string, type_line: string, oracle_text: string, mana_cost: string, colors: list, color_indicator: list, power: string, toughness: string, loyalty: string, flavor_text: string, illustration_id: string, image_uris: record>, legalities: record<standard: string, future: string, frontier: string, modern: string, legacy: string, pauper: string, vintage: string, penny: string, commander: string, 1v1: string, duel: string, brawl: string>, reserved: bool, edhrec_rank: int, set: string, set_name: string, collector_number: string, set_search_uri: string, scryfall_set_uri: string, image_uris: record<small: string, normal: string, large: string, png: string, art_crop: string, border_crop: string>, highres_image: bool, reprint: bool, digital: bool, rarity: string, flavor_text: string, artist: string, illustration_id: string, frame: string, full_art: bool, watermark: string, border_color: string, story_spotlight_number: int, story_spotlight_uri: string, timeshifted: bool, colorshifted: bool, futureshifted: bool, purchase_uris: record, related_uris: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/multiverse/{id}/rulings
#
# operationId: Rulings_GetByMultiverseId
export def "cards-multiverse-rulings GetByMultiverseId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<source: string, published_at: string, comment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/multiverse/($id)/rulings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/mtgo/{id}/rulings
#
# operationId: Rulings_GetByMtgoId
export def "cards-mtgo-rulings GetByMtgoId" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<source: string, published_at: string, comment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/mtgo/($id)/rulings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/{code}/{number}/rulings
#
# operationId: Rulings_GetByCodeByNumberId
export def "cards-rulings GetByCodeByNumberId" [
  code: string
  number: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<source: string, published_at: string, comment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($code)/($number)/rulings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /cards/{id}/rulings
#
# operationId: Rulings_GetById
export def "cards-rulings GetById" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<source: string, published_at: string, comment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cards/($id)/rulings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /symbology
#
# operationId: Symbology_GetAll
export def "symbology GetAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<symbol: string, loose_variant: string, english: string, transposable: bool, represents_mana: bool, cmc: float, appears_in_mana_costs: bool, funny: bool, colors: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/symbology")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /symbology/parse-mana
#
# operationId: Symbology_ParseMana
export def "symbology-parse-mana ParseMana" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cost: string
]: nothing -> record<cost: string, cmc: float, colors: string, colorless: bool, monocolored: bool, multicolored: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cost" $cost "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/symbology/parse-mana" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/card-names
#
# operationId: Catalog_GetCardNames
export def "catalog-card-names GetCardNames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/card-names")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/word-bank
#
# operationId: Catalog_GetWordBank
export def "catalog-word-bank GetWordBank" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/word-bank")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/creature-types
#
# operationId: Catalog_GetCreatureTypes
export def "catalog-creature-types GetCreatureTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/creature-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/planeswalker-types
#
# operationId: Catalog_GetPlaneswalkerTypes
export def "catalog-planeswalker-types GetPlaneswalkerTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/planeswalker-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/land-types
#
# operationId: Catalog_GetLandTypes
export def "catalog-land-types GetLandTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/land-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/artifact-types
#
# operationId: Catalog_GetArtifactTypes
export def "catalog-artifact-types GetArtifactTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/artifact-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/enchantment-types
#
# operationId: Catalog_GetEnchantmentTypes
export def "catalog-enchantment-types GetEnchantmentTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/enchantment-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/spell-types
#
# operationId: Catalog_GetSpellTypes
export def "catalog-spell-types GetSpellTypes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/spell-types")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/powers
#
# operationId: Catalog_GetPowers
export def "catalog-powers GetPowers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/powers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/thoughnesses
#
# operationId: Catalog_GetToughnesses
export def "catalog-thoughnesses GetToughnesses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/thoughnesses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/loyalties
#
# operationId: Catalog_GetLoyalties
export def "catalog-loyalties GetLoyalties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/loyalties")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /catalog/watermarks
#
# operationId: Catalog_GetWatermarks
export def "catalog-watermarks GetWatermarks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<total_items: int, data: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/catalog/watermarks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
