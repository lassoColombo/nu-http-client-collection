# Auto-generated client for PokéAPI v2.7.0
# Source: https://raw.githubusercontent.com/PokeAPI/pokeapi/master/openapi.yml
# Auth: --token flag or $env.POK_API_TOKEN

const BASE_URL = "https://pokeapi.co"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o POK_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "cookie-sessionid" => { {headers: {Cookie: $"sessionid=($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://pokeapi.co"] }
def auth-scheme-completer [] { ["basic" "cookie-sessionid"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "ability list" } } | get name | first)
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

# Abilities provide passive effects for Pokémon in battle or in the overworld. Pokémon have multiple possible abilities but can have only one ability at a time. Check out [Bulbapedia](http://bulbapedia.bulbagarden.net/wiki/Ability) for greater detail.
#
# GET /api/v2/ability/
# operationId: ability_list
export def "ability list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/ability/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Abilities provide passive effects for Pokémon in battle or in the overworld. Pokémon have multiple possible abilities but can have only one ability at a time. Check out [Bulbapedia](http://bulbapedia.bulbagarden.net/wiki/Ability) for greater detail.
#
# GET /api/v2/ability/{id}/
# operationId: ability_retrieve
export def "ability get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, is_main_series: bool, generation: record<name: string, url: string>, names: table<name: string, language: record>, effect_entries: table<effect: string, short_effect: string, language: record>, effect_changes: table<version_group: record, effect_entries: list>, flavor_text_entries: table<flavor_text: string, language: record, version_group: record>, pokemon: table<is_hidden: bool, slot: int, pokemon: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/ability/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List berries
#
# GET /api/v2/berry/
# operationId: berry_list
export def "berry list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/berry/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a berry
#
# GET /api/v2/berry/{id}/
# operationId: berry_retrieve
export def "berry get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, growth_time: int, max_harvest: int, natural_gift_power: int, size: int, smoothness: int, soil_dryness: int, firmness: record<name: string, url: string>, flavors: table<potency: int, flavor: record>, item: record<name: string, url: string>, natural_gift_type: record<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/berry/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List berry firmness
#
# GET /api/v2/berry-firmness/
# operationId: berry_firmness_list
export def "berry-firmness list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/berry-firmness/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get berry by firmness
#
# GET /api/v2/berry-firmness/{id}/
# operationId: berry_firmness_retrieve
export def "berry-firmness get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, berries: table<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/berry-firmness/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List berry flavors
#
# GET /api/v2/berry-flavor/
# operationId: berry_flavor_list
export def "berry-flavor list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/berry-flavor/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get berries by flavor
#
# GET /api/v2/berry-flavor/{id}/
# operationId: berry_flavor_retrieve
export def "berry-flavor get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, berries: table<potency: int, berry: record>, contest_type: record<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/berry-flavor/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List charecterictics
#
# GET /api/v2/characteristic/
# operationId: characteristic_list
export def "characteristic list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/characteristic/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get characteristic
#
# GET /api/v2/characteristic/{id}/
# operationId: characteristic_retrieve
export def "characteristic get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, gene_modulo: int, possible_values: list<int>, highest_stat: record<name: string, url: string>, descriptions: table<description: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/characteristic/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List contest types
#
# GET /api/v2/contest-type/
# operationId: contest_type_list
export def "contest-type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/contest-type/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contest type
#
# GET /api/v2/contest-type/{id}/
# operationId: contest_type_retrieve
export def "contest-type get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, berry_flavor: record<name: string, url: string>, names: table<name: string, color: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/contest-type/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List contest effects
#
# GET /api/v2/contest-effect/
# operationId: contest_effect_list
export def "contest-effect list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/contest-effect/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contest effect
#
# GET /api/v2/contest-effect/{id}/
# operationId: contest_effect_retrieve
export def "contest-effect get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, appeal: int, jam: int, effect_entries: table<effect: string, language: record>, flavor_text_entries: table<flavor_text: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/contest-effect/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List egg groups
#
# GET /api/v2/egg-group/
# operationId: egg_group_list
export def "egg-group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/egg-group/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get egg group
#
# GET /api/v2/egg-group/{id}/
# operationId: egg_group_retrieve
export def "egg-group get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, names: table<name: string, language: record>, pokemon_species: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/egg-group/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List encounter methods
#
# GET /api/v2/encounter-method/
# operationId: encounter_method_list
export def "encounter-method list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/encounter-method/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get encounter method
#
# GET /api/v2/encounter-method/{id}/
# operationId: encounter_method_retrieve
export def "encounter-method get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, order: int, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/encounter-method/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List encounter conditions
#
# GET /api/v2/encounter-condition/
# operationId: encounter_condition_list
export def "encounter-condition list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/encounter-condition/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get encounter condition
#
# GET /api/v2/encounter-condition/{id}/
# operationId: encounter_condition_retrieve
export def "encounter-condition get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, values: table<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/encounter-condition/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List encounter condition values
#
# GET /api/v2/encounter-condition-value/
# operationId: encounter_condition_value_list
export def "encounter-condition-value list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/encounter-condition-value/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get encounter condition value
#
# GET /api/v2/encounter-condition-value/{id}/
# operationId: encounter_condition_value_retrieve
export def "encounter-condition-value get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, condition: record<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/encounter-condition-value/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List evolution chains
#
# GET /api/v2/evolution-chain/
# operationId: evolution_chain_list
export def "evolution-chain list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/evolution-chain/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get evolution chain
#
# GET /api/v2/evolution-chain/{id}/
# operationId: evolution_chain_retrieve
export def "evolution-chain get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, baby_trigger_item: record<name: string, url: string>, chain: record<evolution_details: list<any>, evolves_to: list<record>, is_baby: bool, species: record<name: string, url: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/evolution-chain/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List evolution triggers
#
# GET /api/v2/evolution-trigger/
# operationId: evolution_trigger_list
export def "evolution-trigger list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/evolution-trigger/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get evolution trigger
#
# GET /api/v2/evolution-trigger/{id}/
# operationId: evolution_trigger_retrieve
export def "evolution-trigger get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, names: table<name: string, language: record>, pokemon_species: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/evolution-trigger/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List genrations
#
# GET /api/v2/generation/
# operationId: generation_list
export def "generation list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/generation/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get genration
#
# GET /api/v2/generation/{id}/
# operationId: generation_retrieve
export def "generation get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, abilities: table<name: string, url: string>, main_region: record<name: string, url: string>, moves: table<name: string, url: string>, names: table<name: string, language: record>, pokemon_species: table<name: string, url: string>, types: table<name: string, url: string>, version_groups: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/generation/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List genders
#
# GET /api/v2/gender/
# operationId: gender_list
export def "gender list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/gender/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get gender
#
# GET /api/v2/gender/{id}/
# operationId: gender_retrieve
export def "gender get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, pokemon_species_details: table<rate: int, pokemon_species: record>, required_for_evolution: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/gender/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List growth rates
#
# GET /api/v2/growth-rate/
# operationId: growth_rate_list
export def "growth-rate list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/growth-rate/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get growth rate
#
# GET /api/v2/growth-rate/{id}/
# operationId: growth_rate_retrieve
export def "growth-rate get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, formula: string, descriptions: table<description: string, language: record>, levels: table<level: int, experience: int>, pokemon_species: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/growth-rate/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List items
#
# GET /api/v2/item/
# operationId: item_list
export def "item list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/item/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item
#
# GET /api/v2/item/{id}/
# operationId: item_retrieve
export def "item get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, cost: int, fling_power: int, fling_effect: record<name: string, url: string>, attributes: table<name: string, url: string>, category: record<name: string, url: string>, effect_entries: table<effect: string, short_effect: string, language: record>, flavor_text_entries: table<text: string, version_group: record, language: record>, game_indices: table<game_index: int, generation: record>, names: table<name: string, language: record>, held_by_pokemon: table<pokemon: record, version_details: list>, sprites: record<default: string>, baby_trigger_for: record<url: string>, machines: table<machine: string, version_group: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/item/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List item categories
#
# GET /api/v2/item-category/
# operationId: item_category_list
export def "item-category list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/item-category/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item category
#
# GET /api/v2/item-category/{id}/
# operationId: item_category_retrieve
export def "item-category get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, items: table<name: string, url: string>, names: table<name: string, language: record>, pocket: record<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/item-category/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List item attributes
#
# GET /api/v2/item-attribute/
# operationId: item_attribute_list
export def "item-attribute list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/item-attribute/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item attribute
#
# GET /api/v2/item-attribute/{id}/
# operationId: item_attribute_retrieve
export def "item-attribute get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, descriptions: table<description: string, language: record>, items: table<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/item-attribute/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List item fling effects
#
# GET /api/v2/item-fling-effect/
# operationId: item_fling_effect_list
export def "item-fling-effect list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/item-fling-effect/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item fling effect
#
# GET /api/v2/item-fling-effect/{id}/
# operationId: item_fling_effect_retrieve
export def "item-fling-effect get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, effect_entries: table<effect: string, language: record>, items: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/item-fling-effect/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List item pockets
#
# GET /api/v2/item-pocket/
# operationId: item_pocket_list
export def "item-pocket list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/item-pocket/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get item pocket
#
# GET /api/v2/item-pocket/{id}/
# operationId: item_pocket_retrieve
export def "item-pocket get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, categories: table<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/item-pocket/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List languages
#
# GET /api/v2/language/
# operationId: language_list
export def "language list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/language/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get language
#
# GET /api/v2/language/{id}/
# operationId: language_retrieve
export def "language get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, official: bool, iso639: string, iso3166: string, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/language/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List locations
#
# GET /api/v2/location/
# operationId: location_list
export def "location list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/location/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get location
#
# GET /api/v2/location/{id}/
# operationId: location_retrieve
export def "location get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, region: record<name: string, url: string>, names: table<name: string, language: record>, game_indices: table<game_index: int, generation: record>, areas: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/location/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List location areas
#
# GET /api/v2/location-area/
# operationId: location_area_list
export def "location-area list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/location-area/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get location area
#
# GET /api/v2/location-area/{id}/
# operationId: location_area_retrieve
export def "location-area get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, game_index: int, encounter_method_rates: table<encounter_method: record, version_details: list>, location: record<name: string, url: string>, names: table<name: string, language: record>, pokemon_encounters: table<pokemon: record, version_details: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/location-area/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List machines
#
# GET /api/v2/machine/
# operationId: machine_list
export def "machine list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/machine/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get machine
#
# GET /api/v2/machine/{id}/
# operationId: machine_retrieve
export def "machine get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, item: record<name: string, url: string>, version_group: record<name: string, url: string>, move: record<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/machine/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns metadata about the current deployed version of the API, including the git commit hash, deploy date, and tag (if any).
#
# GET /api/v2/meta/
# operationId: meta_list
export def "meta list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<deploy_date: string, hash: string, tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/meta/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List moves
#
# GET /api/v2/move/
# operationId: move_list
export def "move list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/move/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get move
#
# GET /api/v2/move/{id}/
# operationId: move_retrieve
export def "move get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, accuracy: int, effect_chance: int, pp: int, priority: int, power: int, contest_combos: record<normal: record<use_before: list, use_after: list>, super: record<use_before: list, use_after: list>>, contest_type: record<name: string, url: string>, contest_effect: record<url: string>, damage_class: record<name: string, url: string>, effect_entries: table<effect: string, short_effect: string, language: record>, effect_changes: table<effect_entries: list, version_group: record>, generation: record<name: string, url: string>, meta: record<ailment: record<name: string, url: string>, category: record<name: string, url: string>, min_hits: int, max_hits: int, min_turns: int, max_turns: int, drain: int, healing: int, crit_rate: int, ailment_chance: int, flinch_chance: int, stat_chance: int>, names: table<name: string, language: record>, past_values: table<accuracy: int, power: int, pp: int, effect_chance: int, effect_entries: list, type: record, version_group: record>, stat_changes: table<change: int, stat: record>, super_contest_effect: record<url: string>, target: record<name: string, url: string>, type: record<name: string, url: string>, machines: table<machine: record, version_group: record>, flavor_text_entries: table<flavor_text: string, language: record, version_group: record>, learned_by_pokemon: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/move/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List move meta ailments
#
# GET /api/v2/move-ailment/
# operationId: move_ailment_list
export def "move-ailment list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/move-ailment/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get move meta ailment
#
# GET /api/v2/move-ailment/{id}/
# operationId: move_ailment_retrieve
export def "move-ailment get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, moves: table<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/move-ailment/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List move battle styles
#
# GET /api/v2/move-battle-style/
# operationId: move_battle_style_list
export def "move-battle-style list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/move-battle-style/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get move battle style
#
# GET /api/v2/move-battle-style/{id}/
# operationId: move_battle_style_retrieve
export def "move-battle-style get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/move-battle-style/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List move meta categories
#
# GET /api/v2/move-category/
# operationId: move_category_list
export def "move-category list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/move-category/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get move meta category
#
# GET /api/v2/move-category/{id}/
# operationId: move_category_retrieve
export def "move-category get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, descriptions: table<description: string, language: record>, moves: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/move-category/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List move damage classes
#
# GET /api/v2/move-damage-class/
# operationId: move_damage_class_list
export def "move-damage-class list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/move-damage-class/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get move damage class
#
# GET /api/v2/move-damage-class/{id}/
# operationId: move_damage_class_retrieve
export def "move-damage-class get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, descriptions: table<description: string, language: record>, moves: table<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/move-damage-class/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List move learn methods
#
# GET /api/v2/move-learn-method/
# operationId: move_learn_method_list
export def "move-learn-method list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/move-learn-method/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get move learn method
#
# GET /api/v2/move-learn-method/{id}/
# operationId: move_learn_method_retrieve
export def "move-learn-method get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, names: table<name: string, language: record>, descriptions: table<description: string, language: record>, version_groups: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/move-learn-method/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List move targets
#
# GET /api/v2/move-target/
# operationId: move_target_list
export def "move-target list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/move-target/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get move target
#
# GET /api/v2/move-target/{id}/
# operationId: move_target_retrieve
export def "move-target get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, descriptions: table<description: string, language: record>, moves: table<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/move-target/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List natures
#
# GET /api/v2/nature/
# operationId: nature_list
export def "nature list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/nature/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get nature
#
# GET /api/v2/nature/{id}/
# operationId: nature_retrieve
export def "nature get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, decreased_stat: record<name: string, url: string>, increased_stat: record<name: string, url: string>, likes_flavor: record<name: string, url: string>, hates_flavor: record<name: string, url: string>, berries: table<name: string, url: string>, pokeathlon_stat_changes: table<max_change: int, pokeathlon_stat: record>, move_battle_style_preferences: table<low_hp_preference: int, high_hp_preference: int, move_battle_style: record>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/nature/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pal park areas
#
# GET /api/v2/pal-park-area/
# operationId: pal_park_area_list
export def "pal-park-area list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pal-park-area/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pal park area
#
# GET /api/v2/pal-park-area/{id}/
# operationId: pal_park_area_retrieve
export def "pal-park-area get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, names: table<name: string, language: record>, pokemon_encounters: table<base_score: int, pokemon_species: record, rate: int>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pal-park-area/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pokedex
#
# GET /api/v2/pokedex/
# operationId: pokedex_list
export def "pokedex list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pokedex/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokedex
#
# GET /api/v2/pokedex/{id}/
# operationId: pokedex_retrieve
export def "pokedex get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, is_main_series: bool, descriptions: table<description: string, language: record>, names: table<name: string, language: record>, pokemon_entries: table<entry_number: int, pokemon_species: record>, region: record<name: string, url: string>, version_groups: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokedex/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pokemon
#
# GET /api/v2/pokemon/
# operationId: pokemon_list
export def "pokemon list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pokemon/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokemon
#
# GET /api/v2/pokemon/{id}/
# operationId: pokemon_retrieve
export def "pokemon get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, base_experience: int, height: int, is_default: bool, order: int, weight: int, abilities: table<ability: record, is_hidden: bool, slot: int>, past_abilities: table<abilities: list, generation: record>, forms: table<name: string, url: string>, game_indices: table<game_index: int, version: record>, held_items: table<item: record, version_details: list>, location_area_encounters: string, moves: table<move: record, version_group_details: list>, species: record<name: string, url: string>, sprites: record<front_default: string>, cries: record<latest: string, legacy: string>, stats: table<base_stat: int, effort: int, stat: record>, past_stats: table<generation: record, stats: list>, types: table<slot: int, type: record>, past_types: table<generation: record, types: list>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokemon/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pokemon colors
#
# GET /api/v2/pokemon-color/
# operationId: pokemon_color_list
export def "pokemon-color list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pokemon-color/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokemon color
#
# GET /api/v2/pokemon-color/{id}/
# operationId: pokemon_color_retrieve
export def "pokemon-color get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, names: table<name: string, language: record>, pokemon_species: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokemon-color/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pokemon forms
#
# GET /api/v2/pokemon-form/
# operationId: pokemon_form_list
export def "pokemon-form list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pokemon-form/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokemon form
#
# GET /api/v2/pokemon-form/{id}/
# operationId: pokemon_form_retrieve
export def "pokemon-form get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, order: int, form_order: int, is_default: bool, is_battle_only: bool, is_mega: bool, form_name: string, pokemon: record<name: string, url: string>, sprites: record<default: string>, version_group: record<name: string, url: string>, form_names: table<language: record, name: string>, names: table<language: record, name: string>, types: table<slot: int, type: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokemon-form/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pokemom habitas
#
# GET /api/v2/pokemon-habitat/
# operationId: pokemon_habitat_list
export def "pokemon-habitat list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pokemon-habitat/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokemom habita
#
# GET /api/v2/pokemon-habitat/{id}/
# operationId: pokemon_habitat_retrieve
export def "pokemon-habitat get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, names: table<name: string, language: record>, pokemon_species: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokemon-habitat/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pokemon shapes
#
# GET /api/v2/pokemon-shape/
# operationId: pokemon_shape_list
export def "pokemon-shape list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pokemon-shape/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokemon shape
#
# GET /api/v2/pokemon-shape/{id}/
# operationId: pokemon_shape_retrieve
export def "pokemon-shape get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, awesome_names: table<awesome_name: string, language: record>, names: table<url: string, name: string>, pokemon_species: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokemon-shape/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pokemon species
#
# GET /api/v2/pokemon-species/
# operationId: pokemon_species_list
export def "pokemon-species list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pokemon-species/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokemon species
#
# GET /api/v2/pokemon-species/{id}/
# operationId: pokemon_species_retrieve
export def "pokemon-species get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, order: int, gender_rate: int, capture_rate: int, base_happiness: int, is_baby: bool, is_legendary: bool, is_mythical: bool, hatch_counter: int, has_gender_differences: bool, forms_switchable: bool, growth_rate: record<name: string, url: string>, pokedex_numbers: table<entry_number: int, pokedex: record>, egg_groups: table<name: string, url: string>, color: record<name: string, url: string>, shape: record<name: string, url: string>, evolves_from_species: record<name: string, url: string>, evolution_chain: record<url: string>, habitat: record<name: string, url: string>, generation: record<name: string, url: string>, names: table<language: record, name: string>, pal_park_encounters: table<area: record, base_score: int, rate: int>, form_descriptions: table<description: string, language: record>, flavor_text_entries: table<flavor_text: string, language: record, version: record>, genera: table<genus: string, language: record>, varieties: table<is_default: bool, pokemon: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokemon-species/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List pokeathlon stats
#
# GET /api/v2/pokeathlon-stat/
# operationId: pokeathlon_stat_list
export def "pokeathlon-stat list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/pokeathlon-stat/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokeathlon stat
#
# GET /api/v2/pokeathlon-stat/{id}/
# operationId: pokeathlon_stat_retrieve
export def "pokeathlon-stat get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, affecting_natures: record<decrease: list<record>, increase: list<record>>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokeathlon-stat/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List regions
#
# GET /api/v2/region/
# operationId: region_list
export def "region list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/region/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get region
#
# GET /api/v2/region/{id}/
# operationId: region_retrieve
export def "region get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, locations: table<name: string, url: string>, main_generation: any, names: table<name: string, language: record>, pokedexes: table<name: string, url: string>, version_groups: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/region/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List stats
#
# GET /api/v2/stat/
# operationId: stat_list
export def "stat list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/stat/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get stat
#
# GET /api/v2/stat/{id}/
# operationId: stat_retrieve
export def "stat get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, game_index: int, is_battle_only: bool, affecting_moves: record<increase: list<record>, decrease: list<record>>, affecting_natures: record<increase: list<record>, decrease: list<record>>, affecting_items: table<name: string, url: string>, characteristics: table<url: string>, move_damage_class: record<name: string, url: string>, names: table<name: string, language: record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/stat/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List super contest effects
#
# GET /api/v2/super-contest-effect/
# operationId: super_contest_effect_list
export def "super-contest-effect list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/super-contest-effect/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get super contest effect
#
# GET /api/v2/super-contest-effect/{id}/
# operationId: super_contest_effect_retrieve
export def "super-contest-effect get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, appeal: int, flavor_text_entries: table<flavor_text: string, language: record>, moves: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/super-contest-effect/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List types
#
# GET /api/v2/type/
# operationId: type_list
export def "type list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/type/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get types
#
# GET /api/v2/type/{id}/
# operationId: type_retrieve
export def "type get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, damage_relations: record<no_damage_to: list<record>, half_damage_to: list<record>, double_damage_to: list<record>, no_damage_from: list<record>, half_damage_from: list<record>, double_damage_from: list<record>>, past_damage_relations: table<generation: record, damage_relations: record>, game_indices: table<game_index: int, generation: record>, generation: record<name: string, url: string>, move_damage_class: record<name: string, url: string>, names: table<name: string, language: record>, pokemon: table<slot: int, pokemon: record>, moves: table<name: string, url: string>, sprites: record> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/type/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List versions
#
# GET /api/v2/version/
# operationId: version_list
export def "version list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/version/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get version
#
# GET /api/v2/version/{id}/
# operationId: version_retrieve
export def "version get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, names: table<name: string, language: record>, version_group: record<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/version/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List version groups
#
# GET /api/v2/version-group/
# operationId: version_group_list
export def "version-group list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # Number of results to return per page.
  --offset: int # The initial index from which to return the results.
  --q: string # > Only available locally and not at [pokeapi.co](https://pokeapi.co/docs/v2) Case-insensitive query applied on the `name` property. 
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "q" $q "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/version-group/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get version group
#
# GET /api/v2/version-group/{id}/
# operationId: version_group_retrieve
export def "version-group get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, name: string, order: int, generation: record<name: string, url: string>, move_learn_methods: table<name: string, url: string>, pokedexes: table<name: string, url: string>, regions: table<name: string, url: string>, versions: table<name: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/version-group/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pokemon encounter
#
# GET /api/v2/pokemon/{pokemon_id}/encounters
# operationId: pokemon_encounters_retrieve
export def "pokemon-encounters get" [
  pokemon_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<location_area: record<name: string, url: string>, version_details: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-sessionid"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/pokemon/($pokemon_id)/encounters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
