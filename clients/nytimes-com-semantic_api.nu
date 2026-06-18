# Auto-generated client for Semantic API v2.0.0
# Source: https://api.apis.guru/v2/specs/nytimes.com/semantic_api/2.0.0/openapi.json
# Auth: --token flag or $env.SEMANTIC_API_TOKEN

const BASE_URL = "http://api.nytimes.com/svc/semantic/v2/concept"
const DEFAULT_AUTH = "query-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEMANTIC_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-api-key" => { {headers: {}, query: $"api-key=($token_val)"} }
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

def base-url-completer [] { ["http://api.nytimes.com/svc/semantic/v2/concept" "https://api.nytimes.com/svc/semantic/v2/concept"] }
def auth-scheme-completer [] { ["query-api-key"] }

# Completers for enum parameters
def fields-completer [] { ["all" "article_list" "combinations" "geocodes" "links" "pages" "scope_notes" "search_api_query" "taxonomy" "ticker_symbol"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "name get" } } | get name | first)
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

# GET /name/{concept-type}/{specific-concept}.json
export def "name get" [
  concept_type: string
  specific_concept: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string@fields-completer # "all" or comma-separated list of specific optional fields: pages, ticker_symbol, links, taxonomy, combinations, geocodes, article_list, scope_notes, search_api_query Optional fields are returned in result_set. They are briefly explained here: pages: A list of topic pages associated with a specific concept. ticker_symbol: If this concept is a publicly traded company, this field contains the ticker symbol. links: A list of links from this concept to external data resources. taxonomy: For descriptor concepts, this field returns a list of taxonomic relations to other concepts. combinations: For descriptor concepts, this field returns a list of the specific meanings tis concept takes on when combined with other concepts. geocodes: For geographic concepts, the full GIS record from geonames. article_list: A list of up to 10 articles associated with this concept. scope_notes: Scope notes contains clarifications and meaning definitions that explicate the relationship between the concept and an article. search_api_query: Returns the request one would need to submit to the Article Search API to obtain a list of articles annotated with this concept.
  --query: string # Precedes the search term string. Used in a Search Query. Except for <specific_concept_name>, Search Query will take the required parameters listed above (<concept_type>, <concept_uri>, <article_uri>) as an optional_parameter in addition to the query=<query_term>.
]: nothing -> record<copyright: string, num_results: int, results: table<ancestors: list, article_list: record, combinations: list, concept_created: string, concept_id: int, concept_name: string, concept_status: string, concept_type: string, concept_updated: string, descendants: list, is_times_tag: int, links: list, scope_notes: list, search_api_query: string, taxonomy: list, vernacular: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "query" $query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({concept_type: (encode-path-segment $concept_type), specific_concept: (encode-path-segment $specific_concept)} | format pattern "/name/{concept_type}/{specific_concept}.json") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /search.json
export def "search-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Precedes the search term string. Used in a Search Query. Except for <specific_concept_name>, Search Query will take the required parameters listed above (<concept_type>, <concept_uri>, <article_uri>) as an optional_parameter in addition to the query=<query_term>.
  --offset: int # Integer value for the index count from the first concept to the last concept, sorted alphabetically. Used in a Search Query. A Search Query will return up to 10 concepts in its results. (default: 10)
  --fields: string@fields-completer # "all" or comma-separated list of specific optional fields: pages, ticker_symbol, links, taxonomy, combinations, geocodes, article_list, scope_notes, search_api_query Optional fields are returned in result_set. They are briefly explained here: pages: A list of topic pages associated with a specific concept. ticker_symbol: If this concept is a publicly traded company, this field contains the ticker symbol. links: A list of links from this concept to external data resources. taxonomy: For descriptor concepts, this field returns a list of taxonomic relations to other concepts. combinations: For descriptor concepts, this field returns a list of the specific meanings tis concept takes on when combined with other concepts. geocodes: For geographic concepts, the full GIS record from geonames. article_list: A list of up to 10 articles associated with this concept. scope_notes: Scope notes contains clarifications and meaning definitions that explicate the relationship between the concept and an article. search_api_query: Returns the request one would need to submit to the Article Search API to obtain a list of articles annotated with this concept.
]: nothing -> record<copyright: string, num_results: int, results: table<concept_created: string, concept_id: int, concept_name: string, concept_status: string, concept_type: string, concept_updated: string, is_times_tag: int, vernacular: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "fields" $fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
