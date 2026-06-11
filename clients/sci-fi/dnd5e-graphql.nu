# Auto-generated client for 2014 v0.0.0
# Source: https://www.dnd5eapi.co/graphql/2014
# Auth: --token flag or $env.2014_TOKEN

const BASE_URL = "https://www.dnd5eapi.co/graphql/2014"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o 2014_TOKEN | default "" }
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

# Unwrap a GraphQL response: extract data.{field} and surface errors
def unwrap-graphql [resp: any, field: string] {
  if ($resp | describe) == "string" { return $resp }
  let errors = ($resp.errors? | default [])
  if ($errors | length) > 0 {
    let msgs = ($errors | each {|e| $e.message? | default "unknown error" } | str join "; ")
    error make --unspanned { msg: $"GraphQL error: ($msgs)" }
  }
  $resp.data? | get -o $field | default $resp.data?
}

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://www.dnd5eapi.co/graphql/2014"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def order-by-completer [] { ["FULL_NAME" "NAME"] }
def order-direction-completer [] { ["ASC" "DESC"] }
def order-by-completer-1 [] { ["NAME"] }
def order-by-completer-2 [] { ["HIT_DIE" "NAME"] }
def order-by-completer-3 [] { ["COST_QUANTITY" "NAME" "WEIGHT"] }
def order-by-completer-4 [] { ["CLASS" "LEVEL" "NAME" "SUBCLASS"] }
def order-by-completer-5 [] { ["NAME" "SCRIPT" "TYPE"] }
def order-by-completer-6 [] { ["CLASS" "LEVEL" "SUBCLASS"] }
def order-by-completer-7 [] { ["EQUIPMENT_CATEGORY" "NAME" "RARITY"] }
def order-by-completer-8 [] { ["CHALLENGE_RATING" "CHARISMA" "CONSTITUTION" "DEXTERITY" "INTELLIGENCE" "NAME" "SIZE" "STRENGTH" "TYPE" "WISDOM"] }
def order-by-completer-9 [] { ["NAME" "TYPE"] }
def order-by-completer-10 [] { ["ABILITY_SCORE" "NAME"] }
def order-by-completer-11 [] { ["AREA_OF_EFFECT_SIZE" "LEVEL" "NAME" "SCHOOL"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "query ability-scores" } } | get name | first)
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

# Gets all ability scores, optionally filtered by name and sorted.
#
# operationId: abilityScores
# --order-then-by shape: {by: "NAME"|"FULL_NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query ability-scores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --full-name: string # Filter by ability score full name (case-insensitive, partial match)
  --order-by: string@order-by-completer
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"FULL_NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "full_name": $full_name, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc full_name index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $full_name: String, $order: AbilityScoreOrder) { abilityScores(skip: $skip, limit: $limit, name: $name, lang: $lang, full_name: $full_name, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "abilityScores" }
}

# Gets a single ability score by index.
#
# operationId: abilityScore
export def "query ability-score" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc full_name index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { abilityScore(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "abilityScore" }
}

# Gets all alignments, optionally filtered by name and sorted.
#
# operationId: alignments
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query alignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc abbreviation index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: AlignmentOrder) { alignments(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "alignments" }
}

# Gets a single alignment by index.
#
# operationId: alignment
export def "query alignment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc abbreviation index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { alignment(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "alignment" }
}

# Gets all backgrounds, optionally filtered by name and sorted by name.
#
# operationId: backgrounds
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query backgrounds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: BackgroundOrder) { backgrounds(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "backgrounds" }
}

# Gets a single background by index.
#
# operationId: background
export def "query background" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { background(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "background" }
}

# Gets all classes, optionally filtering by name or hit die and sorted.
#
# operationId: classes
# --hit-die-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --order-then-by shape: {by: "NAME"|"HIT_DIE", direction: "ASC"|"DESC", then_by?: record}
export def "query classes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --hit-die-eq: int # Matches an exact integer value.
  --hit-die-in-param: int # Matches any integer value in the provided list.
  --hit-die-nin: int # Matches no integer value in the provided list.
  --hit-die-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --order-by: string@order-by-completer-2
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"HIT_DIE", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let hit_die = ({"eq": $hit_die_eq, "in": $hit_die_in_param, "nin": $hit_die_nin, "range": $hit_die_range} | compact | if ($in | is-empty) { null } else { $in })
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "hit_die": $hit_die, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "hit_die index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $hit_die: NumberFilterInput, $order: ClassOrder) { classes(skip: $skip, limit: $limit, name: $name, lang: $lang, hit_die: $hit_die, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "classes" }
}

# Gets a single class by its index.
#
# operationId: class
export def "query class" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "hit_die index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { class(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "class" }
}

# Gets all conditions, optionally filtered by name and sorted by name.
#
# operationId: conditions
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query conditions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name desc updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: ConditionOrder) { conditions(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "conditions" }
}

# Gets a single condition by index.
#
# operationId: condition
export def "query condition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name desc updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { condition(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "condition" }
}

# Gets all damage types, optionally filtered by name and sorted by name.
#
# operationId: damageTypes
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query damage-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name desc updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: DamageTypeOrder) { damageTypes(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "damageTypes" }
}

# Gets a single damage type by index.
#
# operationId: damageType
export def "query damage-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name desc updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { damageType(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "damageType" }
}

# Gets all equipment, optionally filtered and sorted.
#
# operationId: equipments
# --order-then-by shape: {by: "NAME"|"WEIGHT"|"COST_QUANTITY", direction: "ASC"|"DESC", then_by?: record}
export def "query equipments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --equipment-category: string # Filter by one or more equipment category indices (e.g., ["weapon", "armor"])
  --order-by: string@order-by-completer-3
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"WEIGHT"|"COST_QUANTITY", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "equipment_category": $equipment_category, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on Armor { index name desc weight updated_at armor_category str_minimum stealth_disadvantage } ... on Weapon { index name desc weight updated_at weapon_category weapon_range category_range } ... on Tool { index name desc weight updated_at tool_category }" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $equipment_category: [String!], $order: EquipmentOrder) { equipments(skip: $skip, limit: $limit, name: $name, lang: $lang, equipment_category: $equipment_category, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "equipments" }
}

# Gets a single piece of equipment by its index.
#
# operationId: equipment
export def "query equipment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "__typename ... on Armor { index name desc weight updated_at armor_category str_minimum stealth_disadvantage } ... on Weapon { index name desc weight updated_at weapon_category weapon_range category_range } ... on Tool { index name desc weight updated_at tool_category }" }
    let body = {query: ("query($index: String!, $lang: String) { equipment(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "equipment" }
}

# Gets all equipment categories, optionally filtered by name and sorted by name.
#
# operationId: equipmentCategories
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query equipment-categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: EquipmentCategoryOrder) { equipmentCategories(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "equipmentCategories" }
}

# Gets a single equipment category by index.
#
# operationId: equipmentCategory
export def "query equipment-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { equipmentCategory(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "equipmentCategory" }
}

# Gets all feats, optionally filtered by name and sorted by name.
#
# operationId: feats
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query feats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name desc updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: FeatOrder) { feats(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "feats" }
}

# Gets a single feat by index.
#
# operationId: feat
export def "query feat" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name desc updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { feat(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "feat" }
}

# Gets all features, optionally filtered and sorted.
#
# operationId: features
# --level-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --order-then-by shape: {by: "NAME"|"LEVEL"|"CLASS"|"SUBCLASS", direction: "ASC"|"DESC", then_by?: record}
export def "query features" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --class: string # Filter by one or more associated class indices
  --subclass: string # Filter by one or more associated subclass indices
  --level-eq: int # Matches an exact integer value.
  --level-in-param: int # Matches any integer value in the provided list.
  --level-nin: int # Matches no integer value in the provided list.
  --level-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --order-by: string@order-by-completer-4
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"LEVEL"|"CLASS"|"SUBCLASS", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let level = ({"eq": $level_eq, "in": $level_in_param, "nin": $level_nin, "range": $level_range} | compact | if ($in | is-empty) { null } else { $in })
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "class": $class, "subclass": $subclass, "level": $level, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index level name reference updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $level: NumberFilterInput, $class: [String!], $subclass: [String!], $order: FeatureOrder) { features(skip: $skip, limit: $limit, name: $name, lang: $lang, class: $class, subclass: $subclass, level: $level, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "features" }
}

# Gets a single feature by its index.
#
# operationId: feature
export def "query feature" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index level name reference updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { feature(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "feature" }
}

# Gets a single language by its index.
#
# operationId: language
export def "query language" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name script type typical_speakers updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { language(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "language" }
}

# Gets all languages, optionally filtered and sorted.
#
# operationId: languages
# --order-then-by shape: {by: "NAME"|"TYPE"|"SCRIPT", direction: "ASC"|"DESC", then_by?: record}
export def "query languages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --type: string # Filter by language type (e.g., Standard, Exotic) - case-insensitive exact match after normalization
  --script: string # Filter by one or more language scripts (e.g., ["Common", "Elvish"])
  --order-by: string@order-by-completer-5
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"TYPE"|"SCRIPT", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "type": $type, "script": $script, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name script type typical_speakers updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $type: String, $script: [String!], $order: LanguageOrder) { languages(skip: $skip, limit: $limit, name: $name, lang: $lang, type: $type, script: $script, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "languages" }
}

# Gets a single level by its combined index (e.g., wizard-3-evocation or fighter-5).
#
# operationId: level
export def "query level" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "ability_score_bonuses index level prof_bonus updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { level(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "level" }
}

# Gets all levels, optionally filtered and sorted.
#
# operationId: levels
# --level-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --order-then-by shape: {by: "LEVEL"|"CLASS"|"SUBCLASS", direction: "ASC"|"DESC", then_by?: record}
export def "query levels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --class: string # Filter by one or more class indices
  --subclass: string # Filter by one or more subclass indices
  --ability-score-bonuses: int # Filter by the exact number of ability score bonuses granted at this level.
  --prof-bonus: int # Filter by the exact proficiency bonus at this level.
  --level-eq: int # Matches an exact integer value.
  --level-in-param: int # Matches any integer value in the provided list.
  --level-nin: int # Matches no integer value in the provided list.
  --level-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --order-by: string@order-by-completer-6
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "LEVEL"|"CLASS"|"SUBCLASS", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let level = ({"eq": $level_eq, "in": $level_in_param, "nin": $level_nin, "range": $level_range} | compact | if ($in | is-empty) { null } else { $in })
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "class": $class, "subclass": $subclass, "ability_score_bonuses": $ability_score_bonuses, "prof_bonus": $prof_bonus, "level": $level, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "ability_score_bonuses index level prof_bonus updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $class: [String!], $subclass: [String!], $level: NumberFilterInput, $ability_score_bonuses: Int, $prof_bonus: Int, $order: LevelOrder) { levels(skip: $skip, limit: $limit, class: $class, subclass: $subclass, ability_score_bonuses: $ability_score_bonuses, prof_bonus: $prof_bonus, level: $level, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "levels" }
}

# Gets all supported translation locales for the 2014 SRD.
#
# operationId: locales2014
export def "query locales2014" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {}
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "lang" }
    let body = {query: ("query { locales2014 { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "locales2014" }
}

# Gets a single 2014 locale by BCP 47 language tag (e.g. "de", "fr").
#
# operationId: locale2014
export def "query locale2014" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  lang: string
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "lang" }
    let body = {query: ("query($lang: String!) { locale2014(lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "locale2014" }
}

# Gets all magic items, optionally filtered and sorted.
#
# operationId: magicItems
# --order-then-by shape: {by: "NAME"|"EQUIPMENT_CATEGORY"|"RARITY", direction: "ASC"|"DESC", then_by?: record}
export def "query magic-items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --equipment-category: string # Filter by one or more equipment category indices (e.g., ["armor", "weapon"])
  --rarity: string # Filter by one or more rarity names (e.g., ["Rare", "Legendary"])
  --order-by: string@order-by-completer-7
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"EQUIPMENT_CATEGORY"|"RARITY", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "equipment_category": $equipment_category, "rarity": $rarity, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc image index name variant updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $equipment_category: [String!], $rarity: [String!], $order: MagicItemOrder) { magicItems(skip: $skip, limit: $limit, name: $name, lang: $lang, equipment_category: $equipment_category, rarity: $rarity, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "magicItems" }
}

# Gets a single magic item by index.
#
# operationId: magicItem
export def "query magic-item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc image index name variant updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { magicItem(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "magicItem" }
}

# Gets all magic schools, optionally filtered by name and sorted by name.
#
# operationId: magicSchools
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query magic-schools" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: MagicSchoolOrder) { magicSchools(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "magicSchools" }
}

# Gets a single magic school by index.
#
# operationId: magicSchool
export def "query magic-school" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { magicSchool(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "magicSchool" }
}

# Gets all monsters, optionally filtered and sorted.
#
# operationId: monsters
# --challenge-rating-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --xp-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --strength-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --dexterity-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --constitution-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --intelligence-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --wisdom-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --charisma-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --order-then-by shape: {by: "NAME"|"TYPE"|"SIZE"|"CHALLENGE_RATING"|"STRENGTH"|"DEXTERITY"|"CONSTITUTION"|"INTELLIGENCE"|"WISDOM"|"CHARISMA", direction: "ASC"|"DESC", then_by?: record}
export def "query monsters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --type: string # Filter by monster type (case-insensitive, exact match, e.g., "beast")
  --subtype: string # Filter by monster subtype (case-insensitive, exact match, e.g., "goblinoid")
  --size: string # Filter by monster size (exact match, e.g., "Medium")
  --damage-vulnerabilities: string # Filter by damage vulnerability indices
  --damage-resistances: string # Filter by damage resistance indices
  --damage-immunities: string # Filter by damage immunity indices
  --condition-immunities: string # Filter by condition immunity indices
  --challenge-rating-eq: int # Matches an exact integer value.
  --challenge-rating-in-param: int # Matches any integer value in the provided list.
  --challenge-rating-nin: int # Matches no integer value in the provided list.
  --challenge-rating-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --xp-eq: int # Matches an exact integer value.
  --xp-in-param: int # Matches any integer value in the provided list.
  --xp-nin: int # Matches no integer value in the provided list.
  --xp-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --strength-eq: int # Matches an exact integer value.
  --strength-in-param: int # Matches any integer value in the provided list.
  --strength-nin: int # Matches no integer value in the provided list.
  --strength-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --dexterity-eq: int # Matches an exact integer value.
  --dexterity-in-param: int # Matches any integer value in the provided list.
  --dexterity-nin: int # Matches no integer value in the provided list.
  --dexterity-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --constitution-eq: int # Matches an exact integer value.
  --constitution-in-param: int # Matches any integer value in the provided list.
  --constitution-nin: int # Matches no integer value in the provided list.
  --constitution-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --intelligence-eq: int # Matches an exact integer value.
  --intelligence-in-param: int # Matches any integer value in the provided list.
  --intelligence-nin: int # Matches no integer value in the provided list.
  --intelligence-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --wisdom-eq: int # Matches an exact integer value.
  --wisdom-in-param: int # Matches any integer value in the provided list.
  --wisdom-nin: int # Matches no integer value in the provided list.
  --wisdom-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --charisma-eq: int # Matches an exact integer value.
  --charisma-in-param: int # Matches any integer value in the provided list.
  --charisma-nin: int # Matches no integer value in the provided list.
  --charisma-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --order-by: string@order-by-completer-8
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"TYPE"|"SIZE"|"CHALLENGE_RATING"|"STRENGTH"|"DEXTERITY"|"CONSTITUTION"|"INTELLIGENCE"|"WISDOM"|"CHARISMA", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let challenge_rating = ({"eq": $challenge_rating_eq, "in": $challenge_rating_in_param, "nin": $challenge_rating_nin, "range": $challenge_rating_range} | compact | if ($in | is-empty) { null } else { $in })
  let xp = ({"eq": $xp_eq, "in": $xp_in_param, "nin": $xp_nin, "range": $xp_range} | compact | if ($in | is-empty) { null } else { $in })
  let strength = ({"eq": $strength_eq, "in": $strength_in_param, "nin": $strength_nin, "range": $strength_range} | compact | if ($in | is-empty) { null } else { $in })
  let dexterity = ({"eq": $dexterity_eq, "in": $dexterity_in_param, "nin": $dexterity_nin, "range": $dexterity_range} | compact | if ($in | is-empty) { null } else { $in })
  let constitution = ({"eq": $constitution_eq, "in": $constitution_in_param, "nin": $constitution_nin, "range": $constitution_range} | compact | if ($in | is-empty) { null } else { $in })
  let intelligence = ({"eq": $intelligence_eq, "in": $intelligence_in_param, "nin": $intelligence_nin, "range": $intelligence_range} | compact | if ($in | is-empty) { null } else { $in })
  let wisdom = ({"eq": $wisdom_eq, "in": $wisdom_in_param, "nin": $wisdom_nin, "range": $wisdom_range} | compact | if ($in | is-empty) { null } else { $in })
  let charisma = ({"eq": $charisma_eq, "in": $charisma_in_param, "nin": $charisma_nin, "range": $charisma_range} | compact | if ($in | is-empty) { null } else { $in })
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "type": $type, "subtype": $subtype, "size": $size, "damage_vulnerabilities": $damage_vulnerabilities, "damage_resistances": $damage_resistances, "damage_immunities": $damage_immunities, "condition_immunities": $condition_immunities, "challenge_rating": $challenge_rating, "xp": $xp, "strength": $strength, "dexterity": $dexterity, "constitution": $constitution, "intelligence": $intelligence, "wisdom": $wisdom, "charisma": $charisma, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alignment challenge_rating charisma constitution damage_immunities damage_resistances damage_vulnerabilities desc dexterity hit_dice hit_points hit_points_roll image index intelligence languages name size strength subtype type wisdom xp updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $type: String, $subtype: String, $challenge_rating: NumberFilterInput, $size: String, $xp: NumberFilterInput, $strength: NumberFilterInput, $dexterity: NumberFilterInput, $constitution: NumberFilterInput, $intelligence: NumberFilterInput, $wisdom: NumberFilterInput, $charisma: NumberFilterInput, $damage_vulnerabilities: [String!], $damage_resistances: [String!], $damage_immunities: [String!], $condition_immunities: [String!], $order: MonsterOrder) { monsters(skip: $skip, limit: $limit, name: $name, lang: $lang, type: $type, subtype: $subtype, size: $size, damage_vulnerabilities: $damage_vulnerabilities, damage_resistances: $damage_resistances, damage_immunities: $damage_immunities, condition_immunities: $condition_immunities, challenge_rating: $challenge_rating, xp: $xp, strength: $strength, dexterity: $dexterity, constitution: $constitution, intelligence: $intelligence, wisdom: $wisdom, charisma: $charisma, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "monsters" }
}

# Gets a single monster by its index.
#
# operationId: monster
export def "query monster" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "alignment challenge_rating charisma constitution damage_immunities damage_resistances damage_vulnerabilities desc dexterity hit_dice hit_points hit_points_roll image index intelligence languages name size strength subtype type wisdom xp updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { monster(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "monster" }
}

# Query all Proficiencies, optionally filtered and sorted.
#
# operationId: proficiencies
# --order-then-by shape: {by: "NAME"|"TYPE", direction: "ASC"|"DESC", then_by?: record}
export def "query proficiencies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --class: string # Filter by class index (e.g., ["barbarian", "bard"])
  --race: string # Filter by race index (e.g., ["dragonborn", "dwarf"])
  --type: string # Filter by proficiency type (exact match, e.g., ["ARMOR", "WEAPONS"])
  --order-by: string@order-by-completer-9
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"TYPE", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "class": $class, "race": $race, "type": $type, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name type updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $class: [String!], $race: [String!], $type: [String!], $order: ProficiencyOrder) { proficiencies(skip: $skip, limit: $limit, name: $name, lang: $lang, class: $class, race: $race, type: $type, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "proficiencies" }
}

# Gets a single proficiency by index.
#
# operationId: proficiency
export def "query proficiency" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index name type updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { proficiency(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "proficiency" }
}

# Gets all races, optionally filtered by name and sorted.
#
# operationId: races
# --speed-range shape: {lt?: int, lte?: int, gt?: int, gte?: int}
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query races" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --ability-bonus: string # Filter by one or more ability score indices that provide a bonus
  --size: string # Filter by one or more race sizes (e.g., ["Medium", "Small"])
  --language: string # Filter by one or more language indices spoken by the race
  --speed-eq: int # Matches an exact integer value.
  --speed-in-param: int # Matches any integer value in the provided list.
  --speed-nin: int # Matches no integer value in the provided list.
  --speed-range: record # Matches integer values within a specified range. — shape: {lt?: int, lte?: int, gt?: int, gte?: int}
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let speed = ({"eq": $speed_eq, "in": $speed_in_param, "nin": $speed_nin, "range": $speed_range} | compact | if ($in | is-empty) { null } else { $in })
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "ability_bonus": $ability_bonus, "size": $size, "language": $language, "speed": $speed, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index age alignment language_desc name size size_description speed updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $ability_bonus: [String!], $size: [String!], $language: [String!], $speed: NumberFilterInput, $order: RaceOrder) { races(skip: $skip, limit: $limit, name: $name, lang: $lang, ability_bonus: $ability_bonus, size: $size, language: $language, speed: $speed, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "races" }
}

# Gets a single race by its index.
#
# operationId: race
export def "query race" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "index age alignment language_desc name size size_description speed updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { race(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "race" }
}

# Gets all rules, optionally filtered by name and sorted by name.
#
# operationId: rules
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query rules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: RuleOrder) { rules(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "rules" }
}

# Gets a single rule by index.
#
# operationId: rule
export def "query rule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { rule(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "rule" }
}

# Gets all rule sections, optionally filtered by name and sorted by name.
#
# operationId: ruleSections
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query rule-sections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: RuleSectionOrder) { ruleSections(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "ruleSections" }
}

# Gets a single rule section by index.
#
# operationId: ruleSection
export def "query rule-section" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { ruleSection(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "ruleSection" }
}

# Gets all skills, optionally filtered by name and sorted by name.
#
# operationId: skills
# --order-then-by shape: {by: "NAME"|"ABILITY_SCORE", direction: "ASC"|"DESC", then_by?: record}
export def "query skills" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --ability-score: string # Filter by ability score index (e.g., ["str", "dex"])
  --order-by: string@order-by-completer-10
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"ABILITY_SCORE", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "ability_score": $ability_score, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $ability_score: [String!], $order: SkillOrder) { skills(skip: $skip, limit: $limit, name: $name, lang: $lang, ability_score: $ability_score, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "skills" }
}

# Gets a single skill by index.
#
# operationId: skill
export def "query skill" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { skill(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "skill" }
}

# Gets all spells, optionally filtered and sorted.
#
# operationId: spells
# --area-of-effect-size shape: {eq?: int, in?: int, nin?: int, range?: record}
# --order-then-by shape: {by: "NAME"|"LEVEL"|"SCHOOL"|"AREA_OF_EFFECT_SIZE", direction: "ASC"|"DESC", then_by?: record}
export def "query spells" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --level: int # Filter by spell level (e.g., [0, 9])
  --school: string # Filter by magic school index (e.g., ["evocation"])
  --class: string # Filter by class index that can cast the spell (e.g., ["wizard"])
  --subclass: string # Filter by subclass index that can cast the spell (e.g., ["lore"])
  --concentration: string@bool-completer # Filter by concentration requirement
  --ritual: string@bool-completer # Filter by ritual requirement
  --attack-type: string # Filter by attack type (e.g., ["ranged", "melee"])
  --casting-time: string # Filter by casting time (e.g., ["1 action"])
  --damage-type: string # Filter by damage type index (e.g., ["fire"])
  --dc-type: string # Filter by saving throw DC type index (e.g., ["dex"])
  --range: string # Filter by spell range (e.g., ["Self", "Touch"])
  --area-of-effect-type: string # Filter by area of effect type (e.g., ["sphere", "cone"])
  --area-of-effect-size: record # Filter by area of effect size (in feet). — shape: {eq?: int, in?: int, nin?: int, range?: record}
  --order-by: string@order-by-completer-11
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME"|"LEVEL"|"SCHOOL"|"AREA_OF_EFFECT_SIZE", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let area_of_effect = ({"type": $area_of_effect_type, "size": $area_of_effect_size} | compact | if ($in | is-empty) { null } else { $in })
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "level": $level, "school": $school, "class": $class, "subclass": $subclass, "concentration": $concentration, "ritual": $ritual, "attack_type": $attack_type, "casting_time": $casting_time, "damage_type": $damage_type, "dc_type": $dc_type, "range": $range, "area_of_effect": $area_of_effect, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "attack_type casting_time components concentration desc duration higher_level index level material name range ritual updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $level: [Int!], $school: [String!], $class: [String!], $subclass: [String!], $concentration: Boolean, $ritual: Boolean, $attack_type: [String!], $casting_time: [String!], $area_of_effect: AreaOfEffectFilterInput, $damage_type: [String!], $dc_type: [String!], $range: [String!], $order: SpellOrder) { spells(skip: $skip, limit: $limit, name: $name, lang: $lang, level: $level, school: $school, class: $class, subclass: $subclass, concentration: $concentration, ritual: $ritual, attack_type: $attack_type, casting_time: $casting_time, damage_type: $damage_type, dc_type: $dc_type, range: $range, area_of_effect: $area_of_effect, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "spells" }
}

# Gets a single spell by its index.
#
# operationId: spell
export def "query spell" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "attack_type casting_time components concentration desc duration higher_level index level material name range ritual updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { spell(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "spell" }
}

# Gets all subclasses, optionally filtered by name and sorted.
#
# operationId: subclasses
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query subclasses" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name subclass_flavor updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: SubclassOrder) { subclasses(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "subclasses" }
}

# Gets a single subclass by its index.
#
# operationId: subclass
export def "query subclass" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name subclass_flavor updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { subclass(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "subclass" }
}

# Gets all subraces, optionally filtered by name and sorted by name.
#
# operationId: subraces
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query subraces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: SubraceOrder) { subraces(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "subraces" }
}

# Gets a single subrace by index.
#
# operationId: subrace
export def "query subrace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { subrace(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "subrace" }
}

# Gets all traits, optionally filtered by name and sorted by name.
#
# operationId: traits
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query traits" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: TraitOrder) { traits(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "traits" }
}

# Gets a single trait by index.
#
# operationId: trait
export def "query trait" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { trait(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "trait" }
}

# Gets all weapon properties, optionally filtered by name and sorted by name.
#
# operationId: weaponProperties
# --order-then-by shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
export def "query weapon-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  --skip: int # Number of results to skip for pagination. Default: 0.
  --limit: int # Maximum number of results to return for pagination. Default: 50, Max: 100.
  --name: string # Filter by name (case-insensitive, partial match).
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
  --order-by: string@order-by-completer-1
  --order-direction: string@order-direction-completer
  --order-then-by: record # shape: {by: "NAME", direction: "ASC"|"DESC", then_by?: record}
]: any -> list {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let order = ({"by": $order_by, "direction": $order_direction, "then_by": $order_then_by} | compact | if ($in | is-empty) { null } else { $in })
  let variables = {"skip": $skip, "limit": $limit, "name": $name, "lang": $lang, "order": $order} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($skip: Int, $limit: Int, $name: String, $lang: String, $order: WeaponPropertyOrder) { weaponProperties(skip: $skip, limit: $limit, name: $name, lang: $lang, order: $order) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "weaponProperties" }
}

# Gets a single weapon property by index.
#
# operationId: weaponProperty
export def "query weapon-property" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fields: list<string> # Fields to select
  --query: string # Raw GraphQL query (overrides auto-generated)
  index: string # The index of the resource to retrieve.
  --lang: string # BCP 47 language tag for translated content (e.g. "de", "fr"). Defaults to "en".
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default $DEFAULT_AUTH))
  let base = ($base_url | default $BASE_URL)
  let variables = {"index": $index, "lang": $lang} | compact
  let variables = if ($input | describe | str starts-with "record") { $input | merge deep $variables } else { $variables }
  let result = if ($query | is-not-empty) {
    let body = {query: $query, variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  } else {
    let sel = if ($fields | is-not-empty) { $fields | str join " " } else { "desc index name updated_at" }
    let body = {query: ("query($index: String!, $lang: String) { weaponProperty(index: $index, lang: $lang) { " + $sel + " } }"), variables: $variables}
    do-request "post" $base $auth $insecure $raw $max_time $allow_errors "application/json" $body
  }
  if $raw or $allow_errors { $result } else { unwrap-graphql $result "weaponProperty" }
}
