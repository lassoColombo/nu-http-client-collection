# Auto-generated client for search-a-licious API v0.1.0
# Source: https://search.openfoodfacts.org/openapi.json
# Auth: --token flag or $env.SEARCH_A_LICIOUS_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCH_A_LICIOUS_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "document get" } } | get name | first)
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

# Get Document
#
# GET /document/{identifier}
# operationId: get_document_document__identifier__get
export def "document get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --index-id: string # Index ID to use for the search, if not provided, the default index is used.         If there is only one index, this parameter is not needed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "index_id" $index_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/document/($identifier)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# POST /search
# operationId: search_search_post
export def "search post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: any # The search query, it supports Lucene search query syntax (https://lucene.apache.org/core/3_6_0/queryparsersyntax.html). Words that are not recognized by the lucene query parser are searched as full text search.  Example: `categories_tags:"en:beverages" strawberry brands:"casino"` query use a filter clause for categories and brands and look for "strawberry" in multiple fields.  The query is optional, but `sort_by` value must then be provided.
  --langs: list # List of languages we want to support during search. This list should include the user expected language, and additional languages (such as english for example).  This is currently used for language-specific subfields to choose in which subfields we're searching in.  If not provided, `['en']` is used. (default: [en])
  --page-size: int # Number of results to return per page. (default: 10)
  --page: int # Page to request, starts at 1. (default: 1)
  --body-fields: any # List of fields to include in the response. All other fields will be ignored.
  --sort-by: any #  Field name to use to sort results, the field should exist and be sortable. If it is not provided, results are sorted by descending relevance score.  If you put a minus before the name, the results will be sorted by descending order.  If the field name match a known script (defined in your configuration), it will be use for sorting.  In this case you also need to provide additional parameters corresponding to your script parameters. If a script needs parameters, you can only use the POST method.  Beware that this may have a big [impact on performance][perf_link]  Also bare in mind [privacy considerations][privacy_link] if your script parameters contains sensible data.  [perf_link]: https://openfoodfacts.github.io/search-a-licious/users/how-to-use-scripts/#performance-considerations [privacy_link]: https://openfoodfacts.github.io/search-a-licious/users/how-to-use-scripts/#performance-considerations
  --facets: any # Name of facets to return in the response as a comma-separated value.             If None (default) no facets are returned.
  --charts: any # Name of vega representations to return in the response.             Can be distribution chart or scatter plot
  --sort-params: any # Additional parameters when using  a sort script in sort_by.             If the sort script needs parameters, you can only be used the POST method.
  --index-id: any # Index ID to use for the search, if not provided, the default index is used.         If there is only one index, this parameter is not needed.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search")
  let body = {q: $q, langs: $langs, page_size: $page_size, page: $page, fields: $body_fields, sort_by: $sort_by, facets: $facets, charts: $charts, sort_params: $sort_params, index_id: $index_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Get
#
# GET /search
# operationId: search_get_search_get
export def "search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # The search query, it supports Lucene search query syntax (https://lucene.apache.org/core/3_6_0/queryparsersyntax.html). Words that are not recognized by the lucene query parser are searched as full text search.  Example: `categories_tags:"en:beverages" strawberry brands:"casino"` query use a filter clause for categories and brands and look for "strawberry" in multiple fields.  The query is optional, but `sort_by` value must then be provided.
  --langs: string # List of languages we want to support during search. This list should include the user expected language, and additional languages (such as english for example).  This is currently used for language-specific subfields to choose in which subfields we're searching in.  If not provided, `['en']` is used.
  --page-size: int # Number of results to return per page. (default: 10)
  --page: int # Page to request, starts at 1. (default: 1)
  --qp-fields: string # List of fields to include in the response. All other fields will be ignored.
  --sort-by: string #  Field name to use to sort results, the field should exist and be sortable. If it is not provided, results are sorted by descending relevance score.  If you put a minus before the name, the results will be sorted by descending order.  If the field name match a known script (defined in your configuration), it will be use for sorting.  In this case you also need to provide additional parameters corresponding to your script parameters. If a script needs parameters, you can only use the POST method.  Beware that this may have a big [impact on performance][perf_link]  Also bare in mind [privacy considerations][privacy_link] if your script parameters contains sensible data.  [perf_link]: https://openfoodfacts.github.io/search-a-licious/users/how-to-use-scripts/#performance-considerations [privacy_link]: https://openfoodfacts.github.io/search-a-licious/users/how-to-use-scripts/#performance-considerations
  --facets: string # Name of facets to return in the response as a comma-separated value.             If None (default) no facets are returned.
  --charts: string # Name of vega representations to return in the response.             Can be distribution chart or scatter plot
  --index-id: string # Index ID to use for the search, if not provided, the default index is used.         If there is only one index, this parameter is not needed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "langs" $langs "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "facets" $facets "scalar") (serialize-qp "charts" $charts "scalar") (serialize-qp "index_id" $index_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Taxonomy Autocomplete
#
# GET /autocomplete
# operationId: taxonomy_autocomplete_autocomplete_get
export def "autocomplete get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # User autocomplete query.
  --taxonomy-names: string # Name(s) of the taxonomy to search in, as a comma-separated value.
  --lang: string # Language to search in, defaults to 'en'. (default: en)
  --size: int # Number of results to return. (default: 10)
  --fuzziness: string # Fuzziness level to use, default to no fuzziness.
  --index-id: string # Index ID to use for the search, if not provided, the default index is used.         If there is only one index, this parameter is not needed.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "taxonomy_names" $taxonomy_names "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "fuzziness" $fuzziness "scalar") (serialize-qp "index_id" $index_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Off Demo
#
# GET /
# operationId: off_demo__get
export def "api get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Html Search
#
# GET /off-test
# operationId: html_search_off_test_get
export def "off-test get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string
  --page: int # default: 1
  --page-size: int # default: 24
  --langs: string # default: fr,en
  --sort-by: string
  --index-id: string # Index ID to use for the search, if not provided, the default index is used.         If there is only one index, this parameter is not needed.
  --display-debug: string@bool-completer # default: false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "langs" $langs "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "index_id" $index_id "scalar") (serialize-qp "display_debug" $display_debug "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/off-test" $qp)
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Robots Txt
#
# GET /robots.txt
# operationId: robots_txt_robots_txt_get
export def "robotstxt get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/robots.txt")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Healthcheck
#
# GET /health
# operationId: healthcheck_health_get
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
