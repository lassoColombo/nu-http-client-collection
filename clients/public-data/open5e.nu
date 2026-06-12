# Auto-generated client for Open5e vdevelopment (v1)
# Source: https://api.open5e.com/schema/?format=json
# Auth: --token flag or $env.OPEN5E_TOKEN

const BASE_URL = "https://api.open5e.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OPEN5E_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.open5e.com" "https://api-beta.open5e.com" "http://localhost:8000"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["MISC" "SOURCE"] }
def distance-unit-completer [] { ["any" "feet" "ft" "miles"] }
def weight-unit-completer [] { ["kg" "lb"] }
def duration-completer [] { ["1 day" "1 hour" "1 hour or until triggered" "1 hour/caster level" "1 minute" "1 minute" "1 minute or 1 hour" "1 minute, or until expended" "1 minute, until expended" "1 round" "1 turn" "1 year" "10 days" "10 hours" "10 minutes" "10 rounds" "12 hours" "13 days" "1d10 hours" "1d4+2 rounds" "2 hours" "2 rounds" "2-12 hours" "24 hours" "24 hours or until the target attempts a third death saving throw" "3 days" "3 hours" "3 rounds" "30 days" "4 rounds" "5 days" "5 minutes" "5 rounds" "6 hours" "6 rounds" "7 days" "8 hours" "concentration + 1 round" "instantaneous" "instantaneous or special" "permanent" "permanent until discharged" "permanent; one generation" "special" "until cured or dispelled" "until destroyed" "until dispelled" "until dispelled or destroyed" "until dispelled or triggered" "up to 1 hour" "up to 1 minute" "up to 8 hours"] }
def casting-time-completer [] { ["10minutes" "12hours" "1hour" "1minute" "1week" "24hours" "4hours" "5minutes" "7hours" "8hours" "9hours" "action" "bonus-action" "reaction" "round" "turn"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "items list" } } | get name | first)
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

# list: API endpoint for returning a list of items.  retrieve: API endpoint for returning a particular item.
#
# GET /v2/items/
# operationId: items_list
export def "items list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --name-iexact: string
  --name-icontains: string
  --desc-icontains: string
  --cost: float
  --cost-range: list # Multiple values may be separated by commas.
  --cost-gt: float
  --cost-gte: float
  --cost-lt: float
  --cost-lte: float
  --weight: float
  --weight-range: list # Multiple values may be separated by commas.
  --weight-gt: float
  --weight-gte: float
  --weight-lt: float
  --weight-lte: float
  --category-in: list # Multiple values may be separated by commas.
  --category: string # Unique key for the Item.
  --document-in: list # Multiple values may be separated by commas.
  --document: string # Unique key for the Document.
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --is-weapon: oneof<nothing, bool> # Weapons
  --is-armor: oneof<nothing, bool> # Armor
  --is-light: oneof<nothing, bool> # Light Weapons
  --is-versatile: oneof<nothing, bool> # Versatile Weapons
  --is-thrown: oneof<nothing, bool> # Thrown Weapons
  --is-finesse: oneof<nothing, bool> # Finesse Weapons
  --is-two-handed: oneof<nothing, bool> # Two-handed Weapons
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, desc: string, category: record, weapon: record, armor: record, size: record, weight: string, weight_unit: string, cost: string, document: record, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "desc__icontains" $desc_icontains "scalar") (serialize-qp "cost" $cost "scalar") (serialize-qp "cost__range" $cost_range "csv") (serialize-qp "cost__gt" $cost_gt "scalar") (serialize-qp "cost__gte" $cost_gte "scalar") (serialize-qp "cost__lt" $cost_lt "scalar") (serialize-qp "cost__lte" $cost_lte "scalar") (serialize-qp "weight" $weight "scalar") (serialize-qp "weight__range" $weight_range "csv") (serialize-qp "weight__gt" $weight_gt "scalar") (serialize-qp "weight__gte" $weight_gte "scalar") (serialize-qp "weight__lt" $weight_lt "scalar") (serialize-qp "weight__lte" $weight_lte "scalar") (serialize-qp "category__in" $category_in "csv") (serialize-qp "category" $category "scalar") (serialize-qp "document__in" $document_in "csv") (serialize-qp "document" $document "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "is_weapon" $is_weapon "scalar") (serialize-qp "is_armor" $is_armor "scalar") (serialize-qp "is_light" $is_light "scalar") (serialize-qp "is_versatile" $is_versatile "scalar") (serialize-qp "is_thrown" $is_thrown "scalar") (serialize-qp "is_finesse" $is_finesse "scalar") (serialize-qp "is_two_handed" $is_two_handed "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/items/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of items.  retrieve: API endpoint for returning a particular item.
#
# GET /v2/items/{key}/
# operationId: items_retrieve
export def "items get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, desc: string, category: record<name: string, key: string>, weapon: record<name: string, key: string, damage_type: record<name: string, key: string>, damage_dice: string, properties: list<record>, is_melee: string, is_simple: bool, is_martial: bool, is_improvised: bool, distance_unit: string>, armor: record<name: string, key: string, category: string, ac_base: int, ac_display: string, ac_add_dexmod: bool, ac_cap_dexmod: int, grants_stealth_disadvantage: bool, strength_score_required: int>, size: record<name: string, key: string>, weight: string, weight_unit: string, cost: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/items/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of magic items.  retrieve: API endpoint for returning a particular magic item.
#
# GET /v2/magicitems/
# operationId: magicitems_list
export def "magicitems list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --name-iexact: string
  --name-icontains: string
  --desc-icontains: string
  --cost: float
  --cost-range: list # Multiple values may be separated by commas.
  --cost-gt: float
  --cost-gte: float
  --cost-lt: float
  --cost-lte: float
  --weight: float
  --weight-range: list # Multiple values may be separated by commas.
  --weight-gt: float
  --weight-gte: float
  --weight-lt: float
  --weight-lte: float
  --category-in: list # Multiple values may be separated by commas.
  --category: string # Unique key for the Item.
  --document-in: list # Multiple values may be separated by commas.
  --document: string # Unique key for the Document.
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --rarity: string # Unique key for the Item.
  --rarity-in: list # Multiple values may be separated by commas.
  --requires-attunement: oneof<nothing, bool> # Requires Attunement
  --is-weapon: oneof<nothing, bool> # Weapons
  --is-armor: oneof<nothing, bool> # Armor
  --is-light: oneof<nothing, bool> # Light Weapons
  --is-versatile: oneof<nothing, bool> # Versatile Weapons
  --is-thrown: oneof<nothing, bool> # Thrown Weapons
  --is-finesse: oneof<nothing, bool> # Finesse Weapons
  --is-two-handed: oneof<nothing, bool> # Two-handed Weapons
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, desc: string, category: record, rarity: record, is_magic_item: string, weapon: record, armor: record, size: record, weight: string, weight_unit: string, cost: string, requires_attunement: bool, attunement_detail: string, document: record, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "desc__icontains" $desc_icontains "scalar") (serialize-qp "cost" $cost "scalar") (serialize-qp "cost__range" $cost_range "csv") (serialize-qp "cost__gt" $cost_gt "scalar") (serialize-qp "cost__gte" $cost_gte "scalar") (serialize-qp "cost__lt" $cost_lt "scalar") (serialize-qp "cost__lte" $cost_lte "scalar") (serialize-qp "weight" $weight "scalar") (serialize-qp "weight__range" $weight_range "csv") (serialize-qp "weight__gt" $weight_gt "scalar") (serialize-qp "weight__gte" $weight_gte "scalar") (serialize-qp "weight__lt" $weight_lt "scalar") (serialize-qp "weight__lte" $weight_lte "scalar") (serialize-qp "category__in" $category_in "csv") (serialize-qp "category" $category "scalar") (serialize-qp "document__in" $document_in "csv") (serialize-qp "document" $document "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "rarity" $rarity "scalar") (serialize-qp "rarity__in" $rarity_in "csv") (serialize-qp "requires_attunement" $requires_attunement "scalar") (serialize-qp "is_weapon" $is_weapon "scalar") (serialize-qp "is_armor" $is_armor "scalar") (serialize-qp "is_light" $is_light "scalar") (serialize-qp "is_versatile" $is_versatile "scalar") (serialize-qp "is_thrown" $is_thrown "scalar") (serialize-qp "is_finesse" $is_finesse "scalar") (serialize-qp "is_two_handed" $is_two_handed "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/magicitems/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of magic items.  retrieve: API endpoint for returning a particular magic item.
#
# GET /v2/magicitems/{key}/
# operationId: magicitems_retrieve
export def "magicitems get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, desc: string, category: record<name: string, key: string>, rarity: record<name: string, key: string, rank: int>, is_magic_item: string, weapon: record<name: string, key: string, damage_type: record<name: string, key: string>, damage_dice: string, properties: list<record>, is_melee: string, is_simple: bool, is_martial: bool, is_improvised: bool, distance_unit: string>, armor: record<name: string, key: string, category: string, ac_base: int, ac_display: string, ac_add_dexmod: bool, ac_cap_dexmod: int, grants_stealth_disadvantage: bool, strength_score_required: int>, size: record<name: string, key: string>, weight: string, weight_unit: string, cost: string, requires_attunement: bool, attunement_detail: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/magicitems/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API Endpoint for returning a set of itemsets.  retrieve: API endpoint for return a particular itemset.
#
# GET /v2/itemsets/
# operationId: itemsets_list
export def "itemsets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, items: list, name: string, desc: string, document: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/itemsets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API Endpoint for returning a set of itemsets.  retrieve: API endpoint for return a particular itemset.
#
# GET /v2/itemsets/{key}/
# operationId: itemsets_retrieve
export def "itemsets get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, items: table<name: string, key: string, url: string>, name: string, desc: string, document: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/itemsets/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API Endpoint for returning a set of item categories.  retrieve: API endpoint for return a particular item categories.
#
# GET /v2/itemcategories/
# operationId: itemcategories_list
export def "itemcategories list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, document: record, name: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/itemcategories/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API Endpoint for returning a set of item categories.  retrieve: API endpoint for return a particular item categories.
#
# GET /v2/itemcategories/{key}/
# operationId: itemcategories_retrieve
export def "itemcategories get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, name: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/itemcategories/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of documents. retrieve: API endpoint for returning a particular document.
#
# GET /v2/documents/
# operationId: documents_list
export def "documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --desc: string
  --key: string
  --type: string@type-completer # Whether this Document is a published data source, or general resources  * `SOURCE` - Source * `MISC` - Miscellaneous
  --licenses: list # Unique key for the License.
  --publisher: string # Unique key for the publishing organization.
  --gamesystem: string # Unique key for the gamesystem the document was published for.
  --author: string
  --display-name: string
  --publication-date: string # format: date-time
  --permalink: string
  --distance-unit: string@distance-unit-completer # What distance unit the relevant field uses.  * `feet` - feet * `ft` - ft * `miles` - miles * `any` - any (nullable)
  --weight-unit: string@weight-unit-completer # What weight unit the relevant field uses.  * `lb` - lb * `kg` - kg (nullable)
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, licenses: list, publisher: record, gamesystem: record, display_name: string, name: string, desc: string, type: string, author: string, publication_date: string, permalink: string, distance_unit: string, weight_unit: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "licenses" $licenses "multi") (serialize-qp "publisher" $publisher "scalar") (serialize-qp "gamesystem" $gamesystem "scalar") (serialize-qp "author" $author "scalar") (serialize-qp "display_name" $display_name "scalar") (serialize-qp "publication_date" $publication_date "scalar") (serialize-qp "permalink" $permalink "scalar") (serialize-qp "distance_unit" $distance_unit "scalar") (serialize-qp "weight_unit" $weight_unit "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/documents/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of documents. retrieve: API endpoint for returning a particular document.
#
# GET /v2/documents/{key}/
# operationId: documents_retrieve
export def "documents get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, licenses: table<name: string, key: string>, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, display_name: string, name: string, desc: string, type: string, author: string, publication_date: string, permalink: string, distance_unit: string, weight_unit: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/documents/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of licenses. retrieve: API endpoint for returning a particular license.
#
# GET /v2/licenses/
# operationId: licenses_list
export def "licenses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --desc: string
  --key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, desc: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "desc" $desc "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/licenses/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of licenses. retrieve: API endpoint for returning a particular license.
#
# GET /v2/licenses/{key}/
# operationId: licenses_retrieve
export def "licenses get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, desc: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/licenses/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of publishers. retrieve: API endpoint for returning a particular publisher.
#
# GET /v2/publishers/
# operationId: publishers_list
export def "publishers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/publishers/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of publishers. retrieve: API endpoint for returning a particular publisher.
#
# GET /v2/publishers/{key}/
# operationId: publishers_retrieve
export def "publishers get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/publishers/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of weapons. retrieve: API endpoint for returning a particular weapon.
#
# GET /v2/weapons/
# operationId: weapons_list
export def "weapons list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --name-iexact: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --damage-dice-in: list # Multiple values may be separated by commas.
  --damage-dice-iexact: string
  --is-light: oneof<nothing, bool> # Is Light
  --is-versatile: oneof<nothing, bool> # Is Versatile
  --is-thrown: oneof<nothing, bool> # Is Thrown
  --is-finesse: oneof<nothing, bool> # Is Finesse
  --is-two-handed: oneof<nothing, bool> # Is Two-handed
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, document: record, properties: string, damage_type: record, ranged_attack_possible: string, range_melee: string, distance_unit: string, name: string, damage_dice: string, range: int, long_range: int, is_simple: bool, is_improvised: bool, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "damage_dice__in" $damage_dice_in "csv") (serialize-qp "damage_dice__iexact" $damage_dice_iexact "scalar") (serialize-qp "is_light" $is_light "scalar") (serialize-qp "is_versatile" $is_versatile "scalar") (serialize-qp "is_thrown" $is_thrown "scalar") (serialize-qp "is_finesse" $is_finesse "scalar") (serialize-qp "is_two_handed" $is_two_handed "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/weapons/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of weapons. retrieve: API endpoint for returning a particular weapon.
#
# GET /v2/weapons/{key}/
# operationId: weapons_retrieve
export def "weapons get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, properties: string, damage_type: record<name: string, key: string>, ranged_attack_possible: string, range_melee: string, distance_unit: string, name: string, damage_dice: string, range: int, long_range: int, is_simple: bool, is_improvised: bool, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/weapons/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of armor. retrieve: API endpoint for returning a particular armor.
#
# GET /v2/armor/
# operationId: armor_list
export def "armor list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --grants-stealth-disadvantage: oneof<nothing, bool>
  --strength-score-required: int
  --strength-score-required-lt: int
  --strength-score-required-lte: int
  --strength-score-required-gt: int
  --strength-score-required-gte: int
  --ac-base: int
  --ac-base-lt: int
  --ac-base-lte: int
  --ac-base-gt: int
  --ac-base-gte: int
  --ac-add-dexmod: oneof<nothing, bool>
  --ac-cap-dexmod: int
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, ac_display: string, category: string, document: record, name: string, grants_stealth_disadvantage: bool, strength_score_required: int, ac_base: int, ac_add_dexmod: bool, ac_cap_dexmod: int, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "grants_stealth_disadvantage" $grants_stealth_disadvantage "scalar") (serialize-qp "strength_score_required" $strength_score_required "scalar") (serialize-qp "strength_score_required__lt" $strength_score_required_lt "scalar") (serialize-qp "strength_score_required__lte" $strength_score_required_lte "scalar") (serialize-qp "strength_score_required__gt" $strength_score_required_gt "scalar") (serialize-qp "strength_score_required__gte" $strength_score_required_gte "scalar") (serialize-qp "ac_base" $ac_base "scalar") (serialize-qp "ac_base__lt" $ac_base_lt "scalar") (serialize-qp "ac_base__lte" $ac_base_lte "scalar") (serialize-qp "ac_base__gt" $ac_base_gt "scalar") (serialize-qp "ac_base__gte" $ac_base_gte "scalar") (serialize-qp "ac_add_dexmod" $ac_add_dexmod "scalar") (serialize-qp "ac_cap_dexmod" $ac_cap_dexmod "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/armor/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of armor. retrieve: API endpoint for returning a particular armor.
#
# GET /v2/armor/{key}/
# operationId: armor_retrieve
export def "armor get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, ac_display: string, category: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, name: string, grants_stealth_disadvantage: bool, strength_score_required: int, ac_base: int, ac_add_dexmod: bool, ac_cap_dexmod: int, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/armor/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# " list: API Endpoint for returning a set of gamesystems.  retrieve: API endpoint for return a particular gamesystem.
#
# GET /v2/gamesystems/
# operationId: gamesystems_list
export def "gamesystems list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, desc: string, content_prefix: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/gamesystems/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# " list: API Endpoint for returning a set of gamesystems.  retrieve: API endpoint for return a particular gamesystem.
#
# GET /v2/gamesystems/{key}/
# operationId: gamesystems_retrieve
export def "gamesystems get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, desc: string, content_prefix: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/gamesystems/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of backgrounds. retrieve: API endpoint for returning a particular background.
#
# GET /v2/backgrounds/
# operationId: backgrounds_list
export def "backgrounds list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-icontains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, benefits: list, document: record, name: string, desc: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/backgrounds/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of backgrounds. retrieve: API endpoint for returning a particular background.
#
# GET /v2/backgrounds/{key}/
# operationId: backgrounds_retrieve
export def "backgrounds get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, benefits: table<name: string, desc: string, type: string>, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, name: string, desc: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/backgrounds/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of feats. retrieve: API endpoint for returning a particular feat.
#
# GET /v2/feats/
# operationId: feats_list
export def "feats list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-icontains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, has_prerequisite: bool, benefits: list, document: record, name: string, desc: string, prerequisite: string, type: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/feats/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of feats. retrieve: API endpoint for returning a particular feat.
#
# GET /v2/feats/{key}/
# operationId: feats_retrieve
export def "feats get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, has_prerequisite: bool, benefits: table<desc: string>, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, name: string, desc: string, prerequisite: string, type: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/feats/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of species. retrieve: API endpoint for returning a particular species.
#
# GET /v2/species/
# operationId: species_list
export def "species list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-icontains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --subspecies-of-isnull: oneof<nothing, bool>
  --subspecies-of-key--in: list # Multiple values may be separated by commas.
  --subspecies-of-key--iexact: string
  --subspecies-of-key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, is_subspecies: bool, document: record, traits: list, name: string, desc: string, subspecies_of: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "subspecies_of__isnull" $subspecies_of_isnull "scalar") (serialize-qp "subspecies_of__key__in" $subspecies_of_key__in "csv") (serialize-qp "subspecies_of__key__iexact" $subspecies_of_key__iexact "scalar") (serialize-qp "subspecies_of__key" $subspecies_of_key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/species/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of species. retrieve: API endpoint for returning a particular species.
#
# GET /v2/species/{key}/
# operationId: species_retrieve
export def "species get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, is_subspecies: bool, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, traits: table<name: string, desc: string, type: string, order: int>, name: string, desc: string, subspecies_of: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/species/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of creatures. retrieve: API endpoint for returning a particular creature.
#
# GET /v2/creatures/
# operationId: creatures_list
export def "creatures list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-icontains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --size: string # Unique key for the Item.
  --category: string
  --category-iexact: string
  --subcategory: string
  --subcategory-iexact: string
  --type: string # Unique key for the Item.
  --challenge-rating: float # format: float
  --challenge-rating-lt: float # format: float
  --challenge-rating-lte: float # format: float
  --challenge-rating-gt: float # format: float
  --challenge-rating-gte: float # format: float
  --armor-class: int
  --armor-class-lt: int
  --armor-class-lte: int
  --armor-class-gt: int
  --armor-class-gte: int
  --ability-score-strength: int
  --ability-score-strength-lt: int
  --ability-score-strength-lte: int
  --ability-score-strength-gt: int
  --ability-score-strength-gte: int
  --ability-score-dexterity: int
  --ability-score-dexterity-lt: int
  --ability-score-dexterity-lte: int
  --ability-score-dexterity-gt: int
  --ability-score-dexterity-gte: int
  --ability-score-constitution: int
  --ability-score-constitution-lt: int
  --ability-score-constitution-lte: int
  --ability-score-constitution-gt: int
  --ability-score-constitution-gte: int
  --ability-score-intelligence: int
  --ability-score-intelligence-lt: int
  --ability-score-intelligence-lte: int
  --ability-score-intelligence-gt: int
  --ability-score-intelligence-gte: int
  --ability-score-wisdom: int
  --ability-score-wisdom-lt: int
  --ability-score-wisdom-lte: int
  --ability-score-wisdom-gt: int
  --ability-score-wisdom-gte: int
  --ability-score-charisma: int
  --ability-score-charisma-lt: int
  --ability-score-charisma-lte: int
  --ability-score-charisma-gt: int
  --ability-score-charisma-gte: int
  --saving-throw-strength-isnull: oneof<nothing, bool>
  --saving-throw-dexterity-isnull: oneof<nothing, bool>
  --saving-throw-constitution-isnull: oneof<nothing, bool>
  --saving-throw-intelligence-isnull: oneof<nothing, bool>
  --saving-throw-wisdom-isnull: oneof<nothing, bool>
  --saving-throw-charisma-isnull: oneof<nothing, bool>
  --skill-bonus-acrobatics-isnull: oneof<nothing, bool>
  --skill-bonus-animal-handling-isnull: oneof<nothing, bool>
  --skill-bonus-arcana-isnull: oneof<nothing, bool>
  --skill-bonus-athletics-isnull: oneof<nothing, bool>
  --skill-bonus-deception-isnull: oneof<nothing, bool>
  --skill-bonus-history-isnull: oneof<nothing, bool>
  --skill-bonus-insight-isnull: oneof<nothing, bool>
  --skill-bonus-intimidation-isnull: oneof<nothing, bool>
  --skill-bonus-investigation-isnull: oneof<nothing, bool>
  --skill-bonus-medicine-isnull: oneof<nothing, bool>
  --skill-bonus-nature-isnull: oneof<nothing, bool>
  --skill-bonus-perception-isnull: oneof<nothing, bool>
  --skill-bonus-performance-isnull: oneof<nothing, bool>
  --skill-bonus-persuasion-isnull: oneof<nothing, bool>
  --skill-bonus-religion-isnull: oneof<nothing, bool>
  --skill-bonus-sleight-of-hand-isnull: oneof<nothing, bool>
  --skill-bonus-stealth-isnull: oneof<nothing, bool>
  --skill-bonus-survival-isnull: oneof<nothing, bool>
  --passive-perception: int
  --passive-perception-lt: int
  --passive-perception-lte: int
  --passive-perception-gt: int
  --passive-perception-gte: int
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, document: record, type: record, size: record, challenge_rating: float, proficiency_bonus: int, speed: record, speed_all: record, category: string, subcategory: string, alignment: string, languages: record, armor_class: int, armor_detail: string, hit_points: int, hit_dice: string, experience_points: int, ability_scores: record, modifiers: record, initiative_bonus: int, saving_throws: record, saving_throws_all: record, skill_bonuses: record, skill_bonuses_all: record, passive_perception: int, resistances_and_immunities: record, normal_sight_range: int, darkvision_range: int, blindsight_range: int, tremorsense_range: int, truesight_range: int, actions: list, traits: list, creaturesets: list, environments: list, illustration: record, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "category" $category "scalar") (serialize-qp "category__iexact" $category_iexact "scalar") (serialize-qp "subcategory" $subcategory "scalar") (serialize-qp "subcategory__iexact" $subcategory_iexact "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "challenge_rating" $challenge_rating "scalar") (serialize-qp "challenge_rating__lt" $challenge_rating_lt "scalar") (serialize-qp "challenge_rating__lte" $challenge_rating_lte "scalar") (serialize-qp "challenge_rating__gt" $challenge_rating_gt "scalar") (serialize-qp "challenge_rating__gte" $challenge_rating_gte "scalar") (serialize-qp "armor_class" $armor_class "scalar") (serialize-qp "armor_class__lt" $armor_class_lt "scalar") (serialize-qp "armor_class__lte" $armor_class_lte "scalar") (serialize-qp "armor_class__gt" $armor_class_gt "scalar") (serialize-qp "armor_class__gte" $armor_class_gte "scalar") (serialize-qp "ability_score_strength" $ability_score_strength "scalar") (serialize-qp "ability_score_strength__lt" $ability_score_strength_lt "scalar") (serialize-qp "ability_score_strength__lte" $ability_score_strength_lte "scalar") (serialize-qp "ability_score_strength__gt" $ability_score_strength_gt "scalar") (serialize-qp "ability_score_strength__gte" $ability_score_strength_gte "scalar") (serialize-qp "ability_score_dexterity" $ability_score_dexterity "scalar") (serialize-qp "ability_score_dexterity__lt" $ability_score_dexterity_lt "scalar") (serialize-qp "ability_score_dexterity__lte" $ability_score_dexterity_lte "scalar") (serialize-qp "ability_score_dexterity__gt" $ability_score_dexterity_gt "scalar") (serialize-qp "ability_score_dexterity__gte" $ability_score_dexterity_gte "scalar") (serialize-qp "ability_score_constitution" $ability_score_constitution "scalar") (serialize-qp "ability_score_constitution__lt" $ability_score_constitution_lt "scalar") (serialize-qp "ability_score_constitution__lte" $ability_score_constitution_lte "scalar") (serialize-qp "ability_score_constitution__gt" $ability_score_constitution_gt "scalar") (serialize-qp "ability_score_constitution__gte" $ability_score_constitution_gte "scalar") (serialize-qp "ability_score_intelligence" $ability_score_intelligence "scalar") (serialize-qp "ability_score_intelligence__lt" $ability_score_intelligence_lt "scalar") (serialize-qp "ability_score_intelligence__lte" $ability_score_intelligence_lte "scalar") (serialize-qp "ability_score_intelligence__gt" $ability_score_intelligence_gt "scalar") (serialize-qp "ability_score_intelligence__gte" $ability_score_intelligence_gte "scalar") (serialize-qp "ability_score_wisdom" $ability_score_wisdom "scalar") (serialize-qp "ability_score_wisdom__lt" $ability_score_wisdom_lt "scalar") (serialize-qp "ability_score_wisdom__lte" $ability_score_wisdom_lte "scalar") (serialize-qp "ability_score_wisdom__gt" $ability_score_wisdom_gt "scalar") (serialize-qp "ability_score_wisdom__gte" $ability_score_wisdom_gte "scalar") (serialize-qp "ability_score_charisma" $ability_score_charisma "scalar") (serialize-qp "ability_score_charisma__lt" $ability_score_charisma_lt "scalar") (serialize-qp "ability_score_charisma__lte" $ability_score_charisma_lte "scalar") (serialize-qp "ability_score_charisma__gt" $ability_score_charisma_gt "scalar") (serialize-qp "ability_score_charisma__gte" $ability_score_charisma_gte "scalar") (serialize-qp "saving_throw_strength__isnull" $saving_throw_strength_isnull "scalar") (serialize-qp "saving_throw_dexterity__isnull" $saving_throw_dexterity_isnull "scalar") (serialize-qp "saving_throw_constitution__isnull" $saving_throw_constitution_isnull "scalar") (serialize-qp "saving_throw_intelligence__isnull" $saving_throw_intelligence_isnull "scalar") (serialize-qp "saving_throw_wisdom__isnull" $saving_throw_wisdom_isnull "scalar") (serialize-qp "saving_throw_charisma__isnull" $saving_throw_charisma_isnull "scalar") (serialize-qp "skill_bonus_acrobatics__isnull" $skill_bonus_acrobatics_isnull "scalar") (serialize-qp "skill_bonus_animal_handling__isnull" $skill_bonus_animal_handling_isnull "scalar") (serialize-qp "skill_bonus_arcana__isnull" $skill_bonus_arcana_isnull "scalar") (serialize-qp "skill_bonus_athletics__isnull" $skill_bonus_athletics_isnull "scalar") (serialize-qp "skill_bonus_deception__isnull" $skill_bonus_deception_isnull "scalar") (serialize-qp "skill_bonus_history__isnull" $skill_bonus_history_isnull "scalar") (serialize-qp "skill_bonus_insight__isnull" $skill_bonus_insight_isnull "scalar") (serialize-qp "skill_bonus_intimidation__isnull" $skill_bonus_intimidation_isnull "scalar") (serialize-qp "skill_bonus_investigation__isnull" $skill_bonus_investigation_isnull "scalar") (serialize-qp "skill_bonus_medicine__isnull" $skill_bonus_medicine_isnull "scalar") (serialize-qp "skill_bonus_nature__isnull" $skill_bonus_nature_isnull "scalar") (serialize-qp "skill_bonus_perception__isnull" $skill_bonus_perception_isnull "scalar") (serialize-qp "skill_bonus_performance__isnull" $skill_bonus_performance_isnull "scalar") (serialize-qp "skill_bonus_persuasion__isnull" $skill_bonus_persuasion_isnull "scalar") (serialize-qp "skill_bonus_religion__isnull" $skill_bonus_religion_isnull "scalar") (serialize-qp "skill_bonus_sleight_of_hand__isnull" $skill_bonus_sleight_of_hand_isnull "scalar") (serialize-qp "skill_bonus_stealth__isnull" $skill_bonus_stealth_isnull "scalar") (serialize-qp "skill_bonus_survival__isnull" $skill_bonus_survival_isnull "scalar") (serialize-qp "passive_perception" $passive_perception "scalar") (serialize-qp "passive_perception__lt" $passive_perception_lt "scalar") (serialize-qp "passive_perception__lte" $passive_perception_lte "scalar") (serialize-qp "passive_perception__gt" $passive_perception_gt "scalar") (serialize-qp "passive_perception__gte" $passive_perception_gte "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/creatures/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of creatures. retrieve: API endpoint for returning a particular creature.
#
# GET /v2/creatures/{key}/
# operationId: creatures_retrieve
export def "creatures get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, type: record<name: string, key: string>, size: record<name: string, key: string>, challenge_rating: float, proficiency_bonus: int, speed: record<walk: string, fly: string, swim: string, climb: string, burrow: string, hover: bool>, speed_all: record<unit: string, walk: int, crawl: int, hover: bool, fly: int, burrow: int, climb: int, swim: int>, category: string, subcategory: string, alignment: string, languages: record<as_string: string, data: list<record>>, armor_class: int, armor_detail: string, hit_points: int, hit_dice: string, experience_points: int, ability_scores: record<strength: int, dexterity: int, constitution: int, intelligence: int, wisdom: int, charisma: int>, modifiers: record<strength: int, dexterity: int, constitution: int, intelligence: int, wisdom: int, charisma: int>, initiative_bonus: int, saving_throws: record<strength: int, dexterity: int, constitution: int, intelligence: int, wisdom: int, charisma: int>, saving_throws_all: record<strength: int, dexterity: int, constitution: int, intelligence: int, wisdom: int, charisma: int>, skill_bonuses: record<acrobatics: int, animal_handling: int, arcana: int, athletics: int, deception: int, history: int, insight: int, intimidation: int, investigation: int, medicine: int, nature: int, perception: int, performance: int, persuasion: int, religion: int, sleight_of_hand: int, stealth: int, survival: int>, skill_bonuses_all: record<acrobatics: int, animal_handling: int, arcana: int, athletics: int, deception: int, history: int, insight: int, intimidation: int, investigation: int, medicine: int, nature: int, perception: int, performance: int, persuasion: int, religion: int, sleight_of_hand: int, stealth: int, survival: int>, passive_perception: int, resistances_and_immunities: record<damage_immunities_display: string, damage_immunities: list<record>, damage_resistances_display: string, damage_resistances: list<record>, damage_vulnerabilities_display: string, damage_vulnerabilities: list<record>, condition_immunities_display: string, condition_immunities: list<record>>, normal_sight_range: int, darkvision_range: int, blindsight_range: int, tremorsense_range: int, truesight_range: int, actions: table<name: string, desc: string, attacks: list, action_type: string, order_in_statblock: int, legendary_action_cost: int, limited_to_form: string, usage_limits: record>, traits: table<name: string, desc: string>, creaturesets: list<string>, environments: table<name: string, key: string>, illustration: record<name: string, key: string, file_url: string, alt_text: string, attribution: string>, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/creatures/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of creatures types. retrieve: API endpoint for returning a particular creature type.
#
# GET /v2/creaturetypes/
# operationId: creaturetypes_list
export def "creaturetypes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, descriptions: list, name: string, document: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/creaturetypes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of creatures types. retrieve: API endpoint for returning a particular creature type.
#
# GET /v2/creaturetypes/{key}/
# operationId: creaturetypes_retrieve
export def "creaturetypes get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, descriptions: table<desc: string, document: string, gamesystem: string>, name: string, document: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/creaturetypes/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of creature sets, which is similar to tags. retrieve: API endpoint for returning a particular creature set.
#
# GET /v2/creaturesets/
# operationId: creaturesets_list
export def "creaturesets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, creatures: list, name: string, document: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/creaturesets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of creature sets, which is similar to tags. retrieve: API endpoint for returning a particular creature set.
#
# GET /v2/creaturesets/{key}/
# operationId: creaturesets_retrieve
export def "creaturesets get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, creatures: table<key: string, name: string, document: record, type: record, size: record, challenge_rating: float, proficiency_bonus: int, speed: record, speed_all: record, category: string, subcategory: string, alignment: string, languages: record, armor_class: int, armor_detail: string, hit_points: int, hit_dice: string, experience_points: int, ability_scores: record, modifiers: record, initiative_bonus: int, saving_throws: record, saving_throws_all: record, skill_bonuses: record, skill_bonuses_all: record, passive_perception: int, resistances_and_immunities: record, normal_sight_range: int, darkvision_range: int, blindsight_range: int, tremorsense_range: int, truesight_range: int, actions: list, traits: list, creaturesets: list, environments: list, illustration: record, crossreferences: record>, name: string, document: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/creaturesets/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of damage types. retrieve: API endpoint for returning a particular damage type.
#
# GET /v2/damagetypes/
# operationId: damagetypes_list
export def "damagetypes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, descriptions: list, name: string, document: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/damagetypes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of damage types. retrieve: API endpoint for returning a particular damage type.
#
# GET /v2/damagetypes/{key}/
# operationId: damagetypes_retrieve
export def "damagetypes get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, descriptions: table<desc: string, document: string, gamesystem: string>, name: string, document: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/damagetypes/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of feats. retrieve: API endpoint for returning a particular feat.
#
# GET /v2/languages/
# operationId: languages_list
export def "languages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --is-exotic: oneof<nothing, bool>
  --is-secret: oneof<nothing, bool>
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, document: record, name: string, desc: string, is_exotic: bool, is_secret: bool, script_language: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "is_exotic" $is_exotic "scalar") (serialize-qp "is_secret" $is_secret "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/languages/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of feats. retrieve: API endpoint for returning a particular feat.
#
# GET /v2/languages/{key}/
# operationId: languages_retrieve
export def "languages get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, name: string, desc: string, is_exotic: bool, is_secret: bool, script_language: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/languages/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of alignments. retrieve: API endpoint for returning a particular alignment.
#
# GET /v2/alignments/
# operationId: alignments_list
export def "alignments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, morality: string, societal_attitude: string, short_name: string, descriptions: list, document: record, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/alignments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of alignments. retrieve: API endpoint for returning a particular alignment.
#
# GET /v2/alignments/{key}/
# operationId: alignments_retrieve
export def "alignments get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, morality: string, societal_attitude: string, short_name: string, descriptions: table<desc: string, document: string, gamesystem: string>, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/alignments/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of conditions. retrieve: API endpoint for returning a particular condition.
#
# GET /v2/conditions/
# operationId: conditions_list
export def "conditions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, document: record, icon: record, descriptions: list, name: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/conditions/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of conditions. retrieve: API endpoint for returning a particular condition.
#
# GET /v2/conditions/{key}/
# operationId: conditions_retrieve
export def "conditions get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, icon: record<name: string, key: string, file_url: string, alt_text: string, attribution: string>, descriptions: table<desc: string, document: string, gamesystem: string>, name: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/conditions/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of spells. retrieve: API endpoint for returning a particular spell.
#
# GET /v2/spells/
# operationId: spells_list
export def "spells list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --name-icontains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --classes-key--in: list # Multiple values may be separated by commas.
  --classes-key--iexact: string
  --classes-key: string
  --classes-name--in: list # Multiple values may be separated by commas.
  --level: int
  --level-range: list # Multiple values may be separated by commas.
  --level-gt: int
  --level-gte: int
  --level-lt: int
  --level-lte: int
  --range: int
  --range-range: list # Multiple values may be separated by commas.
  --range-gt: int
  --range-gte: int
  --range-lt: int
  --range-lte: int
  --school-key: string
  --school-name--in: list # Multiple values may be separated by commas.
  --school-name--iexact: string
  --school-name: string
  --duration-in: list # Multiple values may be separated by commas.
  --duration-iexact: string
  --duration: string@duration-completer # Description of the duration of the effect such as "instantaneous" or "1 minute"  * `instantaneous` - instantaneous * `instantaneous or special` - instantaneous or special * `1 turn` - 1 turn * `1 round` - 1 round * `concentration + 1 round` - concentration + 1 round * `2 rounds` - 2 rounds * `3 rounds` - 3 rounds * `4 rounds` - 4 rounds * `1d4+2 rounds` - 1d4+2 rounds * `5 rounds` - 5 rounds * `6 rounds` - 6 rounds * `10 rounds` - 10 rounds * `up to 1 minute` - up to 1 minute * `1 minute` - 1 minute * `1 minute, or until expended` - 1 minute, or until expended * `1 minute, until expended` - 1 minute, until expended * `1 minute` - 1 minute * `5 minutes` - 5 minutes * `10 minutes` - 10 minutes * `1 minute or 1 hour` - 1 minute or 1 hour * `up to 1 hour` - up to 1 hour * `1 hour` - 1 hour * `1 hour or until triggered` - 1 hour or until triggered * `2 hours` - 2 hours * `3 hours` - 3 hours * `1d10 hours` - 1d10 hours * `6 hours` - 6 hours * `2-12 hours` - 2-12 hours * `up to 8 hours` - up to 8 hours * `8 hours` - 8 hours * `1 hour/caster level` - 1 hour/caster level * `10 hours` - 10 hours * `12 hours` - 12 hours * `24 hours or until the target attempts a third death saving throw` - 24 hours or until the target attempts a third death saving throw * `24 hours` - 24 hours * `1 day` - 1 day * `3 days` - 3 days * `5 days` - 5 days * `7 days` - 7 days * `10 days` - 10 days * `13 days` - 13 days * `30 days` - 30 days * `1 year` - 1 year * `special` - special * `until dispelled or destroyed` - until dispelled or destroyed * `until destroyed` - until destroyed * `until dispelled` - until dispelled * `until cured or dispelled` - until cured or dispelled * `until dispelled or triggered` - until dispelled or triggered * `permanent until discharged` - permanent until discharged * `permanent; one generation` - permanent; one generation * `permanent` - permanent
  --concentration: oneof<nothing, bool>
  --verbal: oneof<nothing, bool>
  --somatic: oneof<nothing, bool>
  --material: oneof<nothing, bool>
  --material-consumed: oneof<nothing, bool>
  --casting-time-in: list # Multiple values may be separated by commas.
  --casting-time-iexact: string
  --casting-time: string@casting-time-completer # Casting time key, such as 'action'  * `reaction` - Reaction * `bonus-action` - 1 Bonus Action * `action` - 1 Action * `turn` - 1 Turn * `round` - 1 Round * `1minute` - 1 Minute * `5minutes` - 5 Minutes * `10minutes` - 10 Minutes * `1hour` - 1 Hour * `4hours` - 4 Hours * `7hours` - 7 Hours * `8hours` - 8 Hours * `9hours` - 9 Hours * `12hours` - 12 Hours * `24hours` - 24 Hours * `1week` - 1 Week
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, document: record, casting_options: list, school: record, classes: list, range_unit: string, shape_size_unit: string, name: string, desc: string, level: int, higher_level: string, target_type: string, range_text: string, range: int, ritual: bool, casting_time: string, reaction_condition: string, verbal: bool, somatic: bool, material: bool, material_specified: string, material_cost: string, material_consumed: bool, target_count: int, saving_throw_ability: string, attack_roll: bool, damage_roll: string, damage_types: any, duration: string, shape_type: string, shape_size: int, concentration: bool, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "classes__key__in" $classes_key__in "csv") (serialize-qp "classes__key__iexact" $classes_key__iexact "scalar") (serialize-qp "classes__key" $classes_key "scalar") (serialize-qp "classes__name__in" $classes_name__in "csv") (serialize-qp "level" $level "scalar") (serialize-qp "level__range" $level_range "csv") (serialize-qp "level__gt" $level_gt "scalar") (serialize-qp "level__gte" $level_gte "scalar") (serialize-qp "level__lt" $level_lt "scalar") (serialize-qp "level__lte" $level_lte "scalar") (serialize-qp "range" $range "scalar") (serialize-qp "range__range" $range_range "csv") (serialize-qp "range__gt" $range_gt "scalar") (serialize-qp "range__gte" $range_gte "scalar") (serialize-qp "range__lt" $range_lt "scalar") (serialize-qp "range__lte" $range_lte "scalar") (serialize-qp "school__key" $school_key "scalar") (serialize-qp "school__name__in" $school_name__in "csv") (serialize-qp "school__name__iexact" $school_name__iexact "scalar") (serialize-qp "school__name" $school_name "scalar") (serialize-qp "duration__in" $duration_in "csv") (serialize-qp "duration__iexact" $duration_iexact "scalar") (serialize-qp "duration" $duration "scalar") (serialize-qp "concentration" $concentration "scalar") (serialize-qp "verbal" $verbal "scalar") (serialize-qp "somatic" $somatic "scalar") (serialize-qp "material" $material "scalar") (serialize-qp "material_consumed" $material_consumed "scalar") (serialize-qp "casting_time__in" $casting_time_in "csv") (serialize-qp "casting_time__iexact" $casting_time_iexact "scalar") (serialize-qp "casting_time" $casting_time "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/spells/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of spells. retrieve: API endpoint for returning a particular spell.
#
# GET /v2/spells/{key}/
# operationId: spells_retrieve
export def "spells get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, casting_options: table<type: string, damage_roll: string, target_count: int, duration: string, range: string, concentration: bool, shape_size: int, desc: string>, school: record<name: string, key: string>, classes: table<name: string, key: string>, range_unit: string, shape_size_unit: string, name: string, desc: string, level: int, higher_level: string, target_type: string, range_text: string, range: int, ritual: bool, casting_time: string, reaction_condition: string, verbal: bool, somatic: bool, material: bool, material_specified: string, material_cost: string, material_consumed: bool, target_count: int, saving_throw_ability: string, attack_roll: bool, damage_roll: string, damage_types: any, duration: string, shape_type: string, shape_size: int, concentration: bool, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/spells/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/spellschools/
#
# operationId: spellschools_list
export def "spellschools list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, desc: string, document: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/spellschools/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/spellschools/{key}/
#
# operationId: spellschools_retrieve
export def "spellschools get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, desc: string, document: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/spellschools/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of classes. retrieve: API endpoint for returning a particular class.
#
# GET /v2/classes/
# operationId: classes_list
export def "classes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --subclass-of: string # Unique key for the Item.
  --is-subclass: oneof<nothing, bool>
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, features: list, hit_points: record, document: record, saving_throws: list, subclass_of: record, name: string, desc: string, hit_dice: string, caster_type: string, primary_abilities: list, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "subclass_of" $subclass_of "scalar") (serialize-qp "is_subclass" $is_subclass "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/classes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of classes. retrieve: API endpoint for returning a particular class.
#
# GET /v2/classes/{key}/
# operationId: classes_retrieve
export def "classes get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, features: table<key: string, name: string, desc: string, feature_type: string, feature_items: list>, hit_points: record<hit_dice: int, hit_dice_name: string, hit_points_at_1st_level: int, hit_points_at_higher_levels: int>, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, saving_throws: table<name: string>, subclass_of: record<name: string, key: string>, name: string, desc: string, hit_dice: string, caster_type: string, primary_abilities: list<string>, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/classes/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of damage types. retrieve: API endpoint for returning a particular damage type.
#
# GET /v2/sizes/
# operationId: sizes_list
export def "sizes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, document: record, distance_unit: string, name: string, rank: int, space_diameter: int, suggested_hit_dice: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/sizes/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of damage types. retrieve: API endpoint for returning a particular damage type.
#
# GET /v2/sizes/{key}/
# operationId: sizes_retrieve
export def "sizes get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, distance_unit: string, name: string, rank: int, space_diameter: int, suggested_hit_dice: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/sizes/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of item rarities.  retrieve: API endpoint for returning a particular item rarity.
#
# GET /v2/itemrarities/
# operationId: itemrarities_list
export def "itemrarities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, key: string, rank: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/itemrarities/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of item rarities.  retrieve: API endpoint for returning a particular item rarity.
#
# GET /v2/itemrarities/{key}/
# operationId: itemrarities_retrieve
export def "itemrarities get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, key: string, rank: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/itemrarities/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of environments. retrieve: API endpoint for returning a particular environment.
#
# GET /v2/environments/
# operationId: environments_list
export def "environments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, desc: string, aquatic: bool, planar: bool, interior: bool, document: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/environments/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of environments. retrieve: API endpoint for returning a particular environment.
#
# GET /v2/environments/{key}/
# operationId: environments_retrieve
export def "environments get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, desc: string, aquatic: bool, planar: bool, interior: bool, document: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/environments/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of abilities. retrieve: API endpoint for returning a particular ability.
#
# GET /v2/abilities/
# operationId: abilities_list
export def "abilities list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, descriptions: list, skills: list, name: string, short_desc: string, document: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/abilities/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of abilities. retrieve: API endpoint for returning a particular ability.
#
# GET /v2/abilities/{key}/
# operationId: abilities_retrieve
export def "abilities get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, descriptions: table<desc: string, document: string, gamesystem: string>, skills: table<key: string, descriptions: list, name: string, document: string, ability: string>, name: string, short_desc: string, document: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/abilities/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of skills. retrieve: API endpoint for returning a particular skill.
#
# GET /v2/skills/
# operationId: skills_list
export def "skills list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, descriptions: list, name: string, document: string, ability: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/skills/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# list: API endpoint for returning a list of skills. retrieve: API endpoint for returning a particular skill.
#
# GET /v2/skills/{key}/
# operationId: skills_retrieve
export def "skills get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, descriptions: table<desc: string, document: string, gamesystem: string>, name: string, document: string, ability: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/skills/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This Mixin supports dynamically excluding returned fields of serializers that inherit from it via the `?exclude` query parameter.  Syntactically similar to the default `?field` DRF query parameter. Nested fields are similarly excluded via the '__' operator (see Examples).  ## Usage 1. Make sure your ViewSet inherits from `ExcludeFieldsMixin` before its base class (ie. ReadOnlyModelViewSet). 2. Pass exclude params in the request query string to remove fields from the response.  # Exclude top-level fields GET /v2/creatures/?exclude=traits,actions  # Exclude nested fields GET /v2/creatures/?actions__exclude=attacks
#
# GET /v2/rules/
# operationId: rules_list
export def "rules list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-icontains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, desc: string, index: int, initialHeaderLevel: int, document: string, ruleset: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rules/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This Mixin supports dynamically excluding returned fields of serializers that inherit from it via the `?exclude` query parameter.  Syntactically similar to the default `?field` DRF query parameter. Nested fields are similarly excluded via the '__' operator (see Examples).  ## Usage 1. Make sure your ViewSet inherits from `ExcludeFieldsMixin` before its base class (ie. ReadOnlyModelViewSet). 2. Pass exclude params in the request query string to remove fields from the response.  # Exclude top-level fields GET /v2/creatures/?exclude=traits,actions  # Exclude nested fields GET /v2/creatures/?actions__exclude=attacks
#
# GET /v2/rules/{key}/
# operationId: rules_retrieve
export def "rules get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, desc: string, index: int, initialHeaderLevel: int, document: string, ruleset: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/rules/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mixin to apply eager loading optimisations to a ViewSet.  Handles the running of `select_related()` (for ForeignKey fields) and `prefetch_related()` (from ManyToMany/reverse relationships) queryset methods to allow developers to solve N+1 problems on Open5e endpoints.  ## Usage 1. Make sure your ViewSet inherits from `EagerLoadingMixin` before its base class (ie. ReadOnlyModelViewSet). 2. Re-define `select_related_fields` and `prefetch_related_fields` lists on the child ViewSet to specify relationships to select related / pre-fetch.  ## Usage Example ```   class CreatureViewSet(EagerLoadingMixin, viewsets.ReadOnlyModelViewSet):     queryset = models.Creature.objects.all().order_by('pk')     serializer_class = serializers.CreatureSerializer     filterset_class = CreatureFilterSet     select_related_fields = []   # ForeignKey relations to optimise with select_related()     prefetch_related_fields = [] # ManyToMany/reverse relations to optimise with prefetch_related() ```
#
# GET /v2/rulesets/
# operationId: rulesets_list
export def "rulesets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key: string
  --name: string
  --name-contains: string
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, key: string, document: record, desc: string, rules: list, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key" $key "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__contains" $name_contains "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/rulesets/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mixin to apply eager loading optimisations to a ViewSet.  Handles the running of `select_related()` (for ForeignKey fields) and `prefetch_related()` (from ManyToMany/reverse relationships) queryset methods to allow developers to solve N+1 problems on Open5e endpoints.  ## Usage 1. Make sure your ViewSet inherits from `EagerLoadingMixin` before its base class (ie. ReadOnlyModelViewSet). 2. Re-define `select_related_fields` and `prefetch_related_fields` lists on the child ViewSet to specify relationships to select related / pre-fetch.  ## Usage Example ```   class CreatureViewSet(EagerLoadingMixin, viewsets.ReadOnlyModelViewSet):     queryset = models.Creature.objects.all().order_by('pk')     serializer_class = serializers.CreatureSerializer     filterset_class = CreatureFilterSet     select_related_fields = []   # ForeignKey relations to optimise with select_related()     prefetch_related_fields = [] # ManyToMany/reverse relations to optimise with prefetch_related() ```
#
# GET /v2/rulesets/{key}/
# operationId: rulesets_retrieve
export def "rulesets get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, key: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, desc: string, rules: table<key: string, name: string, desc: string, index: int, initialHeaderLevel: int, document: string, ruleset: string, crossreferences: record>, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/rulesets/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This Mixin supports dynamically excluding returned fields of serializers that inherit from it via the `?exclude` query parameter.  Syntactically similar to the default `?field` DRF query parameter. Nested fields are similarly excluded via the '__' operator (see Examples).  ## Usage 1. Make sure your ViewSet inherits from `ExcludeFieldsMixin` before its base class (ie. ReadOnlyModelViewSet). 2. Pass exclude params in the request query string to remove fields from the response.  # Exclude top-level fields GET /v2/creatures/?exclude=traits,actions  # Exclude nested fields GET /v2/creatures/?actions__exclude=attacks
#
# GET /v2/images/
# operationId: images_list
export def "images list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<name: string, key: string, file_url: string, alt_text: string, attribution: string, document: record, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/images/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# This Mixin supports dynamically excluding returned fields of serializers that inherit from it via the `?exclude` query parameter.  Syntactically similar to the default `?field` DRF query parameter. Nested fields are similarly excluded via the '__' operator (see Examples).  ## Usage 1. Make sure your ViewSet inherits from `ExcludeFieldsMixin` before its base class (ie. ReadOnlyModelViewSet). 2. Pass exclude params in the request query string to remove fields from the response.  # Exclude top-level fields GET /v2/creatures/?exclude=traits,actions  # Exclude nested fields GET /v2/creatures/?actions__exclude=attacks
#
# GET /v2/images/{key}/
# operationId: images_retrieve
export def "images get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, key: string, file_url: string, alt_text: string, attribution: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/images/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mixin to apply eager loading optimisations to a ViewSet.  Handles the running of `select_related()` (for ForeignKey fields) and `prefetch_related()` (from ManyToMany/reverse relationships) queryset methods to allow developers to solve N+1 problems on Open5e endpoints.  ## Usage 1. Make sure your ViewSet inherits from `EagerLoadingMixin` before its base class (ie. ReadOnlyModelViewSet). 2. Re-define `select_related_fields` and `prefetch_related_fields` lists on the child ViewSet to specify relationships to select related / pre-fetch.  ## Usage Example ```   class CreatureViewSet(EagerLoadingMixin, viewsets.ReadOnlyModelViewSet):     queryset = models.Creature.objects.all().order_by('pk')     serializer_class = serializers.CreatureSerializer     filterset_class = CreatureFilterSet     select_related_fields = []   # ForeignKey relations to optimise with select_related()     prefetch_related_fields = [] # ManyToMany/reverse relations to optimise with prefetch_related() ```
#
# GET /v2/weaponproperties/
# operationId: weaponproperties_list
export def "weaponproperties list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key-in: list # Multiple values may be separated by commas.
  --key-iexact: string
  --key: string
  --name-iexact: string
  --name: string
  --name-icontains: string
  --type: string
  --type-isnull: oneof<nothing, bool>
  --document-key--in: list # Multiple values may be separated by commas.
  --document-key--iexact: string
  --document-key: string
  --document-gamesystem--key--in: list # Multiple values may be separated by commas.
  --document-gamesystem--key--iexact: string
  --document-gamesystem--key: string
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, name: string, desc: string, document: string, type: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key__in" $key_in "csv") (serialize-qp "key__iexact" $key_iexact "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name__iexact" $name_iexact "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "name__icontains" $name_icontains "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "type__isnull" $type_isnull "scalar") (serialize-qp "document__key__in" $document_key__in "csv") (serialize-qp "document__key__iexact" $document_key__iexact "scalar") (serialize-qp "document__key" $document_key "scalar") (serialize-qp "document__gamesystem__key__in" $document_gamesystem__key__in "csv") (serialize-qp "document__gamesystem__key__iexact" $document_gamesystem__key__iexact "scalar") (serialize-qp "document__gamesystem__key" $document_gamesystem__key "scalar") (serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/weaponproperties/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mixin to apply eager loading optimisations to a ViewSet.  Handles the running of `select_related()` (for ForeignKey fields) and `prefetch_related()` (from ManyToMany/reverse relationships) queryset methods to allow developers to solve N+1 problems on Open5e endpoints.  ## Usage 1. Make sure your ViewSet inherits from `EagerLoadingMixin` before its base class (ie. ReadOnlyModelViewSet). 2. Re-define `select_related_fields` and `prefetch_related_fields` lists on the child ViewSet to specify relationships to select related / pre-fetch.  ## Usage Example ```   class CreatureViewSet(EagerLoadingMixin, viewsets.ReadOnlyModelViewSet):     queryset = models.Creature.objects.all().order_by('pk')     serializer_class = serializers.CreatureSerializer     filterset_class = CreatureFilterSet     select_related_fields = []   # ForeignKey relations to optimise with select_related()     prefetch_related_fields = [] # ManyToMany/reverse relations to optimise with prefetch_related() ```
#
# GET /v2/weaponproperties/{key}/
# operationId: weaponproperties_retrieve
export def "weaponproperties get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, name: string, desc: string, document: string, type: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/weaponproperties/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/services/
#
# operationId: services_list
export def "services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
]: nothing -> record<count: int, next: string, previous: string, results: table<key: string, document: record, name: string, desc: string, cost: string, detail: string, crossreferences: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/services/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v2/services/{key}/
#
# operationId: services_retrieve
export def "services get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: string, document: record<name: string, key: string, type: string, display_name: string, publisher: record<name: string, key: string>, gamesystem: record<name: string, key: string>, permalink: string>, name: string, desc: string, cost: string, detail: string, crossreferences: record<to: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/services/($key)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API endpoint for enums.
#
# GET /v2/enums/
# operationId: enums_list
export def "enums list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/enums/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search across D&D 5E content
#
# GET /v2/search/
# operationId: search_list
export def "search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ordering: string # Which field to use when ordering the results.
  --search: string # A search term.
  --page: int # A page number within the paginated result set.
  --limit: int # Number of results to return per page.
  --qp-query: string # The search term to find. Required parameter.
  --strict: oneof<nothing, bool> # Strict mode: only return explicitly requested search types. When false (default), exact search always runs with fuzzy fallback if no results found.
  --fuzzy: oneof<nothing, bool> # Include fuzzy individual word matches in name fields only. Default: false (but used as fallback in default mode).
  --vector: oneof<nothing, bool> # Include vector search results against name + description. Finds semantically similar content using TF-IDF similarity. Default: false.
  --object-model: string # Filter results to specific content type. Default: all types.
  --document-pk: string # Filter results to specific document. Use document key/slug. Default: all documents.
  --schema: string # API schema version to search. Default: 'v2'.
]: nothing -> record<count: int, next: string, previous: string, results: table<document: record, object_pk: string, object_name: string, object: any, object_model: string, schema_version: string, route: string, text: string, highlighted: string, match_type: string, matched_term: string, match_score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ordering" $ordering "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "strict" $strict "scalar") (serialize-qp "fuzzy" $fuzzy "scalar") (serialize-qp "vector" $vector "scalar") (serialize-qp "object_model" $object_model "scalar") (serialize-qp "document_pk" $document_pk "scalar") (serialize-qp "schema" $schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/search/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unified search across exact text, fuzzy, and vector search methods.
#
# GET /v2/search/{id}/
# operationId: search_retrieve
export def "search get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<document: record<key: string, name: string>, object_pk: string, object_name: string, object: any, object_model: string, schema_version: string, route: string, text: string, highlighted: string, match_type: string, matched_term: string, match_score: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/search/($id)/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
