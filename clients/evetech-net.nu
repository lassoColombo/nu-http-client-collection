# Auto-generated client for EVE Swagger Interface v0.8.6
# Source: https://api.apis.guru/v2/specs/evetech.net/0.8.6/swagger.json
# Auth: --token flag or $env.EVE_SWAGGER_INTERFACE_TOKEN

const BASE_URL = "https://esi.evetech.net/latest"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EVE_SWAGGER_INTERFACE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://esi.evetech.net/latest"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def datasource-completer [] { ["singularity" "tranquility"] }
def response-completer [] { ["accepted" "declined" "tentative"] }
def color-completer [] { ["#0000fe" "#006634" "#0099ff" "#00ff33" "#01ffff" "#349800" "#660066" "#666666" "#999999" "#99ffff" "#9a0000" "#ccff9a" "#e6e6e6" "#fe0000" "#ff6600" "#ffff01" "#ffffcd" "#ffffff"] }
def language-completer [] { ["de" "en-us" "fr" "ja" "ru" "zh"] }
def accept-language-completer [] { ["de" "en-us" "fr" "ja" "ru" "zh"] }
def role-completer [] { ["fleet_commander" "squad_commander" "squad_member" "wing_commander"] }
def order-type-completer [] { ["all" "buy" "sell"] }
def flag-completer [] { ["insecure" "secure" "shortest"] }
def filter-completer [] { ["manufacturing_basic" "market"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alliances list" } } | get name | first)
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

# List all alliances
#
# GET /alliances/
# operationId: get_alliances
export def "alliances list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/alliances/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get alliance information
#
# GET /alliances/{alliance_id}/
# operationId: get_alliances_alliance_id
export def "alliances get" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<creator_corporation_id: int, creator_id: int, date_founded: string, executor_corporation_id: int, faction_id: int, name: string, ticker: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({alliance_id: (encode-path-segment $alliance_id)} | format pattern "/alliances/{alliance_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get alliance contacts
#
# GET /alliances/{alliance_id}/contacts/
# operationId: get_alliances_alliance_id_contacts
export def "alliances-contacts get" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<contact_id: int, contact_type: string, label_ids: list<int>, standing: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({alliance_id: (encode-path-segment $alliance_id)} | format pattern "/alliances/{alliance_id}/contacts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get alliance contact labels
#
# GET /alliances/{alliance_id}/contacts/labels/
# operationId: get_alliances_alliance_id_contacts_labels
export def "alliances-contacts-labels get" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<label_id: int, label_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({alliance_id: (encode-path-segment $alliance_id)} | format pattern "/alliances/{alliance_id}/contacts/labels/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List alliance's corporations
#
# GET /alliances/{alliance_id}/corporations/
# operationId: get_alliances_alliance_id_corporations
export def "alliances-corporations get" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({alliance_id: (encode-path-segment $alliance_id)} | format pattern "/alliances/{alliance_id}/corporations/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get alliance icon
#
# GET /alliances/{alliance_id}/icons/
# operationId: get_alliances_alliance_id_icons
export def "alliances-icons get" [
  alliance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<px128x128: string, px64x64: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({alliance_id: (encode-path-segment $alliance_id)} | format pattern "/alliances/{alliance_id}/icons/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Character affiliation
#
# POST /characters/affiliation/
# operationId: post_characters_affiliation
export def "characters-affiliation create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --body: record
]: any -> table<alliance_id: int, character_id: int, corporation_id: int, faction_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/characters/affiliation/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get character's public information
#
# GET /characters/{character_id}/
# operationId: get_characters_character_id
export def "characters get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<alliance_id: int, ancestry_id: int, birthday: string, bloodline_id: int, corporation_id: int, description: string, faction_id: int, gender: string, name: string, race_id: int, security_status: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get agents research
#
# GET /characters/{character_id}/agents_research/
# operationId: get_characters_character_id_agents_research
export def "characters-agents-research get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<agent_id: int, points_per_day: float, remainder_points: float, skill_type_id: int, started_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/agents_research/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character assets
#
# GET /characters/{character_id}/assets/
# operationId: get_characters_character_id_assets
export def "characters-assets get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<is_blueprint_copy: bool, is_singleton: bool, item_id: int, location_flag: string, location_id: int, location_type: string, quantity: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/assets/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character asset locations
#
# POST /characters/{character_id}/assets/locations/
# operationId: post_characters_character_id_assets_locations
export def "characters-assets-locations create" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --body: record
]: any -> table<item_id: int, position: record<x: float, y: float, z: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/assets/locations/") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get character asset names
#
# POST /characters/{character_id}/assets/names/
# operationId: post_characters_character_id_assets_names
export def "characters-assets-names create" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --body: record
]: any -> table<item_id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/assets/names/") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get character attributes
#
# GET /characters/{character_id}/attributes/
# operationId: get_characters_character_id_attributes
export def "characters-attributes get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<accrued_remap_cooldown_date: string, bonus_remaps: int, charisma: int, intelligence: int, last_remap_date: string, memory: int, perception: int, willpower: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/attributes/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get blueprints
#
# GET /characters/{character_id}/blueprints/
# operationId: get_characters_character_id_blueprints
export def "characters-blueprints get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<item_id: int, location_flag: string, location_id: int, material_efficiency: int, quantity: int, runs: int, time_efficiency: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/blueprints/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bookmarks
#
# GET /characters/{character_id}/bookmarks/
# operationId: get_characters_character_id_bookmarks
export def "characters-bookmarks get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<bookmark_id: int, coordinates: record<x: float, y: float, z: float>, created: string, creator_id: int, folder_id: int, item: record<item_id: int, type_id: int>, label: string, location_id: int, notes: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/bookmarks/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List bookmark folders
#
# GET /characters/{character_id}/bookmarks/folders/
# operationId: get_characters_character_id_bookmarks_folders
export def "characters-bookmarks-folders get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<folder_id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/bookmarks/folders/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List calendar event summaries
#
# GET /characters/{character_id}/calendar/
# operationId: get_characters_character_id_calendar
export def "characters-calendar list" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --from-event: int # The event ID to retrieve events from (format: int32)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<event_date: string, event_id: int, event_response: string, importance: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "from_event" $from_event "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/calendar/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an event
#
# GET /characters/{character_id}/calendar/{event_id}/
# operationId: get_characters_character_id_calendar_event_id
export def "characters-calendar get" [
  character_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<date: string, duration: int, event_id: int, importance: int, owner_id: int, owner_name: string, owner_type: string, response: string, text: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), event_id: (encode-path-segment $event_id)} | format pattern "/characters/{character_id}/calendar/{event_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Respond to an event
#
# PUT /characters/{character_id}/calendar/{event_id}/
# operationId: put_characters_character_id_calendar_event_id
export def "characters-calendar update" [
  character_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  response: string@response-completer # response string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), event_id: (encode-path-segment $event_id)} | format pattern "/characters/{character_id}/calendar/{event_id}/") $qp)
  let req_body = {"response": $response} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get attendees
#
# GET /characters/{character_id}/calendar/{event_id}/attendees/
# operationId: get_characters_character_id_calendar_event_id_attendees
export def "characters-calendar-attendees get" [
  character_id: int
  event_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<character_id: int, event_response: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), event_id: (encode-path-segment $event_id)} | format pattern "/characters/{character_id}/calendar/{event_id}/attendees/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get clones
#
# GET /characters/{character_id}/clones/
# operationId: get_characters_character_id_clones
export def "characters-clones get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<home_location: record<location_id: int, location_type: string>, jump_clones: table<implants: list, jump_clone_id: int, location_id: int, location_type: string, name: string>, last_clone_jump_date: string, last_station_change_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/clones/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete contacts
#
# DELETE /characters/{character_id}/contacts/
# operationId: delete_characters_character_id_contacts
export def "characters-contacts delete" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contact-ids: list<int> # A list of contacts to delete
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contact_ids" $contact_ids "csv") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/contacts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contacts
#
# GET /characters/{character_id}/contacts/
# operationId: get_characters_character_id_contacts
export def "characters-contacts get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<contact_id: int, contact_type: string, is_blocked: bool, is_watched: bool, label_ids: list<int>, standing: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/contacts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add contacts
#
# POST /characters/{character_id}/contacts/
# operationId: post_characters_character_id_contacts
export def "characters-contacts create" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --label-ids: list<int> # Add custom labels to the new contact
  --standing: float # Standing for the contact (format: float)
  --qp-token: string # Access token to use if unable to set a header
  --watched: oneof<nothing, bool> # Whether the contact should be watched, note this is only effective on characters (default: false)
  --body: record
]: any -> list<int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "label_ids" $label_ids "csv") (serialize-qp "standing" $standing "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "watched" $watched "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/contacts/") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Edit contacts
#
# PUT /characters/{character_id}/contacts/
# operationId: put_characters_character_id_contacts
export def "characters-contacts update" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --label-ids: list<int> # Add custom labels to the contact
  --standing: float # Standing for the contact (format: float)
  --qp-token: string # Access token to use if unable to set a header
  --watched: oneof<nothing, bool> # Whether the contact should be watched, note this is only effective on characters (default: false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "label_ids" $label_ids "csv") (serialize-qp "standing" $standing "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "watched" $watched "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/contacts/") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get contact labels
#
# GET /characters/{character_id}/contacts/labels/
# operationId: get_characters_character_id_contacts_labels
export def "characters-contacts-labels get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<label_id: int, label_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/contacts/labels/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contracts
#
# GET /characters/{character_id}/contracts/
# operationId: get_characters_character_id_contracts
export def "characters-contracts get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<acceptor_id: int, assignee_id: int, availability: string, buyout: float, collateral: float, contract_id: int, date_accepted: string, date_completed: string, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, status: string, title: string, type: string, volume: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/contracts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contract bids
#
# GET /characters/{character_id}/contracts/{contract_id}/bids/
# operationId: get_characters_character_id_contracts_contract_id_bids
export def "characters-contracts-bids get" [
  character_id: int
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<amount: float, bid_id: int, bidder_id: int, date_bid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), contract_id: (encode-path-segment $contract_id)} | format pattern "/characters/{character_id}/contracts/{contract_id}/bids/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contract items
#
# GET /characters/{character_id}/contracts/{contract_id}/items/
# operationId: get_characters_character_id_contracts_contract_id_items
export def "characters-contracts-items get" [
  character_id: int
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<is_included: bool, is_singleton: bool, quantity: int, raw_quantity: int, record_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), contract_id: (encode-path-segment $contract_id)} | format pattern "/characters/{character_id}/contracts/{contract_id}/items/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation history
#
# GET /characters/{character_id}/corporationhistory/
# operationId: get_characters_character_id_corporationhistory
export def "characters-corporationhistory get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<corporation_id: int, is_deleted: bool, record_id: int, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/corporationhistory/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Calculate a CSPA charge cost
#
# POST /characters/{character_id}/cspa/
# operationId: post_characters_character_id_cspa
export def "characters-cspa create" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --body: record
]: any -> float {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/cspa/") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get jump fatigue
#
# GET /characters/{character_id}/fatigue/
# operationId: get_characters_character_id_fatigue
export def "characters-fatigue get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<jump_fatigue_expire_date: string, last_jump_date: string, last_update_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/fatigue/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get fittings
#
# GET /characters/{character_id}/fittings/
# operationId: get_characters_character_id_fittings
export def "characters-fittings get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<description: string, fitting_id: int, items: list<record>, name: string, ship_type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/fittings/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create fitting
#
# POST /characters/{character_id}/fittings/
# operationId: post_characters_character_id_fittings
# --items item shape: {flag: int, quantity: int, type_id: int}
export def "characters-fittings create" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  description: string # description string
  items: list # items array — item shape: {flag: int, quantity: int, type_id: int}
  name: string # name string
  ship_type_id: int # ship_type_id integer (format: int32)
]: any -> record<fitting_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/fittings/") $qp)
  let req_body = {"description": $description, "items": $items, "name": $name, "ship_type_id": $ship_type_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete fitting
#
# DELETE /characters/{character_id}/fittings/{fitting_id}/
# operationId: delete_characters_character_id_fittings_fitting_id
export def "characters-fittings delete" [
  character_id: int
  fitting_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), fitting_id: (encode-path-segment $fitting_id)} | format pattern "/characters/{character_id}/fittings/{fitting_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character fleet info
#
# GET /characters/{character_id}/fleet/
# operationId: get_characters_character_id_fleet
export def "characters-fleet get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<fleet_id: int, role: string, squad_id: int, wing_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/fleet/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Overview of a character involved in faction warfare
#
# GET /characters/{character_id}/fw/stats/
# operationId: get_characters_character_id_fw_stats
export def "characters-fw-stats get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<current_rank: int, enlisted_on: string, faction_id: int, highest_rank: int, kills: record<last_week: int, total: int, yesterday: int>, victory_points: record<last_week: int, total: int, yesterday: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/fw/stats/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get active implants
#
# GET /characters/{character_id}/implants/
# operationId: get_characters_character_id_implants
export def "characters-implants get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/implants/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List character industry jobs
#
# GET /characters/{character_id}/industry/jobs/
# operationId: get_characters_character_id_industry_jobs
export def "characters-industry-jobs get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --include-completed: oneof<nothing, bool> # Whether to retrieve completed character industry jobs. Only includes jobs from the past 90 days
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<activity_id: int, blueprint_id: int, blueprint_location_id: int, blueprint_type_id: int, completed_character_id: int, completed_date: string, cost: float, duration: int, end_date: string, facility_id: int, installer_id: int, job_id: int, licensed_runs: int, output_location_id: int, pause_date: string, probability: float, product_type_id: int, runs: int, start_date: string, station_id: int, status: string, successful_runs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "include_completed" $include_completed "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/industry/jobs/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a character's recent kills and losses
#
# GET /characters/{character_id}/killmails/recent/
# operationId: get_characters_character_id_killmails_recent
export def "characters-killmails-recent get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<killmail_hash: string, killmail_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/killmails/recent/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character location
#
# GET /characters/{character_id}/location/
# operationId: get_characters_character_id_location
export def "characters-location get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<solar_system_id: int, station_id: int, structure_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/location/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get loyalty points
#
# GET /characters/{character_id}/loyalty/points/
# operationId: get_characters_character_id_loyalty_points
export def "characters-loyalty-points get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<corporation_id: int, loyalty_points: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/loyalty/points/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return mail headers
#
# GET /characters/{character_id}/mail/
# operationId: get_characters_character_id_mail
export def "characters-mail list" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --labels: list<int> # Fetch only mails that match one or more of the given labels
  --last-mail-id: int # List only mail with an ID lower than the given ID, if present (format: int32)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<from: int, is_read: bool, labels: list<int>, mail_id: int, recipients: list<record>, subject: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "labels" $labels "csv") (serialize-qp "last_mail_id" $last_mail_id "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/mail/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a new mail
#
# POST /characters/{character_id}/mail/
# operationId: post_characters_character_id_mail
# --recipients item shape: {recipient_id: int, recipient_type: "alliance"|"character"|"corporation"|"mailing_list"}
export def "characters-mail create" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --approved-cost: int # approved_cost integer (format: int64, default: 0)
  body: string # body string
  recipients: list # recipients array — item shape: {recipient_id: int, recipient_type: "alliance"|"character"|"corporation"|"mailing_list"}
  subject: string # subject string
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/mail/") $qp)
  let req_body = {"approved_cost": $approved_cost, "body": $body, "recipients": $recipients, "subject": $subject} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get mail labels and unread counts
#
# GET /characters/{character_id}/mail/labels/
# operationId: get_characters_character_id_mail_labels
export def "characters-mail-labels get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<labels: table<color: string, label_id: int, name: string, unread_count: int>, total_unread_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/mail/labels/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a mail label
#
# POST /characters/{character_id}/mail/labels/
# operationId: post_characters_character_id_mail_labels
export def "characters-mail-labels create" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --color: string@color-completer # Hexadecimal string representing label color, in RGB format (default: #ffffff)
  name: string # name string
]: any -> int {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/mail/labels/") $qp)
  let req_body = {"color": $color, "name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a mail label
#
# DELETE /characters/{character_id}/mail/labels/{label_id}/
# operationId: delete_characters_character_id_mail_labels_label_id
export def "characters-mail-labels delete" [
  character_id: int
  label_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), label_id: (encode-path-segment $label_id)} | format pattern "/characters/{character_id}/mail/labels/{label_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return mailing list subscriptions
#
# GET /characters/{character_id}/mail/lists/
# operationId: get_characters_character_id_mail_lists
export def "characters-mail-lists get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<mailing_list_id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/mail/lists/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a mail
#
# DELETE /characters/{character_id}/mail/{mail_id}/
# operationId: delete_characters_character_id_mail_mail_id
export def "characters-mail delete" [
  character_id: int
  mail_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), mail_id: (encode-path-segment $mail_id)} | format pattern "/characters/{character_id}/mail/{mail_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Return a mail
#
# GET /characters/{character_id}/mail/{mail_id}/
# operationId: get_characters_character_id_mail_mail_id
export def "characters-mail get" [
  character_id: int
  mail_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<body: string, from: int, labels: list<int>, read: bool, recipients: table<recipient_id: int, recipient_type: string>, subject: string, timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), mail_id: (encode-path-segment $mail_id)} | format pattern "/characters/{character_id}/mail/{mail_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update metadata about a mail
#
# PUT /characters/{character_id}/mail/{mail_id}/
# operationId: put_characters_character_id_mail_mail_id
export def "characters-mail update" [
  character_id: int
  mail_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --labels: list<int> # Labels to assign to the mail. Pre-existing labels are unassigned.
  --read: oneof<nothing, bool> # Whether the mail is flagged as read
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), mail_id: (encode-path-segment $mail_id)} | format pattern "/characters/{character_id}/mail/{mail_id}/") $qp)
  let req_body = {"labels": $labels, "read": $read} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get medals
#
# GET /characters/{character_id}/medals/
# operationId: get_characters_character_id_medals
export def "characters-medals get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<corporation_id: int, date: string, description: string, graphics: list<record>, issuer_id: int, medal_id: int, reason: string, status: string, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/medals/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Character mining ledger
#
# GET /characters/{character_id}/mining/
# operationId: get_characters_character_id_mining
export def "characters-mining get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<date: string, quantity: int, solar_system_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/mining/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character notifications
#
# GET /characters/{character_id}/notifications/
# operationId: get_characters_character_id_notifications
export def "characters-notifications get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<is_read: bool, notification_id: int, sender_id: int, sender_type: string, text: string, timestamp: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/notifications/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get new contact notifications
#
# GET /characters/{character_id}/notifications/contacts/
# operationId: get_characters_character_id_notifications_contacts
export def "characters-notifications-contacts get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<message: string, notification_id: int, send_date: string, sender_character_id: int, standing_level: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/notifications/contacts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character online
#
# GET /characters/{character_id}/online/
# operationId: get_characters_character_id_online
export def "characters-online get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<last_login: string, last_logout: string, logins: int, online: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/online/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a character's completed tasks
#
# GET /characters/{character_id}/opportunities/
# operationId: get_characters_character_id_opportunities
export def "characters-opportunities get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<completed_at: string, task_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/opportunities/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List open orders from a character
#
# GET /characters/{character_id}/orders/
# operationId: get_characters_character_id_orders
export def "characters-orders get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<duration: int, escrow: float, is_buy_order: bool, is_corporation: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, type_id: int, volume_remain: int, volume_total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/orders/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List historical orders by a character
#
# GET /characters/{character_id}/orders/history/
# operationId: get_characters_character_id_orders_history
export def "characters-orders-history get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<duration: int, escrow: float, is_buy_order: bool, is_corporation: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, state: string, type_id: int, volume_remain: int, volume_total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/orders/history/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get colonies
#
# GET /characters/{character_id}/planets/
# operationId: get_characters_character_id_planets
export def "characters-planets list" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<last_update: string, num_pins: int, owner_id: int, planet_id: int, planet_type: string, solar_system_id: int, upgrade_level: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/planets/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get colony layout
#
# GET /characters/{character_id}/planets/{planet_id}/
# operationId: get_characters_character_id_planets_planet_id
export def "characters-planets get" [
  character_id: int
  planet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<links: table<destination_pin_id: int, link_level: int, source_pin_id: int>, pins: table<contents: list, expiry_time: string, extractor_details: record, factory_details: record, install_time: string, last_cycle_start: string, latitude: float, longitude: float, pin_id: int, schematic_id: int, type_id: int>, routes: table<content_type_id: int, destination_pin_id: int, quantity: float, route_id: int, source_pin_id: int, waypoints: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id), planet_id: (encode-path-segment $planet_id)} | format pattern "/characters/{character_id}/planets/{planet_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character portraits
#
# GET /characters/{character_id}/portrait/
# operationId: get_characters_character_id_portrait
export def "characters-portrait get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<px128x128: string, px256x256: string, px512x512: string, px64x64: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/portrait/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character corporation roles
#
# GET /characters/{character_id}/roles/
# operationId: get_characters_character_id_roles
export def "characters-roles get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/roles/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search on a string
#
# GET /characters/{character_id}/search/
# operationId: get_characters_character_id_search
export def "characters-search get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # Type of entities to search for
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --search: string # The string to search on
  --strict: oneof<nothing, bool> # Whether the search should be a strict match (default: false)
  --qp-token: string # Access token to use if unable to set a header
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<agent: list<int>, alliance: list<int>, character: list<int>, constellation: list<int>, corporation: list<int>, faction: list<int>, inventory_type: list<int>, region: list<int>, solar_system: list<int>, station: list<int>, structure: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categories" $categories "csv") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "strict" $strict "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/search/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current ship
#
# GET /characters/{character_id}/ship/
# operationId: get_characters_character_id_ship
export def "characters-ship get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<ship_item_id: int, ship_name: string, ship_type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/ship/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character's skill queue
#
# GET /characters/{character_id}/skillqueue/
# operationId: get_characters_character_id_skillqueue
export def "characters-skillqueue get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<finish_date: string, finished_level: int, level_end_sp: int, level_start_sp: int, queue_position: int, skill_id: int, start_date: string, training_start_sp: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/skillqueue/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character skills
#
# GET /characters/{character_id}/skills/
# operationId: get_characters_character_id_skills
export def "characters-skills get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<skills: table<active_skill_level: int, skill_id: int, skillpoints_in_skill: int, trained_skill_level: int>, total_sp: int, unallocated_sp: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/skills/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get standings
#
# GET /characters/{character_id}/standings/
# operationId: get_characters_character_id_standings
export def "characters-standings get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<from_id: int, from_type: string, standing: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/standings/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Yearly aggregate stats
#
# GET /characters/{character_id}/stats/
# operationId: get_characters_character_id_stats
export def "characters-stats get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<character: record<days_of_activity: int, minutes: int, sessions_started: int>, combat: record<cap_drainedby_npc: int, cap_drainedby_pc: int, cap_draining_pc: int, criminal_flag_set: int, damage_from_np_cs_amount: int, damage_from_np_cs_num_shots: int, damage_from_players_bomb_amount: int, damage_from_players_bomb_num_shots: int, damage_from_players_combat_drone_amount: int, damage_from_players_combat_drone_num_shots: int, damage_from_players_energy_amount: int, damage_from_players_energy_num_shots: int, damage_from_players_fighter_bomber_amount: int, damage_from_players_fighter_bomber_num_shots: int, damage_from_players_fighter_drone_amount: int, damage_from_players_fighter_drone_num_shots: int, damage_from_players_hybrid_amount: int, damage_from_players_hybrid_num_shots: int, damage_from_players_missile_amount: int, damage_from_players_missile_num_shots: int, damage_from_players_projectile_amount: int, damage_from_players_projectile_num_shots: int, damage_from_players_smart_bomb_amount: int, damage_from_players_smart_bomb_num_shots: int, damage_from_players_super_amount: int, damage_from_players_super_num_shots: int, damage_from_structures_total_amount: int, damage_from_structures_total_num_shots: int, damage_to_players_bomb_amount: int, damage_to_players_bomb_num_shots: int, damage_to_players_combat_drone_amount: int, damage_to_players_combat_drone_num_shots: int, damage_to_players_energy_amount: int, damage_to_players_energy_num_shots: int, damage_to_players_fighter_bomber_amount: int, damage_to_players_fighter_bomber_num_shots: int, damage_to_players_fighter_drone_amount: int, damage_to_players_fighter_drone_num_shots: int, damage_to_players_hybrid_amount: int, damage_to_players_hybrid_num_shots: int, damage_to_players_missile_amount: int, damage_to_players_missile_num_shots: int, damage_to_players_projectile_amount: int, damage_to_players_projectile_num_shots: int, damage_to_players_smart_bomb_amount: int, damage_to_players_smart_bomb_num_shots: int, damage_to_players_super_amount: int, damage_to_players_super_num_shots: int, damage_to_structures_total_amount: int, damage_to_structures_total_num_shots: int, deaths_high_sec: int, deaths_low_sec: int, deaths_null_sec: int, deaths_pod_high_sec: int, deaths_pod_low_sec: int, deaths_pod_null_sec: int, deaths_pod_wormhole: int, deaths_wormhole: int, drone_engage: int, dscans: int, duel_requested: int, engagement_register: int, kills_assists: int, kills_high_sec: int, kills_low_sec: int, kills_null_sec: int, kills_pod_high_sec: int, kills_pod_low_sec: int, kills_pod_null_sec: int, kills_pod_wormhole: int, kills_wormhole: int, npc_flag_set: int, probe_scans: int, pvp_flag_set: int, repair_armor_by_remote_amount: int, repair_armor_remote_amount: int, repair_armor_self_amount: int, repair_capacitor_by_remote_amount: int, repair_capacitor_remote_amount: int, repair_capacitor_self_amount: int, repair_hull_by_remote_amount: int, repair_hull_remote_amount: int, repair_hull_self_amount: int, repair_shield_by_remote_amount: int, repair_shield_remote_amount: int, repair_shield_self_amount: int, self_destructs: int, warp_scramble_pc: int, warp_scrambledby_npc: int, warp_scrambledby_pc: int, weapon_flag_set: int, webifiedby_npc: int, webifiedby_pc: int, webifying_pc: int>, industry: record<hacking_successes: int, jobs_cancelled: int, jobs_completed_copy_blueprint: int, jobs_completed_invention: int, jobs_completed_manufacture: int, jobs_completed_manufacture_asteroid: int, jobs_completed_manufacture_asteroid_quantity: int, jobs_completed_manufacture_charge: int, jobs_completed_manufacture_charge_quantity: int, jobs_completed_manufacture_commodity: int, jobs_completed_manufacture_commodity_quantity: int, jobs_completed_manufacture_deployable: int, jobs_completed_manufacture_deployable_quantity: int, jobs_completed_manufacture_drone: int, jobs_completed_manufacture_drone_quantity: int, jobs_completed_manufacture_implant: int, jobs_completed_manufacture_implant_quantity: int, jobs_completed_manufacture_module: int, jobs_completed_manufacture_module_quantity: int, jobs_completed_manufacture_other: int, jobs_completed_manufacture_other_quantity: int, jobs_completed_manufacture_ship: int, jobs_completed_manufacture_ship_quantity: int, jobs_completed_manufacture_structure: int, jobs_completed_manufacture_structure_quantity: int, jobs_completed_manufacture_subsystem: int, jobs_completed_manufacture_subsystem_quantity: int, jobs_completed_material_productivity: int, jobs_completed_time_productivity: int, jobs_started_copy_blueprint: int, jobs_started_invention: int, jobs_started_manufacture: int, jobs_started_material_productivity: int, jobs_started_time_productivity: int, reprocess_item: int, reprocess_item_quantity: int>, inventory: record<abandon_loot_quantity: int, trash_item_quantity: int>, isk: record<in: int, out: int>, market: record<accept_contracts_courier: int, accept_contracts_item_exchange: int, buy_orders_placed: int, cancel_market_order: int, create_contracts_auction: int, create_contracts_courier: int, create_contracts_item_exchange: int, deliver_courier_contract: int, isk_gained: int, isk_spent: int, modify_market_order: int, search_contracts: int, sell_orders_placed: int>, mining: record<drone_mine: int, ore_arkonor: int, ore_bistot: int, ore_crokite: int, ore_dark_ochre: int, ore_gneiss: int, ore_harvestable_cloud: int, ore_hedbergite: int, ore_hemorphite: int, ore_ice: int, ore_jaspet: int, ore_kernite: int, ore_mercoxit: int, ore_omber: int, ore_plagioclase: int, ore_pyroxeres: int, ore_scordite: int, ore_spodumain: int, ore_veldspar: int>, module: record<activations_armor_hardener: int, activations_armor_repair_unit: int, activations_armor_resistance_shift_hardener: int, activations_automated_targeting_system: int, activations_bastion: int, activations_bomb_launcher: int, activations_capacitor_booster: int, activations_cargo_scanner: int, activations_cloaking_device: int, activations_clone_vat_bay: int, activations_cynosural_field: int, activations_damage_control: int, activations_data_miners: int, activations_drone_control_unit: int, activations_drone_tracking_modules: int, activations_eccm: int, activations_ecm: int, activations_ecm_burst: int, activations_energy_destabilizer: int, activations_energy_vampire: int, activations_energy_weapon: int, activations_festival_launcher: int, activations_frequency_mining_laser: int, activations_fueled_armor_repairer: int, activations_fueled_shield_booster: int, activations_gang_coordinator: int, activations_gas_cloud_harvester: int, activations_hull_repair_unit: int, activations_hybrid_weapon: int, activations_industrial_core: int, activations_interdiction_sphere_launcher: int, activations_micro_jump_drive: int, activations_mining_laser: int, activations_missile_launcher: int, activations_passive_targeting_system: int, activations_probe_launcher: int, activations_projected_eccm: int, activations_projectile_weapon: int, activations_propulsion_module: int, activations_remote_armor_repairer: int, activations_remote_capacitor_transmitter: int, activations_remote_ecm_burst: int, activations_remote_hull_repairer: int, activations_remote_sensor_booster: int, activations_remote_sensor_damper: int, activations_remote_shield_booster: int, activations_remote_tracking_computer: int, activations_salvager: int, activations_sensor_booster: int, activations_shield_booster: int, activations_shield_hardener: int, activations_ship_scanner: int, activations_siege: int, activations_smart_bomb: int, activations_stasis_web: int, activations_strip_miner: int, activations_super_weapon: int, activations_survey_scanner: int, activations_target_breaker: int, activations_target_painter: int, activations_tracking_computer: int, activations_tracking_disruptor: int, activations_tractor_beam: int, activations_triage: int, activations_warp_disrupt_field_generator: int, activations_warp_scrambler: int, link_weapons: int, overload: int, repairs: int>, orbital: record<strike_characters_killed: int, strike_damage_to_players_armor_amount: int, strike_damage_to_players_shield_amount: int>, pve: record<dungeons_completed_agent: int, dungeons_completed_distribution: int, missions_succeeded: int, missions_succeeded_epic_arc: int>, social: record<add_contact_bad: int, add_contact_good: int, add_contact_high: int, add_contact_horrible: int, add_contact_neutral: int, add_note: int, added_as_contact_bad: int, added_as_contact_good: int, added_as_contact_high: int, added_as_contact_horrible: int, added_as_contact_neutral: int, calendar_event_created: int, chat_messages_alliance: int, chat_messages_constellation: int, chat_messages_corporation: int, chat_messages_fleet: int, chat_messages_region: int, chat_messages_solarsystem: int, chat_messages_warfaction: int, chat_total_message_length: int, direct_trades: int, fleet_broadcasts: int, fleet_joins: int, mails_received: int, mails_sent: int>, travel: record<acceleration_gate_activations: int, align_to: int, distance_warped_high_sec: int, distance_warped_low_sec: int, distance_warped_null_sec: int, distance_warped_wormhole: int, docks_high_sec: int, docks_low_sec: int, docks_null_sec: int, jumps_stargate_high_sec: int, jumps_stargate_low_sec: int, jumps_stargate_null_sec: int, jumps_wormhole: int, warps_high_sec: int, warps_low_sec: int, warps_null_sec: int, warps_to_bookmark: int, warps_to_celestial: int, warps_to_fleet_member: int, warps_to_scan_result: int, warps_wormhole: int>, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/stats/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character corporation titles
#
# GET /characters/{character_id}/titles/
# operationId: get_characters_character_id_titles
export def "characters-titles get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<name: string, title_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/titles/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a character's wallet balance
#
# GET /characters/{character_id}/wallet/
# operationId: get_characters_character_id_wallet
export def "characters-wallet get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> float {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/wallet/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character wallet journal
#
# GET /characters/{character_id}/wallet/journal/
# operationId: get_characters_character_id_wallet_journal
export def "characters-wallet-journal get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<amount: float, balance: float, context_id: int, context_id_type: string, date: string, description: string, first_party_id: int, id: int, reason: string, ref_type: string, second_party_id: int, tax: float, tax_receiver_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/wallet/journal/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get wallet transactions
#
# GET /characters/{character_id}/wallet/transactions/
# operationId: get_characters_character_id_wallet_transactions
export def "characters-wallet-transactions get" [
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --from-id: int # Only show transactions happened before the one referenced by this id (format: int64)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<client_id: int, date: string, is_buy: bool, is_personal: bool, journal_ref_id: int, location_id: int, quantity: int, transaction_id: int, type_id: int, unit_price: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({character_id: (encode-path-segment $character_id)} | format pattern "/characters/{character_id}/wallet/transactions/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public contract bids
#
# GET /contracts/public/bids/{contract_id}/
# operationId: get_contracts_public_bids_contract_id
export def "contracts-public-bids get" [
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<amount: float, bid_id: int, date_bid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({contract_id: (encode-path-segment $contract_id)} | format pattern "/contracts/public/bids/{contract_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public contract items
#
# GET /contracts/public/items/{contract_id}/
# operationId: get_contracts_public_items_contract_id
export def "contracts-public-items get" [
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<is_blueprint_copy: bool, is_included: bool, item_id: int, material_efficiency: int, quantity: int, record_id: int, runs: int, time_efficiency: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({contract_id: (encode-path-segment $contract_id)} | format pattern "/contracts/public/items/{contract_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get public contracts
#
# GET /contracts/public/{region_id}/
# operationId: get_contracts_public_region_id
export def "contracts-public get" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<buyout: float, collateral: float, contract_id: int, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, title: string, type: string, volume: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({region_id: (encode-path-segment $region_id)} | format pattern "/contracts/public/{region_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Moon extraction timers
#
# GET /corporation/{corporation_id}/mining/extractions/
# operationId: get_corporation_corporation_id_mining_extractions
export def "corporation-mining-extractions get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<chunk_arrival_time: string, extraction_start_time: string, moon_id: int, natural_decay_time: string, structure_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporation/{corporation_id}/mining/extractions/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Corporation mining observers
#
# GET /corporation/{corporation_id}/mining/observers/
# operationId: get_corporation_corporation_id_mining_observers
export def "corporation-mining-observers list" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<last_updated: string, observer_id: int, observer_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporation/{corporation_id}/mining/observers/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Observed corporation mining
#
# GET /corporation/{corporation_id}/mining/observers/{observer_id}/
# operationId: get_corporation_corporation_id_mining_observers_observer_id
export def "corporation-mining-observers get" [
  corporation_id: int
  observer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<character_id: int, last_updated: string, quantity: int, recorded_corporation_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id), observer_id: (encode-path-segment $observer_id)} | format pattern "/corporation/{corporation_id}/mining/observers/{observer_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get npc corporations
#
# GET /corporations/npccorps/
# operationId: get_corporations_npccorps
export def "corporations-npccorps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/corporations/npccorps/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation information
#
# GET /corporations/{corporation_id}/
# operationId: get_corporations_corporation_id
export def "corporations get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<alliance_id: int, ceo_id: int, creator_id: int, date_founded: string, description: string, faction_id: int, home_station_id: int, member_count: int, name: string, shares: int, tax_rate: float, ticker: string, url: string, war_eligible: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get alliance history
#
# GET /corporations/{corporation_id}/alliancehistory/
# operationId: get_corporations_corporation_id_alliancehistory
export def "corporations-alliancehistory get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<alliance_id: int, is_deleted: bool, record_id: int, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/alliancehistory/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation assets
#
# GET /corporations/{corporation_id}/assets/
# operationId: get_corporations_corporation_id_assets
export def "corporations-assets get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<is_blueprint_copy: bool, is_singleton: bool, item_id: int, location_flag: string, location_id: int, location_type: string, quantity: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/assets/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation asset locations
#
# POST /corporations/{corporation_id}/assets/locations/
# operationId: post_corporations_corporation_id_assets_locations
export def "corporations-assets-locations create" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --body: record
]: any -> table<item_id: int, position: record<x: float, y: float, z: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/assets/locations/") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get corporation asset names
#
# POST /corporations/{corporation_id}/assets/names/
# operationId: post_corporations_corporation_id_assets_names
export def "corporations-assets-names create" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --body: record
]: any -> table<item_id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/assets/names/") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get corporation blueprints
#
# GET /corporations/{corporation_id}/blueprints/
# operationId: get_corporations_corporation_id_blueprints
export def "corporations-blueprints get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<item_id: int, location_flag: string, location_id: int, material_efficiency: int, quantity: int, runs: int, time_efficiency: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/blueprints/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List corporation bookmarks
#
# GET /corporations/{corporation_id}/bookmarks/
# operationId: get_corporations_corporation_id_bookmarks
export def "corporations-bookmarks get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<bookmark_id: int, coordinates: record<x: float, y: float, z: float>, created: string, creator_id: int, folder_id: int, item: record<item_id: int, type_id: int>, label: string, location_id: int, notes: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/bookmarks/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List corporation bookmark folders
#
# GET /corporations/{corporation_id}/bookmarks/folders/
# operationId: get_corporations_corporation_id_bookmarks_folders
export def "corporations-bookmarks-folders get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<creator_id: int, folder_id: int, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/bookmarks/folders/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation contacts
#
# GET /corporations/{corporation_id}/contacts/
# operationId: get_corporations_corporation_id_contacts
export def "corporations-contacts get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<contact_id: int, contact_type: string, is_watched: bool, label_ids: list<int>, standing: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/contacts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation contact labels
#
# GET /corporations/{corporation_id}/contacts/labels/
# operationId: get_corporations_corporation_id_contacts_labels
export def "corporations-contacts-labels get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<label_id: int, label_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/contacts/labels/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all corporation ALSC logs
#
# GET /corporations/{corporation_id}/containers/logs/
# operationId: get_corporations_corporation_id_containers_logs
export def "corporations-containers-logs get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<action: string, character_id: int, container_id: int, container_type_id: int, location_flag: string, location_id: int, logged_at: string, new_config_bitmask: int, old_config_bitmask: int, password_type: string, quantity: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/containers/logs/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation contracts
#
# GET /corporations/{corporation_id}/contracts/
# operationId: get_corporations_corporation_id_contracts
export def "corporations-contracts get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<acceptor_id: int, assignee_id: int, availability: string, buyout: float, collateral: float, contract_id: int, date_accepted: string, date_completed: string, date_expired: string, date_issued: string, days_to_complete: int, end_location_id: int, for_corporation: bool, issuer_corporation_id: int, issuer_id: int, price: float, reward: float, start_location_id: int, status: string, title: string, type: string, volume: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/contracts/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation contract bids
#
# GET /corporations/{corporation_id}/contracts/{contract_id}/bids/
# operationId: get_corporations_corporation_id_contracts_contract_id_bids
export def "corporations-contracts-bids get" [
  corporation_id: int
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<amount: float, bid_id: int, bidder_id: int, date_bid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id), contract_id: (encode-path-segment $contract_id)} | format pattern "/corporations/{corporation_id}/contracts/{contract_id}/bids/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation contract items
#
# GET /corporations/{corporation_id}/contracts/{contract_id}/items/
# operationId: get_corporations_corporation_id_contracts_contract_id_items
export def "corporations-contracts-items get" [
  corporation_id: int
  contract_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<is_included: bool, is_singleton: bool, quantity: int, raw_quantity: int, record_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id), contract_id: (encode-path-segment $contract_id)} | format pattern "/corporations/{corporation_id}/contracts/{contract_id}/items/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List corporation customs offices
#
# GET /corporations/{corporation_id}/customs_offices/
# operationId: get_corporations_corporation_id_customs_offices
export def "corporations-customs-offices get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<alliance_tax_rate: float, allow_access_with_standings: bool, allow_alliance_access: bool, bad_standing_tax_rate: float, corporation_tax_rate: float, excellent_standing_tax_rate: float, good_standing_tax_rate: float, neutral_standing_tax_rate: float, office_id: int, reinforce_exit_end: int, reinforce_exit_start: int, standing_level: string, system_id: int, terrible_standing_tax_rate: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/customs_offices/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation divisions
#
# GET /corporations/{corporation_id}/divisions/
# operationId: get_corporations_corporation_id_divisions
export def "corporations-divisions get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<hangar: table<division: int, name: string>, wallet: table<division: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/divisions/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation facilities
#
# GET /corporations/{corporation_id}/facilities/
# operationId: get_corporations_corporation_id_facilities
export def "corporations-facilities get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<facility_id: int, system_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/facilities/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Overview of a corporation involved in faction warfare
#
# GET /corporations/{corporation_id}/fw/stats/
# operationId: get_corporations_corporation_id_fw_stats
export def "corporations-fw-stats get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<enlisted_on: string, faction_id: int, kills: record<last_week: int, total: int, yesterday: int>, pilots: int, victory_points: record<last_week: int, total: int, yesterday: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/fw/stats/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation icon
#
# GET /corporations/{corporation_id}/icons/
# operationId: get_corporations_corporation_id_icons
export def "corporations-icons get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<px128x128: string, px256x256: string, px64x64: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/icons/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List corporation industry jobs
#
# GET /corporations/{corporation_id}/industry/jobs/
# operationId: get_corporations_corporation_id_industry_jobs
export def "corporations-industry-jobs get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --include-completed: oneof<nothing, bool> # Whether to retrieve completed corporation industry jobs. Only includes jobs from the past 90 days (default: false)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<activity_id: int, blueprint_id: int, blueprint_location_id: int, blueprint_type_id: int, completed_character_id: int, completed_date: string, cost: float, duration: int, end_date: string, facility_id: int, installer_id: int, job_id: int, licensed_runs: int, location_id: int, output_location_id: int, pause_date: string, probability: float, product_type_id: int, runs: int, start_date: string, status: string, successful_runs: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "include_completed" $include_completed "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/industry/jobs/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a corporation's recent kills and losses
#
# GET /corporations/{corporation_id}/killmails/recent/
# operationId: get_corporations_corporation_id_killmails_recent
export def "corporations-killmails-recent get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<killmail_hash: string, killmail_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/killmails/recent/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation medals
#
# GET /corporations/{corporation_id}/medals/
# operationId: get_corporations_corporation_id_medals
export def "corporations-medals get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<created_at: string, creator_id: int, description: string, medal_id: int, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/medals/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation issued medals
#
# GET /corporations/{corporation_id}/medals/issued/
# operationId: get_corporations_corporation_id_medals_issued
export def "corporations-medals-issued get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<character_id: int, issued_at: string, issuer_id: int, medal_id: int, reason: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/medals/issued/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation members
#
# GET /corporations/{corporation_id}/members/
# operationId: get_corporations_corporation_id_members
export def "corporations-members get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/members/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation member limit
#
# GET /corporations/{corporation_id}/members/limit/
# operationId: get_corporations_corporation_id_members_limit
export def "corporations-members-limit get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> int {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/members/limit/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation's members' titles
#
# GET /corporations/{corporation_id}/members/titles/
# operationId: get_corporations_corporation_id_members_titles
export def "corporations-members-titles get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<character_id: int, titles: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/members/titles/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Track corporation members
#
# GET /corporations/{corporation_id}/membertracking/
# operationId: get_corporations_corporation_id_membertracking
export def "corporations-membertracking get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<base_id: int, character_id: int, location_id: int, logoff_date: string, logon_date: string, ship_type_id: int, start_date: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/membertracking/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List open orders from a corporation
#
# GET /corporations/{corporation_id}/orders/
# operationId: get_corporations_corporation_id_orders
export def "corporations-orders get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<duration: int, escrow: float, is_buy_order: bool, issued: string, issued_by: int, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, type_id: int, volume_remain: int, volume_total: int, wallet_division: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/orders/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List historical orders from a corporation
#
# GET /corporations/{corporation_id}/orders/history/
# operationId: get_corporations_corporation_id_orders_history
export def "corporations-orders-history get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<duration: int, escrow: float, is_buy_order: bool, issued: string, issued_by: int, location_id: int, min_volume: int, order_id: int, price: float, range: string, region_id: int, state: string, type_id: int, volume_remain: int, volume_total: int, wallet_division: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/orders/history/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation member roles
#
# GET /corporations/{corporation_id}/roles/
# operationId: get_corporations_corporation_id_roles
export def "corporations-roles get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<character_id: int, grantable_roles: list<string>, grantable_roles_at_base: list<string>, grantable_roles_at_hq: list<string>, grantable_roles_at_other: list<string>, roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/roles/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation member roles history
#
# GET /corporations/{corporation_id}/roles/history/
# operationId: get_corporations_corporation_id_roles_history
export def "corporations-roles-history get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<changed_at: string, character_id: int, issuer_id: int, new_roles: list<string>, old_roles: list<string>, role_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/roles/history/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation shareholders
#
# GET /corporations/{corporation_id}/shareholders/
# operationId: get_corporations_corporation_id_shareholders
export def "corporations-shareholders get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<share_count: int, shareholder_id: int, shareholder_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/shareholders/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation standings
#
# GET /corporations/{corporation_id}/standings/
# operationId: get_corporations_corporation_id_standings
export def "corporations-standings get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<from_id: int, from_type: string, standing: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/standings/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation starbases (POSes)
#
# GET /corporations/{corporation_id}/starbases/
# operationId: get_corporations_corporation_id_starbases
export def "corporations-starbases list" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<moon_id: int, onlined_since: string, reinforced_until: string, starbase_id: int, state: string, system_id: int, type_id: int, unanchor_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/starbases/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get starbase (POS) detail
#
# GET /corporations/{corporation_id}/starbases/{starbase_id}/
# operationId: get_corporations_corporation_id_starbases_starbase_id
export def "corporations-starbases get" [
  corporation_id: int
  starbase_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --system-id: int # The solar system this starbase (POS) is located in, (format: int32)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<allow_alliance_members: bool, allow_corporation_members: bool, anchor: string, attack_if_at_war: bool, attack_if_other_security_status_dropping: bool, attack_security_status_threshold: float, attack_standing_threshold: float, fuel_bay_take: string, fuel_bay_view: string, fuels: table<quantity: int, type_id: int>, offline: string, online: string, unanchor: string, use_alliance_standings: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "system_id" $system_id "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id), starbase_id: (encode-path-segment $starbase_id)} | format pattern "/corporations/{corporation_id}/starbases/{starbase_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation structures
#
# GET /corporations/{corporation_id}/structures/
# operationId: get_corporations_corporation_id_structures
export def "corporations-structures get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<corporation_id: int, fuel_expires: string, next_reinforce_apply: string, next_reinforce_hour: int, next_reinforce_weekday: int, profile_id: int, reinforce_hour: int, reinforce_weekday: int, services: list<record>, state: string, state_timer_end: string, state_timer_start: string, structure_id: int, system_id: int, type_id: int, unanchors_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/structures/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation titles
#
# GET /corporations/{corporation_id}/titles/
# operationId: get_corporations_corporation_id_titles
export def "corporations-titles get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<grantable_roles: list<string>, grantable_roles_at_base: list<string>, grantable_roles_at_hq: list<string>, grantable_roles_at_other: list<string>, name: string, roles: list<string>, roles_at_base: list<string>, roles_at_hq: list<string>, roles_at_other: list<string>, title_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/titles/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a corporation's wallet balance
#
# GET /corporations/{corporation_id}/wallets/
# operationId: get_corporations_corporation_id_wallets
export def "corporations-wallets get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<balance: float, division: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/corporations/{corporation_id}/wallets/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation wallet journal
#
# GET /corporations/{corporation_id}/wallets/{division}/journal/
# operationId: get_corporations_corporation_id_wallets_division_journal
export def "corporations-wallets-journal get" [
  corporation_id: int
  division: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<amount: float, balance: float, context_id: int, context_id_type: string, date: string, description: string, first_party_id: int, id: int, reason: string, ref_type: string, second_party_id: int, tax: float, tax_receiver_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id), division: (encode-path-segment $division)} | format pattern "/corporations/{corporation_id}/wallets/{division}/journal/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get corporation wallet transactions
#
# GET /corporations/{corporation_id}/wallets/{division}/transactions/
# operationId: get_corporations_corporation_id_wallets_division_transactions
export def "corporations-wallets-transactions get" [
  corporation_id: int
  division: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --from-id: int # Only show journal entries happened before the transaction referenced by this id (format: int64)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<client_id: int, date: string, is_buy: bool, journal_ref_id: int, location_id: int, quantity: int, transaction_id: int, type_id: int, unit_price: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "from_id" $from_id "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id), division: (encode-path-segment $division)} | format pattern "/corporations/{corporation_id}/wallets/{division}/transactions/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attributes
#
# GET /dogma/attributes/
# operationId: get_dogma_attributes
export def "dogma-attributes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dogma/attributes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get attribute information
#
# GET /dogma/attributes/{attribute_id}/
# operationId: get_dogma_attributes_attribute_id
export def "dogma-attributes get" [
  attribute_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<attribute_id: int, default_value: float, description: string, display_name: string, high_is_good: bool, icon_id: int, name: string, published: bool, stackable: bool, unit_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({attribute_id: (encode-path-segment $attribute_id)} | format pattern "/dogma/attributes/{attribute_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get dynamic item information
#
# GET /dogma/dynamic/items/{type_id}/{item_id}/
# operationId: get_dogma_dynamic_items_type_id_item_id
export def "dogma-dynamic-items get" [
  type_id: int
  item_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<created_by: int, dogma_attributes: table<attribute_id: int, value: float>, dogma_effects: table<effect_id: int, is_default: bool>, mutator_type_id: int, source_type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id), item_id: (encode-path-segment $item_id)} | format pattern "/dogma/dynamic/items/{type_id}/{item_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effects
#
# GET /dogma/effects/
# operationId: get_dogma_effects
export def "dogma-effects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dogma/effects/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get effect information
#
# GET /dogma/effects/{effect_id}/
# operationId: get_dogma_effects_effect_id
export def "dogma-effects get" [
  effect_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<description: string, disallow_auto_repeat: bool, discharge_attribute_id: int, display_name: string, duration_attribute_id: int, effect_category: int, effect_id: int, electronic_chance: bool, falloff_attribute_id: int, icon_id: int, is_assistance: bool, is_offensive: bool, is_warp_safe: bool, modifiers: table<domain: string, effect_id: int, func: string, modified_attribute_id: int, modifying_attribute_id: int, operator: int>, name: string, post_expression: int, pre_expression: int, published: bool, range_attribute_id: int, range_chance: bool, tracking_speed_attribute_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({effect_id: (encode-path-segment $effect_id)} | format pattern "/dogma/effects/{effect_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get fleet information
#
# GET /fleets/{fleet_id}/
# operationId: get_fleets_fleet_id
export def "fleets get" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<is_free_move: bool, is_registered: bool, is_voice_enabled: bool, motd: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id)} | format pattern "/fleets/{fleet_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update fleet
#
# PUT /fleets/{fleet_id}/
# operationId: put_fleets_fleet_id
export def "fleets update" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --is-free-move: oneof<nothing, bool> # Should free-move be enabled in the fleet
  --motd: string # New fleet MOTD in CCP flavoured HTML
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id)} | format pattern "/fleets/{fleet_id}/") $qp)
  let req_body = {"is_free_move": $is_free_move, "motd": $motd} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get fleet members
#
# GET /fleets/{fleet_id}/members/
# operationId: get_fleets_fleet_id_members
export def "fleets-members get" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --qp-token: string # Access token to use if unable to set a header
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<character_id: int, join_time: string, role: string, role_name: string, ship_type_id: int, solar_system_id: int, squad_id: int, station_id: int, takes_fleet_warp: bool, wing_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id)} | format pattern "/fleets/{fleet_id}/members/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create fleet invitation
#
# POST /fleets/{fleet_id}/members/
# operationId: post_fleets_fleet_id_members
export def "fleets-members create" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  character_id: int # The character you want to invite (format: int32)
  role: string@role-completer # If a character is invited with the `fleet_commander` role, neither `wing_id` or `squad_id` should be specified. If a character is invited with the `wing_commander` role, only `wing_id` should be specified. If a character is invited with the `squad_commander` role, both `wing_id` and `squad_id` should be specified. If a character is invited with the `squad_member` role, `wing_id` and `squad_id` should either both be specified or not specified at all. If they aren’t specified, the invited character will join any squad with available positions.
  --squad-id: int # squad_id integer (format: int64)
  --wing-id: int # wing_id integer (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id)} | format pattern "/fleets/{fleet_id}/members/") $qp)
  let req_body = {"character_id": $character_id, "role": $role, "squad_id": $squad_id, "wing_id": $wing_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Kick fleet member
#
# DELETE /fleets/{fleet_id}/members/{member_id}/
# operationId: delete_fleets_fleet_id_members_member_id
export def "fleets-members delete" [
  fleet_id: int
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id), member_id: (encode-path-segment $member_id)} | format pattern "/fleets/{fleet_id}/members/{member_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move fleet member
#
# PUT /fleets/{fleet_id}/members/{member_id}/
# operationId: put_fleets_fleet_id_members_member_id
export def "fleets-members update" [
  fleet_id: int
  member_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  role: string@role-completer # If a character is moved to the `fleet_commander` role, neither `wing_id` or `squad_id` should be specified. If a character is moved to the `wing_commander` role, only `wing_id` should be specified. If a character is moved to the `squad_commander` role, both `wing_id` and `squad_id` should be specified. If a character is moved to the `squad_member` role, both `wing_id` and `squad_id` should be specified.
  --squad-id: int # squad_id integer (format: int64)
  --wing-id: int # wing_id integer (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id), member_id: (encode-path-segment $member_id)} | format pattern "/fleets/{fleet_id}/members/{member_id}/") $qp)
  let req_body = {"role": $role, "squad_id": $squad_id, "wing_id": $wing_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete fleet squad
#
# DELETE /fleets/{fleet_id}/squads/{squad_id}/
# operationId: delete_fleets_fleet_id_squads_squad_id
export def "fleets-squads delete" [
  fleet_id: int
  squad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id), squad_id: (encode-path-segment $squad_id)} | format pattern "/fleets/{fleet_id}/squads/{squad_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rename fleet squad
#
# PUT /fleets/{fleet_id}/squads/{squad_id}/
# operationId: put_fleets_fleet_id_squads_squad_id
export def "fleets-squads update" [
  fleet_id: int
  squad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  name: string # name string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id), squad_id: (encode-path-segment $squad_id)} | format pattern "/fleets/{fleet_id}/squads/{squad_id}/") $qp)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get fleet wings
#
# GET /fleets/{fleet_id}/wings/
# operationId: get_fleets_fleet_id_wings
export def "fleets-wings get" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --qp-token: string # Access token to use if unable to set a header
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<id: int, name: string, squads: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id)} | format pattern "/fleets/{fleet_id}/wings/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create fleet wing
#
# POST /fleets/{fleet_id}/wings/
# operationId: post_fleets_fleet_id_wings
export def "fleets-wings create" [
  fleet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> record<wing_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id)} | format pattern "/fleets/{fleet_id}/wings/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete fleet wing
#
# DELETE /fleets/{fleet_id}/wings/{wing_id}/
# operationId: delete_fleets_fleet_id_wings_wing_id
export def "fleets-wings delete" [
  fleet_id: int
  wing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id), wing_id: (encode-path-segment $wing_id)} | format pattern "/fleets/{fleet_id}/wings/{wing_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rename fleet wing
#
# PUT /fleets/{fleet_id}/wings/{wing_id}/
# operationId: put_fleets_fleet_id_wings_wing_id
export def "fleets-wings update" [
  fleet_id: int
  wing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  name: string # name string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id), wing_id: (encode-path-segment $wing_id)} | format pattern "/fleets/{fleet_id}/wings/{wing_id}/") $qp)
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create fleet squad
#
# POST /fleets/{fleet_id}/wings/{wing_id}/squads/
# operationId: post_fleets_fleet_id_wings_wing_id_squads
export def "fleets-wings-squads create" [
  fleet_id: int
  wing_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> record<squad_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({fleet_id: (encode-path-segment $fleet_id), wing_id: (encode-path-segment $wing_id)} | format pattern "/fleets/{fleet_id}/wings/{wing_id}/squads/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of the top factions in faction warfare
#
# GET /fw/leaderboards/
# operationId: get_fw_leaderboards
export def "fw-leaderboards get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fw/leaderboards/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of the top pilots in faction warfare
#
# GET /fw/leaderboards/characters/
# operationId: get_fw_leaderboards_characters
export def "fw-leaderboards-characters get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fw/leaderboards/characters/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of the top corporations in faction warfare
#
# GET /fw/leaderboards/corporations/
# operationId: get_fw_leaderboards_corporations
export def "fw-leaderboards-corporations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<kills: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>, victory_points: record<active_total: list<record>, last_week: list<record>, yesterday: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fw/leaderboards/corporations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# An overview of statistics about factions involved in faction warfare
#
# GET /fw/stats/
# operationId: get_fw_stats
export def "fw-stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<faction_id: int, kills: record<last_week: int, total: int, yesterday: int>, pilots: int, systems_controlled: int, victory_points: record<last_week: int, total: int, yesterday: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fw/stats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ownership of faction warfare systems
#
# GET /fw/systems/
# operationId: get_fw_systems
export def "fw-systems get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<contested: string, occupier_faction_id: int, owner_faction_id: int, solar_system_id: int, victory_points: int, victory_points_threshold: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fw/systems/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Data about which NPC factions are at war
#
# GET /fw/wars/
# operationId: get_fw_wars
export def "fw-wars get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<against_id: int, faction_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/fw/wars/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List incursions
#
# GET /incursions/
# operationId: get_incursions
export def "incursions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<constellation_id: int, faction_id: int, has_boss: bool, infested_solar_systems: list<int>, influence: float, staging_solar_system_id: int, state: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/incursions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List industry facilities
#
# GET /industry/facilities/
# operationId: get_industry_facilities
export def "industry-facilities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<facility_id: int, owner_id: int, region_id: int, solar_system_id: int, tax: float, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/industry/facilities/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List solar system cost indices
#
# GET /industry/systems/
# operationId: get_industry_systems
export def "industry-systems get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<cost_indices: list<record>, solar_system_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/industry/systems/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List insurance levels
#
# GET /insurance/prices/
# operationId: get_insurance_prices
export def "insurance-prices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<levels: list<record>, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/insurance/prices/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a single killmail
#
# GET /killmails/{killmail_id}/{killmail_hash}/
# operationId: get_killmails_killmail_id_killmail_hash
export def "killmails get" [
  killmail_id: int
  killmail_hash: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<attackers: table<alliance_id: int, character_id: int, corporation_id: int, damage_done: int, faction_id: int, final_blow: bool, security_status: float, ship_type_id: int, weapon_type_id: int>, killmail_id: int, killmail_time: string, moon_id: int, solar_system_id: int, victim: record<alliance_id: int, character_id: int, corporation_id: int, damage_taken: int, faction_id: int, items: list<record>, position: record<x: float, y: float, z: float>, ship_type_id: int>, war_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({killmail_id: (encode-path-segment $killmail_id), killmail_hash: (encode-path-segment $killmail_hash)} | format pattern "/killmails/{killmail_id}/{killmail_hash}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List loyalty store offers
#
# GET /loyalty/stores/{corporation_id}/offers/
# operationId: get_loyalty_stores_corporation_id_offers
export def "loyalty-stores-offers get" [
  corporation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<ak_cost: int, isk_cost: int, lp_cost: int, offer_id: int, quantity: int, required_items: list<record>, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({corporation_id: (encode-path-segment $corporation_id)} | format pattern "/loyalty/stores/{corporation_id}/offers/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item groups
#
# GET /markets/groups/
# operationId: get_markets_groups
export def "markets-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/markets/groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item group information
#
# GET /markets/groups/{market_group_id}/
# operationId: get_markets_groups_market_group_id
export def "markets-groups get" [
  market_group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<description: string, market_group_id: int, name: string, parent_group_id: int, types: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({market_group_id: (encode-path-segment $market_group_id)} | format pattern "/markets/groups/{market_group_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List market prices
#
# GET /markets/prices/
# operationId: get_markets_prices
export def "markets-prices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<adjusted_price: float, average_price: float, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/markets/prices/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List orders in a structure
#
# GET /markets/structures/{structure_id}/
# operationId: get_markets_structures_structure_id
export def "markets-structures get" [
  structure_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<duration: int, is_buy_order: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, type_id: int, volume_remain: int, volume_total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({structure_id: (encode-path-segment $structure_id)} | format pattern "/markets/structures/{structure_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List historical market statistics in a region
#
# GET /markets/{region_id}/history/
# operationId: get_markets_region_id_history
export def "markets-history get" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --type-id: int # Return statistics for this type (format: int32)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<average: float, date: string, highest: float, lowest: float, order_count: int, volume: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "type_id" $type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({region_id: (encode-path-segment $region_id)} | format pattern "/markets/{region_id}/history/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List orders in a region
#
# GET /markets/{region_id}/orders/
# operationId: get_markets_region_id_orders
export def "markets-orders get" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --order-type: string@order-type-completer # Filter buy/sell orders, return all orders by default. If you query without type_id, we always return both buy and sell orders (default: all)
  --page: int # Which page of results to return (format: int32, default: 1)
  --type-id: int # Return orders only for this type (format: int32)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<duration: int, is_buy_order: bool, issued: string, location_id: int, min_volume: int, order_id: int, price: float, range: string, system_id: int, type_id: int, volume_remain: int, volume_total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "order_type" $order_type "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "type_id" $type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({region_id: (encode-path-segment $region_id)} | format pattern "/markets/{region_id}/orders/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List type IDs relevant to a market
#
# GET /markets/{region_id}/types/
# operationId: get_markets_region_id_types
export def "markets-types get" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({region_id: (encode-path-segment $region_id)} | format pattern "/markets/{region_id}/types/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get opportunities groups
#
# GET /opportunities/groups/
# operationId: get_opportunities_groups
export def "opportunities-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/opportunities/groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get opportunities group
#
# GET /opportunities/groups/{group_id}/
# operationId: get_opportunities_groups_group_id
export def "opportunities-groups get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<connected_groups: list<int>, description: string, group_id: int, name: string, notification: string, required_tasks: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/opportunities/groups/{group_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get opportunities tasks
#
# GET /opportunities/tasks/
# operationId: get_opportunities_tasks
export def "opportunities-tasks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/opportunities/tasks/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get opportunities task
#
# GET /opportunities/tasks/{task_id}/
# operationId: get_opportunities_tasks_task_id
export def "opportunities-tasks get" [
  task_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<description: string, name: string, notification: string, task_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({task_id: (encode-path-segment $task_id)} | format pattern "/opportunities/tasks/{task_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get route
#
# GET /route/{origin}/{destination}/
# operationId: get_route_origin_destination
export def "route get" [
  origin: int
  destination: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --avoid: list<int> # avoid solar system ID(s)
  --connections: list # connected solar system pairs
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --flag: string@flag-completer # route security preference (default: shortest)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "avoid" $avoid "csv") (serialize-qp "connections" $connections "csv") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "flag" $flag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({origin: (encode-path-segment $origin), destination: (encode-path-segment $destination)} | format pattern "/route/{origin}/{destination}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search on a string
#
# GET /search/
# operationId: get_search
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categories: list<string> # Type of entities to search for
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --search: string # The string to search on
  --strict: oneof<nothing, bool> # Whether the search should be a strict match (default: false)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<agent: list<int>, alliance: list<int>, character: list<int>, constellation: list<int>, corporation: list<int>, faction: list<int>, inventory_type: list<int>, region: list<int>, solar_system: list<int>, station: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "categories" $categories "csv") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "strict" $strict "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sovereignty campaigns
#
# GET /sovereignty/campaigns/
# operationId: get_sovereignty_campaigns
export def "sovereignty-campaigns get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<attackers_score: float, campaign_id: int, constellation_id: int, defender_id: int, defender_score: float, event_type: string, participants: list<record>, solar_system_id: int, start_time: string, structure_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sovereignty/campaigns/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sovereignty of systems
#
# GET /sovereignty/map/
# operationId: get_sovereignty_map
export def "sovereignty-map get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<alliance_id: int, corporation_id: int, faction_id: int, system_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sovereignty/map/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List sovereignty structures
#
# GET /sovereignty/structures/
# operationId: get_sovereignty_structures
export def "sovereignty-structures get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<alliance_id: int, solar_system_id: int, structure_id: int, structure_type_id: int, vulnerability_occupancy_level: float, vulnerable_end_time: string, vulnerable_start_time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sovereignty/structures/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the uptime and player counts
#
# GET /status/
# operationId: get_status
export def "status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<players: int, server_version: string, start_time: string, vip: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/status/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Autopilot Waypoint
#
# POST /ui/autopilot/waypoint/
# operationId: post_ui_autopilot_waypoint
export def "ui-autopilot-waypoint create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --add-to-beginning: oneof<nothing, bool> # Whether this solar system should be added to the beginning of all waypoints (default: false)
  --clear-other-waypoints: oneof<nothing, bool> # Whether clean other waypoints beforing adding this one (default: false)
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --destination-id: int # The destination to travel to, can be solar system, station or structure's id (format: int64)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "add_to_beginning" $add_to_beginning "scalar") (serialize-qp "clear_other_waypoints" $clear_other_waypoints "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "destination_id" $destination_id "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui/autopilot/waypoint/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open Contract Window
#
# POST /ui/openwindow/contract/
# operationId: post_ui_openwindow_contract
export def "ui-openwindow-contract create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contract-id: int # The contract to open (format: int32)
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contract_id" $contract_id "scalar") (serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui/openwindow/contract/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open Information Window
#
# POST /ui/openwindow/information/
# operationId: post_ui_openwindow_information
export def "ui-openwindow-information create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --target-id: int # The target to open (format: int32)
  --qp-token: string # Access token to use if unable to set a header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "target_id" $target_id "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui/openwindow/information/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open Market Details
#
# POST /ui/openwindow/marketdetails/
# operationId: post_ui_openwindow_marketdetails
export def "ui-openwindow-marketdetails create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --type-id: int # The item type to open in market window (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "type_id" $type_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui/openwindow/marketdetails/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open New Mail Window
#
# POST /ui/openwindow/newmail/
# operationId: post_ui_openwindow_newmail
export def "ui-openwindow-newmail create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  body: string # body string
  recipients: list<int> # recipients array
  subject: string # subject string
  --to-corp-or-alliance-id: int # to_corp_or_alliance_id integer (format: int32)
  --to-mailing-list-id: int # Corporations, alliances and mailing lists are all types of mailing groups. You may only send to one mailing group, at a time, so you may fill out either this field or the to_corp_or_alliance_ids field (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ui/openwindow/newmail/" $qp)
  let req_body = {"body": $body, "recipients": $recipients, "subject": $subject, "to_corp_or_alliance_id": $to_corp_or_alliance_id, "to_mailing_list_id": $to_mailing_list_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get ancestries
#
# GET /universe/ancestries/
# operationId: get_universe_ancestries
export def "universe-ancestries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<bloodline_id: int, description: string, icon_id: int, id: int, name: string, short_description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/ancestries/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get asteroid belt information
#
# GET /universe/asteroid_belts/{asteroid_belt_id}/
# operationId: get_universe_asteroid_belts_asteroid_belt_id
export def "universe-asteroid-belts get" [
  asteroid_belt_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<name: string, position: record<x: float, y: float, z: float>, system_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({asteroid_belt_id: (encode-path-segment $asteroid_belt_id)} | format pattern "/universe/asteroid_belts/{asteroid_belt_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get bloodlines
#
# GET /universe/bloodlines/
# operationId: get_universe_bloodlines
export def "universe-bloodlines get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<bloodline_id: int, charisma: int, corporation_id: int, description: string, intelligence: int, memory: int, name: string, perception: int, race_id: int, ship_type_id: int, willpower: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/bloodlines/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item categories
#
# GET /universe/categories/
# operationId: get_universe_categories
export def "universe-categories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/categories/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item category information
#
# GET /universe/categories/{category_id}/
# operationId: get_universe_categories_category_id
export def "universe-categories get" [
  category_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<category_id: int, groups: list<int>, name: string, published: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/universe/categories/{category_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get constellations
#
# GET /universe/constellations/
# operationId: get_universe_constellations
export def "universe-constellations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/constellations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get constellation information
#
# GET /universe/constellations/{constellation_id}/
# operationId: get_universe_constellations_constellation_id
export def "universe-constellations get" [
  constellation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<constellation_id: int, name: string, position: record<x: float, y: float, z: float>, region_id: int, systems: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({constellation_id: (encode-path-segment $constellation_id)} | format pattern "/universe/constellations/{constellation_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get factions
#
# GET /universe/factions/
# operationId: get_universe_factions
export def "universe-factions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<corporation_id: int, description: string, faction_id: int, is_unique: bool, militia_corporation_id: int, name: string, size_factor: float, solar_system_id: int, station_count: int, station_system_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/factions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get graphics
#
# GET /universe/graphics/
# operationId: get_universe_graphics
export def "universe-graphics list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/graphics/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get graphic information
#
# GET /universe/graphics/{graphic_id}/
# operationId: get_universe_graphics_graphic_id
export def "universe-graphics get" [
  graphic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<collision_file: string, graphic_file: string, graphic_id: int, icon_folder: string, sof_dna: string, sof_fation_name: string, sof_hull_name: string, sof_race_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({graphic_id: (encode-path-segment $graphic_id)} | format pattern "/universe/graphics/{graphic_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item groups
#
# GET /universe/groups/
# operationId: get_universe_groups
export def "universe-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/groups/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item group information
#
# GET /universe/groups/{group_id}/
# operationId: get_universe_groups_group_id
export def "universe-groups get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<category_id: int, group_id: int, name: string, published: bool, types: list<int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/universe/groups/{group_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk names to IDs
#
# POST /universe/ids/
# operationId: post_universe_ids
export def "universe-ids create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --body: record
]: any -> record<agents: table<id: int, name: string>, alliances: table<id: int, name: string>, characters: table<id: int, name: string>, constellations: table<id: int, name: string>, corporations: table<id: int, name: string>, factions: table<id: int, name: string>, inventory_types: table<id: int, name: string>, regions: table<id: int, name: string>, stations: table<id: int, name: string>, systems: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/ids/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get moon information
#
# GET /universe/moons/{moon_id}/
# operationId: get_universe_moons_moon_id
export def "universe-moons get" [
  moon_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<moon_id: int, name: string, position: record<x: float, y: float, z: float>, system_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({moon_id: (encode-path-segment $moon_id)} | format pattern "/universe/moons/{moon_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get names and categories for a set of ID's
#
# POST /universe/names/
# operationId: post_universe_names
export def "universe-names create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --body: record
]: any -> table<category: string, id: int, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/names/" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get planet information
#
# GET /universe/planets/{planet_id}/
# operationId: get_universe_planets_planet_id
export def "universe-planets get" [
  planet_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<name: string, planet_id: int, position: record<x: float, y: float, z: float>, system_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({planet_id: (encode-path-segment $planet_id)} | format pattern "/universe/planets/{planet_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get character races
#
# GET /universe/races/
# operationId: get_universe_races
export def "universe-races get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<alliance_id: int, description: string, name: string, race_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/races/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get regions
#
# GET /universe/regions/
# operationId: get_universe_regions
export def "universe-regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/regions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get region information
#
# GET /universe/regions/{region_id}/
# operationId: get_universe_regions_region_id
export def "universe-regions get" [
  region_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<constellations: list<int>, description: string, name: string, region_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({region_id: (encode-path-segment $region_id)} | format pattern "/universe/regions/{region_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get schematic information
#
# GET /universe/schematics/{schematic_id}/
# operationId: get_universe_schematics_schematic_id
export def "universe-schematics get" [
  schematic_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<cycle_time: int, schematic_name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({schematic_id: (encode-path-segment $schematic_id)} | format pattern "/universe/schematics/{schematic_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get stargate information
#
# GET /universe/stargates/{stargate_id}/
# operationId: get_universe_stargates_stargate_id
export def "universe-stargates get" [
  stargate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<destination: record<stargate_id: int, system_id: int>, name: string, position: record<x: float, y: float, z: float>, stargate_id: int, system_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({stargate_id: (encode-path-segment $stargate_id)} | format pattern "/universe/stargates/{stargate_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get star information
#
# GET /universe/stars/{star_id}/
# operationId: get_universe_stars_star_id
export def "universe-stars get" [
  star_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<age: int, luminosity: float, name: string, radius: int, solar_system_id: int, spectral_class: string, temperature: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({star_id: (encode-path-segment $star_id)} | format pattern "/universe/stars/{star_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get station information
#
# GET /universe/stations/{station_id}/
# operationId: get_universe_stations_station_id
export def "universe-stations get" [
  station_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<max_dockable_ship_volume: float, name: string, office_rental_cost: float, owner: int, position: record<x: float, y: float, z: float>, race_id: int, reprocessing_efficiency: float, reprocessing_stations_take: float, services: list<string>, station_id: int, system_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({station_id: (encode-path-segment $station_id)} | format pattern "/universe/stations/{station_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all public structures
#
# GET /universe/structures/
# operationId: get_universe_structures
export def "universe-structures list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --filter: string@filter-completer # Only list public structures that have this service online
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/structures/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get structure information
#
# GET /universe/structures/{structure_id}/
# operationId: get_universe_structures_structure_id
export def "universe-structures get" [
  structure_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --qp-token: string # Access token to use if unable to set a header
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<name: string, owner_id: int, position: record<x: float, y: float, z: float>, solar_system_id: int, type_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({structure_id: (encode-path-segment $structure_id)} | format pattern "/universe/structures/{structure_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get system jumps
#
# GET /universe/system_jumps/
# operationId: get_universe_system_jumps
export def "universe-system-jumps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<ship_jumps: int, system_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/system_jumps/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get system kills
#
# GET /universe/system_kills/
# operationId: get_universe_system_kills
export def "universe-system-kills get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<npc_kills: int, pod_kills: int, ship_kills: int, system_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/system_kills/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get solar systems
#
# GET /universe/systems/
# operationId: get_universe_systems
export def "universe-systems list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/systems/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get solar system information
#
# GET /universe/systems/{system_id}/
# operationId: get_universe_systems_system_id
export def "universe-systems get" [
  system_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<constellation_id: int, name: string, planets: table<asteroid_belts: list, moons: list, planet_id: int>, position: record<x: float, y: float, z: float>, security_class: string, security_status: float, star_id: int, stargates: list<int>, stations: list<int>, system_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({system_id: (encode-path-segment $system_id)} | format pattern "/universe/systems/{system_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get types
#
# GET /universe/types/
# operationId: get_universe_types
export def "universe-types list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/universe/types/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get type information
#
# GET /universe/types/{type_id}/
# operationId: get_universe_types_type_id
export def "universe-types get" [
  type_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --language: string@language-completer # Language to use in the response, takes precedence over Accept-Language (default: en-us)
  --accept-language: string@accept-language-completer # Language to use in the response
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<capacity: float, description: string, dogma_attributes: table<attribute_id: int, value: float>, dogma_effects: table<effect_id: int, is_default: bool>, graphic_id: int, group_id: int, icon_id: int, market_group_id: int, mass: float, name: string, packaged_volume: float, portion_size: int, published: bool, radius: float, type_id: int, volume: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "language" $language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type_id: (encode-path-segment $type_id)} | format pattern "/universe/types/{type_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List wars
#
# GET /wars/
# operationId: get_wars
export def "wars list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --max-war-id: int # Only return wars with ID smaller than this (format: int32)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> list<int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "max_war_id" $max_war_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/wars/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get war information
#
# GET /wars/{war_id}/
# operationId: get_wars_war_id
export def "wars get" [
  war_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> record<aggressor: record<alliance_id: int, corporation_id: int, isk_destroyed: float, ships_killed: int>, allies: table<alliance_id: int, corporation_id: int>, declared: string, defender: record<alliance_id: int, corporation_id: int, isk_destroyed: float, ships_killed: int>, finished: string, id: int, mutual: bool, open_for_allies: bool, retracted: string, started: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({war_id: (encode-path-segment $war_id)} | format pattern "/wars/{war_id}/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List kills for a war
#
# GET /wars/{war_id}/killmails/
# operationId: get_wars_war_id_killmails
export def "wars-killmails get" [
  war_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --datasource: string@datasource-completer # The server name you would like data from (default: tranquility)
  --page: int # Which page of results to return (format: int32, default: 1)
  --if-none-match: string # ETag from a previous request. A 304 will be returned if this matches the current ETag
]: nothing -> table<killmail_hash: string, killmail_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "datasource" $datasource "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({war_id: (encode-path-segment $war_id)} | format pattern "/wars/{war_id}/killmails/") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
