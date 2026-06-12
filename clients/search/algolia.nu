# Auto-generated client for Search API v1.0.0
# Source: https://raw.githubusercontent.com/algolia/api-clients-automation/main/specs/bundled/search.yml
# Auth: --token flag or $env.SEARCH_API_TOKEN

const BASE_URL = "https://ALGOLIA_APPLICATION_ID.algolia.net"
const DEFAULT_AUTH = "x-algolia-application-id"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCH_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-algolia-application-id" => { {headers: {x-algolia-application-id: $token_val}, query: ""} }
    "x-algolia-api-key" => { {headers: {x-algolia-api-key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://ALGOLIA_APPLICATION_ID.algolia.net" "https://ALGOLIA_APPLICATION_ID-1.algolianet.com" "https://ALGOLIA_APPLICATION_ID-2.algolianet.com" "https://ALGOLIA_APPLICATION_ID-3.algolianet.com" "https://ALGOLIA_APPLICATION_ID-dsn.algolia.net"] }
def auth-scheme-completer [] { ["x-algolia-application-id" "x-algolia-api-key"] }

# Completers for enum parameters
def strategy-completer [] { ["none" "stopIfEnoughMatches"] }
def queryType-completer [] { ["prefixAll" "prefixLast" "prefixNone"] }
def removeWordsIfNoResults-completer [] { ["allOptional" "firstWords" "lastWords" "none"] }
def mode-completer [] { ["keywordSearch" "neuralSearch"] }
def exactOnSingleWordQuery-completer [] { ["attribute" "none" "word"] }
def type-completer [] { ["altCorrection1" "altCorrection2" "altcorrection1" "altcorrection2" "oneWaySynonym" "onewaysynonym" "placeholder" "synonym"] }
def anchoring-completer [] { ["contains" "endsWith" "is" "startsWith"] }
def language-completer [] { ["af" "ar" "az" "bg" "bn" "ca" "cs" "cy" "da" "de" "el" "en" "eo" "es" "et" "eu" "fa" "fi" "fo" "fr" "ga" "gl" "he" "hi" "hu" "hy" "id" "is" "it" "ja" "ka" "kk" "ko" "ku" "ky" "lt" "lv" "mi" "mn" "mr" "ms" "mt" "nb" "nl" "no" "ns" "pl" "ps" "pt" "pt-br" "qu" "ro" "ru" "sk" "sq" "sv" "sw" "ta" "te" "th" "tl" "tn" "tr" "tt" "uk" "ur" "uz" "zh"] }
def type-completer-1 [] { ["all" "build" "error" "query"] }
def operation-completer [] { ["copy" "move"] }
def operation-completer-1 [] { ["add" "delete" "update"] }
def action-completer [] { ["addObject" "clear" "delete" "deleteObject" "partialUpdateObject" "partialUpdateObjectNoCreate" "updateObject"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "search customGet" } } | get name | first)
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

# Send requests to the Algolia REST API
#
# GET /{path}
# operationId: customGet
export def "search customGet" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # Query parameters to apply to the current query.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/($path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send requests to the Algolia REST API
#
# POST /{path}
# operationId: customPost
export def "search customPost" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # Query parameters to apply to the current query.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/($path)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send requests to the Algolia REST API
#
# PUT /{path}
# operationId: customPut
export def "search customPut" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # Query parameters to apply to the current query.
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/($path)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send requests to the Algolia REST API
#
# DELETE /{path}
# operationId: customDelete
export def "search customDelete" [
  path: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parameters: record # Query parameters to apply to the current query.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parameters" $parameters "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/($path)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search an index
#
# POST /1/indexes/{indexName}/query
# operationId: searchSingleIndex
export def "1-indexes-query searchSingleIndex" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Search parameters as a URL-encoded query string. (default: , e.g. hitsPerPage=2&getRankingInfo=1)
]: any -> record<abTestID: int, abTestVariantID: int, aroundLatLng: string, automaticRadius: string, exhaustive: record<facetsCount: bool, facetValues: bool, nbHits: bool, rulesMatch: bool, typo: bool>, appliedRules: list<record>, exhaustiveFacetsCount: bool, exhaustiveNbHits: bool, exhaustiveTypo: bool, facets: record, facets_stats: record, index: string, indexUsed: string, message: string, nbSortedHits: int, parsedQuery: string, processingTimeMS: int, processingTimingsMS: record, queryAfterRemoval: string, redirect: record<index: list<record>>, renderingContent: record<facetOrdering: record<facets: record, values: record>, redirect: record<url: string>, widgets: record<banners: list>>, serverTimeMS: int, serverUsed: string, userData: any, queryID: string, _automaticInsights: bool, page: int, nbHits: int, nbPages: int, hitsPerPage: int, hits: table<objectID: string, _highlightResult: record, _snippetResult: record, _rankingInfo: record, _distinctSeqID: int>, query: string, params: string, extensions: record<queryCategorization: record<normalizedQuery: string, count: int, type: string, categories: list, autofiltering: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/query")
  let body = {params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search multiple queries
#
# POST /1/indexes/*/queries
# operationId: search
export def "1-indexes-queries search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  requests: list
  --strategy: string@strategy-completer # Strategy for multiple search queries:  - `none`. Run all queries. - `stopIfEnoughMatches`. Run the queries one by one, stopping as soon as a query matches at least the `hitsPerPage` number of results.
]: any -> record<results: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/indexes/*/queries")
  let body = {requests: $requests, strategy: $strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for facet values
#
# POST /1/indexes/{indexName}/facets/{facetName}/query
# operationId: searchForFacetValues
export def "1-indexes-facets-query searchForFacetValues" [
  indexName: string
  facetName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Search parameters as a URL-encoded query string. (default: , e.g. hitsPerPage=2&getRankingInfo=1)
  --facetQuery: string # Text to search inside the facet's values. (default: , e.g. george)
  --maxFacetHits: int # Maximum number of facet values to return when [searching for facet values](https://www.algolia.com/doc/guides/managing-results/refine-results/faceting/#search-for-facet-values). (default: 10)
]: any -> record<facetHits: table<value: string, highlighted: string, count: int>, exhaustiveFacetsCount: bool, processingTimeMS: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/facets/($facetName)/query")
  let body = {params: $params, facetQuery: $facetQuery, maxFacetHits: $maxFacetHits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Browse for records
#
# POST /1/indexes/{indexName}/browse
# operationId: browse
export def "1-indexes-browse browse" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --params: string # Search parameters as a URL-encoded query string. (default: , e.g. hitsPerPage=2&getRankingInfo=1)
]: any -> record<abTestID: int, abTestVariantID: int, aroundLatLng: string, automaticRadius: string, exhaustive: record<facetsCount: bool, facetValues: bool, nbHits: bool, rulesMatch: bool, typo: bool>, appliedRules: list<record>, exhaustiveFacetsCount: bool, exhaustiveNbHits: bool, exhaustiveTypo: bool, facets: record, facets_stats: record, index: string, indexUsed: string, message: string, nbSortedHits: int, parsedQuery: string, processingTimeMS: int, processingTimingsMS: record, queryAfterRemoval: string, redirect: record<index: list<record>>, renderingContent: record<facetOrdering: record<facets: record, values: record>, redirect: record<url: string>, widgets: record<banners: list>>, serverTimeMS: int, serverUsed: string, userData: any, queryID: string, _automaticInsights: bool, page: int, nbHits: int, nbPages: int, hitsPerPage: int, hits: table<objectID: string, _highlightResult: record, _snippetResult: record, _rankingInfo: record, _distinctSeqID: int>, query: string, params: string, extensions: record<queryCategorization: record<normalizedQuery: string, count: int, type: string, categories: list, autofiltering: record>>, cursor: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/browse")
  let body = {params: $params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a new record (with auto-generated object ID)
#
# POST /1/indexes/{indexName}
# operationId: saveObject
export def "1-indexes saveObject" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<createdAt: string, taskID: int, objectID: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an index
#
# DELETE /1/indexes/{indexName}
# Docs: https://www.algolia.com/doc/guides/sending-and-managing-data/manage-indices-and-apps/manage-indices/how-to/delete-indices — Delete indices.
# operationId: deleteIndex
export def "1-indexes delete-by-indexName" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a record
#
# GET /1/indexes/{indexName}/{objectID}
# operationId: getObject
export def "1-indexes get" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attributesToRetrieve: list # Attributes to include with the records in the response. This is useful to reduce the size of the API response. By default, all retrievable attributes are returned.  `objectID` is always retrieved.  Attributes included in `unretrievableAttributes` won't be retrieved unless the request is authenticated with the admin API key.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attributesToRetrieve" $attributesToRetrieve "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/($objectID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or replace a record
#
# PUT /1/indexes/{indexName}/{objectID}
# operationId: addOrUpdateObject
export def "1-indexes addOrUpdateObject" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/($objectID)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a record
#
# DELETE /1/indexes/{indexName}/{objectID}
# operationId: deleteObject
export def "1-indexes delete-by-indexName-objectID" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/($objectID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete records matching a filter
#
# POST /1/indexes/{indexName}/deleteByQuery
# Docs: https://support.algolia.com/hc/articles/16385098766353-Should-I-use-the-deleteBy-method-for-deleting-records-that-match-a-query — Should I use the deleteBy method for deleting records.
# operationId: deleteBy
export def "1-indexes-delete-by-query post" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --facetFilters: any # Filter the search by facet values, so that only records with the same facet values are retrieved.  **Prefer using the `filters` parameter, which supports all filter types and combinations with boolean operators.**  - `[filter1, filter2]` is interpreted as `filter1 AND filter2`. - `[[filter1, filter2], filter3]` is interpreted as `filter1 OR filter2 AND filter3`. - `facet:-value` is interpreted as `NOT facet:value`.  While it's best to avoid attributes that start with a `-`, you can still filter them by escaping with a backslash: `facet:\-value`.  (e.g. [[category:Book, category:-Movie], author:John Doe])
  --filters: string # Filter expression to only include items that match the filter criteria in the response.  You can use these filter expressions:  - **Numeric filters.** `<facet> <op> <number>`, where `<op>` is one of `<`, `<=`, `=`, `!=`, `>`, `>=`. - **Ranges.** `<facet>:<lower> TO <upper>`, where `<lower>` and `<upper>` are the lower and upper limits of the range (inclusive). - **Facet filters.** `<facet>:<value>`, where `<facet>` is a facet attribute (case-sensitive) and `<value>` a facet value. - **Tag filters.** `_tags:<value>` or just `<value>` (case-sensitive). - **Boolean filters.** `<facet>: true | false`.  You can combine filters with `AND`, `OR`, and `NOT` operators with the following restrictions:  - You can only combine filters of the same type with `OR`.   **Not supported:** `facet:value OR num > 3`. - You can't use `NOT` with combinations of filters.   **Not supported:** `NOT(facet:value OR facet:value)` - You can't combine conjunctions (`AND`) with `OR`.   **Not supported:** `facet:value OR (facet:value AND facet:value)`  Use quotes if the facet attribute name or facet value contains spaces, keywords (`OR`, `AND`, `NOT`), or quotes. If a facet attribute is an array, the filter matches if it matches at least one element of the array.  For more information, see [Filters](https://www.algolia.com/doc/guides/managing-results/refine-results/filtering).  (e.g. (category:Book OR category:Ebook) AND _tags:published)
  --numericFilters: any # Filter by numeric facets.  **Prefer using the `filters` parameter, which supports all filter types and combinations with boolean operators.**  You can use numeric comparison operators: `<`, `<=`, `=`, `!=`, `>`, `>=`. Comparisons are precise up to 3 decimals. You can also provide ranges: `facet:<lower> TO <upper>`. The range includes the lower and upper boundaries. The same combination rules apply as for `facetFilters`.  (e.g. [[inStock = 1, deliveryDate < 1441755506], price < 1000])
  --tagFilters: any # Filter the search by values of the special `_tags` attribute.  **Prefer using the `filters` parameter, which supports all filter types and combinations with boolean operators.**  Different from regular facets, `_tags` can only be used for filtering (including or excluding records). You won't get a facet count. The same combination and escaping rules apply as for `facetFilters`.  (e.g. [[Book, Movie], SciFi])
  --aroundLatLng: string # Coordinates for the center of a circle, expressed as a comma-separated string of latitude and longitude.  Only records included within a circle around this central location are included in the results. The radius of the circle is determined by the `aroundRadius` and `minimumAroundRadius` settings. This parameter is ignored if you also specify `insidePolygon` or `insideBoundingBox`.  (default: , e.g. 40.71,-74.01)
  --aroundRadius: any # Maximum radius for a search around a central location.  This parameter works in combination with the `aroundLatLng` and `aroundLatLngViaIP` parameters. By default, the search radius is determined automatically from the density of hits around the central location. The search radius is small if there are many hits close to the central coordinates.
  --insideBoundingBox: any
  --insidePolygon: list # Coordinates of a polygon in which to search.  Polygons are defined by 3 to 10,000 points. Each point is represented by its latitude and longitude. Provide multiple polygons as nested arrays. For more information, see [filtering inside polygons](https://www.algolia.com/doc/guides/managing-results/refine-results/geolocation/#filtering-inside-rectangular-or-polygonal-areas). This parameter is ignored if you also specify `insideBoundingBox`.  (e.g. [[47.3165, 4.9665, 47.3424, 5.0201, 47.32, 4.9], [40.9234, 2.1185, 38.643, 1.9916, 39.2587, 2.0104]])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/deleteByQuery")
  let body = {facetFilters: $facetFilters, filters: $filters, numericFilters: $numericFilters, tagFilters: $tagFilters, aroundLatLng: $aroundLatLng, aroundRadius: $aroundRadius, insideBoundingBox: $insideBoundingBox, insidePolygon: $insidePolygon} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete all records from an index
#
# POST /1/indexes/{indexName}/clear
# operationId: clearObjects
export def "1-indexes-clear clearObjects" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/clear")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or update attributes
#
# POST /1/indexes/{indexName}/{objectID}/partial
# operationId: partialUpdateObject
export def "1-indexes-partial partialUpdateObject" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --createIfNotExists: oneof<nothing, bool> # Whether to create a new record if it doesn't exist. (default: true)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "createIfNotExists" $createIfNotExists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/($objectID)/partial" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch indexing operations on one index
#
# POST /1/indexes/{indexName}/batch
# operationId: batch
# --requests item shape: {action: "addObject"|"updateObject"|"partialUpdateObject"|"partialUpdateObjectNoCreate"|"deleteObject"|"delete"|"clear", body: record}
export def "1-indexes-batch batch" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  requests: list # item shape: {action: "addObject"|"updateObject"|"partialUpdateObject"|"partialUpdateObjectNoCreate"|"deleteObject"|"delete"|"clear", body: record}
]: any -> record<taskID: int, objectIDs: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/batch")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Batch indexing operations on multiple indices
#
# POST /1/indexes/*/batch
# operationId: multipleBatch
# --requests item shape: {action: "addObject"|"updateObject"|"partialUpdateObject"|"partialUpdateObjectNoCreate"|"deleteObject"|"delete"|"clear", body?: record, indexName: string}
export def "1-indexes-batch multipleBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  requests: list # item shape: {action: "addObject"|"updateObject"|"partialUpdateObject"|"partialUpdateObjectNoCreate"|"deleteObject"|"delete"|"clear", body?: record, indexName: string}
]: any -> record<taskID: record, objectIDs: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/indexes/*/batch")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve records
#
# POST /1/indexes/*/objects
# operationId: getObjects
# --requests item shape: {attributesToRetrieve?: list, objectID: string, indexName: string}
export def "1-indexes-objects post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  requests: list # item shape: {attributesToRetrieve?: list, objectID: string, indexName: string}
]: any -> record<message: string, results: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/indexes/*/objects")
  let body = {requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve index settings
#
# GET /1/indexes/{indexName}/settings
# operationId: getSettings
export def "1-indexes-settings get" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --getVersion: int # When set to 2, the endpoint will not include `synonyms` in the response. This parameter is here for backward compatibility. (default: 1)
]: nothing -> record<primary: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getVersion" $getVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/settings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update index settings
#
# PUT /1/indexes/{indexName}/settings
# operationId: setSettings
# --semanticSearch shape: {eventSources?: any}
# --renderingContent shape: {facetOrdering?: record, redirect?: record, widgets?: record}
export def "1-indexes-settings setSettings" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
  --attributesForFaceting: list # Attributes used for [faceting](https://www.algolia.com/doc/guides/managing-results/refine-results/faceting).  Facets are attributes that let you categorize search results. They can be used for filtering search results. By default, no attribute is used for faceting. Attribute names are case-sensitive.  **Modifiers**  - `filterOnly("ATTRIBUTE")`.   Allows the attribute to be used as a filter but doesn't evaluate the facet values.  - `searchable("ATTRIBUTE")`.   Allows searching for facet values.  - `afterDistinct("ATTRIBUTE")`.   Evaluates the facet count _after_ deduplication with `distinct`.   This ensures accurate facet counts.   You can apply this modifier to searchable facets: `afterDistinct(searchable(ATTRIBUTE))`.  (default: [], e.g. [author, filterOnly(isbn), searchable(edition), afterDistinct(category), afterDistinct(searchable(publisher))])
  --replicas: list # Creates [replica indices](https://www.algolia.com/doc/guides/managing-results/refine-results/sorting/in-depth/replicas).  Replicas are copies of a primary index with the same records but different settings, synonyms, or rules. If you want to offer a different ranking or sorting of your search results, you'll use replica indices. All index operations on a primary index are automatically forwarded to its replicas. To add a replica index, you must provide the complete set of replicas to this parameter. If you omit a replica from this list, the replica turns into a regular, standalone index that will no longer be synced with the primary index.  **Modifier**  - `virtual("REPLICA")`.   Create a virtual replica,   Virtual replicas don't increase the number of records and are optimized for [Relevant sorting](https://www.algolia.com/doc/guides/managing-results/refine-results/sorting/in-depth/relevant-sort).  (default: [], e.g. [virtual(prod_products_price_asc), dev_products_replica])
  --paginationLimitedTo: int # Maximum number of search results that can be obtained through pagination.  Higher pagination limits might slow down your search. For pagination limits above 1,000, the sorting of results beyond the 1,000th hit can't be guaranteed.  (default: 1000, e.g. 100)
  --unretrievableAttributes: list # Attributes that can't be retrieved at query time.  This can be useful if you want to use an attribute for ranking or to [restrict access](https://www.algolia.com/doc/guides/security/api-keys/how-to/user-restricted-access-to-data), but don't want to include it in the search results. Attribute names are case-sensitive.  (default: [], e.g. [total_sales])
  --disableTypoToleranceOnWords: list # Creates a list of [words which require exact matches](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/typo-tolerance/in-depth/configuring-typo-tolerance/#turn-off-typo-tolerance-for-certain-words). This also turns off [word splitting and concatenation](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/splitting-and-concatenation) for the specified words.  (default: [], e.g. [wheel, 1X2BCD])
  --attributesToTransliterate: list # Attributes, for which you want to support [Japanese transliteration](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/language-specific-configurations/#japanese-transliteration-and-type-ahead).  Transliteration supports searching in any of the Japanese writing systems. To support transliteration, you must set the indexing language to Japanese. Attribute names are case-sensitive.  (e.g. [name, description])
  --camelCaseAttributes: list # Attributes for which to split [camel case](https://wikipedia.org/wiki/Camel_case) words. Attribute names are case-sensitive.  (default: [], e.g. [description])
  --decompoundedAttributes: record # Searchable attributes to which Algolia should apply [word segmentation](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/how-to/customize-segmentation) (decompounding). Attribute names are case-sensitive.  Compound words are formed by combining two or more individual words, and are particularly prevalent in Germanic languages—for example, "firefighter". With decompounding, the individual components are indexed separately.  You can specify different lists for different languages. Decompounding is supported for these languages: Dutch (`nl`), German (`de`), Finnish (`fi`), Danish (`da`), Swedish (`sv`), and Norwegian (`no`). Decompounding doesn't work for words with [non-spacing mark Unicode characters](https://www.charactercodes.net/category/non-spacing_mark). For example, `Gartenstühle` won't be decompounded if the `ü` consists of `u` (U+0075) and `◌̈` (U+0308).  (default: {}, e.g. {de: [name]})
  --indexLanguages: list # Languages for language-specific processing steps, such as word detection and dictionary settings.  **Always specify an indexing language.** If you don't specify an indexing language, the search engine uses all [supported languages](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/supported-languages), or the languages you specified with the `ignorePlurals` or `removeStopWords` parameters. This can lead to unexpected search results. For more information, see [Language-specific configuration](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/language-specific-configurations).  (default: [], e.g. [ja])
  --disablePrefixOnAttributes: list # Searchable attributes for which you want to turn off [prefix matching](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/override-search-engine-defaults/#adjusting-prefix-search). Attribute names are case-sensitive.  (default: [], e.g. [sku])
  --allowCompressionOfIntegerArray: oneof<nothing, bool> # Whether arrays with exclusively non-negative integers should be compressed for better performance. If true, the compressed arrays may be reordered.  (default: false)
  --numericAttributesForFiltering: list # Numeric attributes that can be used as [numerical filters](https://www.algolia.com/doc/guides/managing-results/rules/detecting-intent/how-to/applying-a-custom-filter-for-a-specific-query/#numerical-filters). Attribute names are case-sensitive.  By default, all numeric attributes are available as numerical filters. For faster indexing, reduce the number of numeric attributes.  To turn off filtering for all numeric attributes, specify an attribute that doesn't exist in your index, such as `NO_NUMERIC_FILTERING`.  **Modifier**  - `equalOnly("ATTRIBUTE")`.   Support only filtering based on equality comparisons `=` and `!=`.  (default: [], e.g. [equalOnly(quantity), popularity])
  --separatorsToIndex: string # Control which non-alphanumeric characters are indexed.  By default, Algolia ignores [non-alphanumeric characters](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/typo-tolerance/how-to/how-to-search-in-hyphenated-attributes/#handling-non-alphanumeric-characters) like hyphen (`-`), plus (`+`), and parentheses (`(`,`)`). To include such characters, define them with `separatorsToIndex`.  Separators are all non-letter characters except spaces and currency characters, such as $€£¥.  With `separatorsToIndex`, Algolia treats separator characters as separate words. For example, in a search for "Disney+", Algolia considers "Disney" and "+" as two separate words.  (default: , e.g. +#)
  --searchableAttributes: list # Attributes used for searching. Attribute names are case-sensitive.  By default, all attributes are searchable and the [Attribute](https://www.algolia.com/doc/guides/managing-results/relevance-overview/in-depth/ranking-criteria/#attribute) ranking criterion is turned off. With a non-empty list, Algolia only returns results with matches in the selected attributes. In addition, the Attribute ranking criterion is turned on: matches in attributes that are higher in the list of `searchableAttributes` rank first. To make matches in two attributes rank equally, include them in a comma-separated string, such as `"title,alternate_title"`. Attributes with the same priority are always unordered.  For more information, see [Searchable attributes](https://www.algolia.com/doc/guides/sending-and-managing-data/prepare-your-data/how-to/setting-searchable-attributes).  **Modifier**  - `unordered("ATTRIBUTE")`.   Ignore the position of a match within the attribute.  Without a modifier, matches at the beginning of an attribute rank higher than matches at the end.  (default: [], e.g. [title,alternative_title, author, unordered(text), emails.personal])
  --userData: any # An object with custom data.  You can store up to 32kB as custom data.  (default: {}, e.g. {settingID: f2a7b51e3503acc6a39b3784ffb84300, pluginVersion: 1.6.0})
  --customNormalization: record # Characters and their normalized replacements. This overrides Algolia's default [normalization](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/normalization).  (e.g. {default: {ä: ae, ü: ue}})
  --attributeForDistinct: string # Attribute that should be used to establish groups of results. Attribute names are case-sensitive.  All records with the same value for this attribute are considered a group. You can combine `attributeForDistinct` with the `distinct` search parameter to control how many items per group are included in the search results.  If you want to use the same attribute also for faceting, use the `afterDistinct` modifier of the `attributesForFaceting` setting. This applies faceting _after_ deduplication, which will result in accurate facet counts.  (e.g. url)
  --maxFacetHits: int # Maximum number of facet values to return when [searching for facet values](https://www.algolia.com/doc/guides/managing-results/refine-results/faceting/#search-for-facet-values). (default: 10)
  --keepDiacriticsOnCharacters: string # Characters for which diacritics should be preserved.  By default, Algolia removes diacritics from letters. For example, `é` becomes `e`. If this causes issues in your search, you can specify characters that should keep their diacritics.  (default: , e.g. øé)
  --customRanking: list # Attributes to use as [custom ranking](https://www.algolia.com/doc/guides/managing-results/must-do/custom-ranking). Attribute names are case-sensitive.  The custom ranking attributes decide which items are shown first if the other ranking criteria are equal.  Records with missing values for your selected custom ranking attributes are always sorted last. Boolean attributes are sorted based on their alphabetical order.  **Modifiers**  - `asc("ATTRIBUTE")`.   Sort the index by the values of an attribute, in ascending order.  - `desc("ATTRIBUTE")`.   Sort the index by the values of an attribute, in descending order.  If you use two or more custom ranking attributes, [reduce the precision](https://www.algolia.com/doc/guides/managing-results/must-do/custom-ranking/how-to/controlling-custom-ranking-metrics-precision) of your first attributes, or the other attributes will never be applied.  (default: [], e.g. [desc(popularity), asc(price)])
  --attributesToRetrieve: list # Attributes to include in the API response To reduce the size of your response, you can retrieve only some of the attributes. Attribute names are case-sensitive - `*` retrieves all attributes, except attributes included in the `customRanking` and `unretrievableAttributes` settings. - To retrieve all attributes except a specific one, prefix the attribute with a dash and combine it with the `*`: `["*", "-ATTRIBUTE"]`. - The `objectID` attribute is always included.  (default: [*], e.g. [author, title, content])
  --ranking: list # Determines the order in which Algolia returns your results.  By default, each entry corresponds to a [ranking criteria](https://www.algolia.com/doc/guides/managing-results/relevance-overview/in-depth/ranking-criteria). The tie-breaking algorithm sequentially applies each criterion in the order they're specified. If you configure a replica index for [sorting by an attribute](https://www.algolia.com/doc/guides/managing-results/refine-results/sorting/how-to/sort-by-attribute), you put the sorting attribute at the top of the list.  **Modifiers**  - `asc("ATTRIBUTE")`.   Sort the index by the values of an attribute, in ascending order. - `desc("ATTRIBUTE")`.   Sort the index by the values of an attribute, in descending order.  Before you modify the default setting, test your changes in the dashboard, and by [A/B testing](https://www.algolia.com/doc/guides/ab-testing/what-is-ab-testing).  (default: [typo, geo, words, filters, proximity, attribute, exact, custom])
  --relevancyStrictness: int # Relevancy threshold below which less relevant results aren't included in the results You can only set `relevancyStrictness` on [virtual replica indices](https://www.algolia.com/doc/guides/managing-results/refine-results/sorting/in-depth/replicas/#what-are-virtual-replicas). Use this setting to strike a balance between the relevance and number of returned results.  (default: 100, e.g. 90)
  --attributesToHighlight: list # Attributes to highlight By default, all searchable attributes are highlighted. Use `*` to highlight all attributes or use an empty array `[]` to turn off highlighting. Attribute names are case-sensitive With highlighting, strings that match the search query are surrounded by HTML tags defined by `highlightPreTag` and `highlightPostTag`. You can use this to visually highlight matching parts of a search query in your UI For more information, see [Highlighting and snippeting](https://www.algolia.com/doc/guides/building-search-ui/ui-and-ux-patterns/highlighting-snippeting/js).  (e.g. [author, title, conten, content])
  --attributesToSnippet: list # Attributes for which to enable snippets. Attribute names are case-sensitive Snippets provide additional context to matched words. If you enable snippets, they include 10 words, including the matched word. The matched word will also be wrapped by HTML tags for highlighting. You can adjust the number of words with the following notation: `ATTRIBUTE:NUMBER`, where `NUMBER` is the number of words to be extracted.  (default: [], e.g. [content:80, description])
  --highlightPreTag: string # HTML tag to insert before the highlighted parts in all highlighted results and snippets. (default: <em>)
  --highlightPostTag: string # HTML tag to insert after the highlighted parts in all highlighted results and snippets. (default: </em>)
  --snippetEllipsisText: string # String used as an ellipsis indicator when a snippet is truncated. (default: …)
  --restrictHighlightAndSnippetArrays: oneof<nothing, bool> # Whether to restrict highlighting and snippeting to items that at least partially matched the search query. By default, all items are highlighted and snippeted.  (default: false)
  --hitsPerPage: int # Number of hits per page. (default: 20)
  --minWordSizefor1Typo: int # Minimum number of characters a word in the search query must contain to accept matches with [one typo](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/typo-tolerance/in-depth/configuring-typo-tolerance/#configuring-word-length-for-typos). (default: 4)
  --minWordSizefor2Typos: int # Minimum number of characters a word in the search query must contain to accept matches with [two typos](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/typo-tolerance/in-depth/configuring-typo-tolerance/#configuring-word-length-for-typos). (default: 8)
  --typoTolerance: any # Whether [typo tolerance](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/typo-tolerance) is enabled and how it is applied.  If typo tolerance is true, `min`, or `strict`, [word splitting and concatenation](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/splitting-and-concatenation) are also active.
  --allowTyposOnNumericTokens: oneof<nothing, bool> # Whether to allow typos on numbers in the search query Turn off this setting to reduce the number of irrelevant matches when searching in large sets of similar numbers.  (default: true)
  --disableTypoToleranceOnAttributes: list # Attributes for which you want to turn off [typo tolerance](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/typo-tolerance). Attribute names are case-sensitive Returning only exact matches can help when - [Searching in hyphenated attributes](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/typo-tolerance/how-to/how-to-search-in-hyphenated-attributes). - Reducing the number of matches when you have too many.   This can happen with attributes that are long blocks of text, such as product descriptions Consider alternatives such as `disableTypoToleranceOnWords` or adding synonyms if your attributes have intentional unusual spellings that might look like typos.  (default: [], e.g. [sku])
  --ignorePlurals: any # Treat singular, plurals, and other forms of declensions as equivalent. Only use this feature for the languages used in your index.  (e.g. [ca, es])
  --removeStopWords: any # Removes stop words from the search query.  Stop words are common words like articles, conjunctions, prepositions, or pronouns that have little or no meaning on their own. In English, "the", "a", or "and" are stop words.  Only use this feature for the languages used in your index.  (e.g. [ca, es])
  --queryLanguages: list # Languages for language-specific query processing steps such as plurals, stop-word removal, and word-detection dictionaries. This setting sets a default list of languages used by the `removeStopWords` and `ignorePlurals` settings. This setting also sets a dictionary for word detection in the logogram-based [CJK](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/normalization/#normalization-for-logogram-based-languages-cjk) languages. To support this, place the CJK language **first**. **Always specify a query language.** If you don't specify an indexing language, the search engine uses all [supported languages](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/supported-languages), or the languages you specified with the `ignorePlurals` or `removeStopWords` parameters. This can lead to unexpected search results. For more information, see [Language-specific configuration](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/language-specific-configurations).  (default: [], e.g. [es])
  --decompoundQuery: oneof<nothing, bool> # Whether to split compound words in the query into their building blocks For more information, see [Word segmentation](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/language-specific-configurations/#splitting-compound-words). Word segmentation is supported for these languages: German, Dutch, Finnish, Swedish, and Norwegian. Decompounding doesn't work for words with [non-spacing mark Unicode characters](https://www.charactercodes.net/category/non-spacing_mark). For example, `Gartenstühle` won't be decompounded if the `ü` consists of `u` (U+0075) and `◌̈` (U+0308).  (default: true)
  --enableRules: oneof<nothing, bool> # Whether to enable rules. (default: true)
  --enablePersonalization: oneof<nothing, bool> # Whether to enable Personalization. (default: false)
  --queryType: string@queryType-completer # Determines if and how query words are interpreted as prefixes.  By default, only the last query word is treated as a prefix (`prefixLast`). To turn off prefix search, use `prefixNone`. Avoid `prefixAll`, which treats all query words as prefixes. This might lead to counterintuitive results and makes your search slower.  For more information, see [Prefix searching](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/override-search-engine-defaults/in-depth/prefix-searching).  (default: prefixLast)
  --removeWordsIfNoResults: string@removeWordsIfNoResults-completer # Strategy for removing words from the query when it doesn't return any results. This helps to avoid returning empty search results.  - `none`.   No words are removed when a query doesn't return results.  - `lastWords`.   Treat the last (then second to last, then third to last) word as optional,   until there are results or at most 5 words have been removed.  - `firstWords`.   Treat the first (then second, then third) word as optional,   until there are results or at most 5 words have been removed.  - `allOptional`.   Treat all words as optional.  For more information, see [Remove words to improve results](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/empty-or-insufficient-results/in-depth/why-use-remove-words-if-no-results).  (default: none, e.g. firstWords)
  --mode: string@mode-completer # Search mode the index will use to query for results.  This setting only applies to indices, for which Algolia enabled NeuralSearch for you.  (default: keywordSearch)
  --semanticSearch: record # Settings for the semantic search part of NeuralSearch. Only used when `mode` is `neuralSearch`. — shape: {eventSources?: any}
  --advancedSyntax: oneof<nothing, bool> # Whether to support phrase matching and excluding words from search queries Use the `advancedSyntaxFeatures` parameter to control which feature is supported.  (default: false)
  --optionalWords: any # Words that should be considered optional when found in the query.  By default, records must match all words in the search query to be included in the search results. Adding optional words can increase the number of search results by running an additional search query that doesn't include the optional words. For example, if the search query is "action video" and "video" is optional, the search engine runs two queries: one for "action video" and one for "action". Records that match all words are ranked higher.  For a search query with 4 or more words **and** all its words are optional, the number of matched words required for a record to be included in the search results increases for every 1,000 records:  - If `optionalWords` has fewer than 10 words, the required number of matched words increases by 1:   results 1 to 1,000 require 1 matched word; results 1,001 to 2,000 need 2 matched words. - If `optionalWords` has 10 or more words, the required number of matched words increases by the number of optional words divided by 5 (rounded down).   Example: with 18 optional words, results 1 to 1,000 require 1 matched word; results 1,001 to 2,000 need 4 matched words.  For more information, see [Optional words](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/empty-or-insufficient-results/#creating-a-list-of-optional-words).
  --disableExactOnAttributes: list # Searchable attributes for which you want to [turn off the Exact ranking criterion](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/override-search-engine-defaults/in-depth/adjust-exact-settings/#turn-off-exact-for-some-attributes). Attribute names are case-sensitive This can be useful for attributes with long values, where the likelihood of an exact match is high, such as product descriptions. Turning off the Exact ranking criterion for these attributes favors exact matching on other attributes. This reduces the impact of individual attributes with a lot of content on ranking.  (default: [], e.g. [description])
  --exactOnSingleWordQuery: string@exactOnSingleWordQuery-completer # Determines how the [Exact ranking criterion](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/override-search-engine-defaults/in-depth/adjust-exact-settings/#turn-off-exact-for-some-attributes) is computed when the search query has only one word.  - `attribute`.   The Exact ranking criterion is 1 if the query word and attribute value are the same.   For example, a search for "road" will match the value "road", but not "road trip".  - `none`.   The Exact ranking criterion is ignored on single-word searches.  - `word`.   The Exact ranking criterion is 1 if the query word is found in the attribute value.   The query word must have at least 3 characters and must not be a stop word.   Only exact matches will be highlighted,   partial and prefix matches won't.  (default: attribute)
  --alternativesAsExact: list # Determine which plurals and synonyms should be considered an exact matches By default, Algolia treats singular and plural forms of a word, and single-word synonyms, as [exact](https://www.algolia.com/doc/guides/managing-results/relevance-overview/in-depth/ranking-criteria/#exact) matches when searching. For example - "swimsuit" and "swimsuits" are treated the same - "swimsuit" and "swimwear" are treated the same (if they are [synonyms](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/adding-synonyms/#regular-synonyms)) - `ignorePlurals`.   Plurals and similar declensions added by the `ignorePlurals` setting are considered exact matches - `singleWordSynonym`.   Single-word synonyms, such as "NY" = "NYC", are considered exact matches - `multiWordsSynonym`.   Multi-word synonyms, such as "NY" = "New York", are considered exact matches.  (default: [ignorePlurals, singleWordSynonym])
  --advancedSyntaxFeatures: list # Advanced search syntax features you want to support - `exactPhrase`.   Phrases in quotes must match exactly.   For example, `sparkly blue "iPhone case"` only returns records with the exact string "iPhone case" - `excludeWords`.   Query words prefixed with a `-` must not occur in a record.   For example, `search -engine` matches records that contain "search" but not "engine" This setting only has an effect if `advancedSyntax` is true.  (default: [exactPhrase, excludeWords])
  --distinct: any # Determines how many records of a group are included in the search results.  Records with the same value for the `attributeForDistinct` attribute are considered a group. The `distinct` setting controls how many members of the group are returned. This is useful for [deduplication and grouping](https://www.algolia.com/doc/guides/managing-results/refine-results/grouping/#introducing-algolias-distinct-feature).  The `distinct` setting is ignored if `attributeForDistinct` is not set.  (e.g. 1)
  --replaceSynonymsInHighlight: oneof<nothing, bool> # Whether to replace a highlighted word with the matched synonym By default, the original words are highlighted even if a synonym matches. For example, with `home` as a synonym for `house` and a search for `home`, records matching either "home" or "house" are included in the search results, and either "home" or "house" are highlighted With `replaceSynonymsInHighlight` set to `true`, a search for `home` still matches the same records, but all occurrences of "house" are replaced by "home" in the highlighted response.  (default: false)
  --minProximity: int # Minimum proximity score for two matching words This adjusts the [Proximity ranking criterion](https://www.algolia.com/doc/guides/managing-results/relevance-overview/in-depth/ranking-criteria/#proximity) by equally scoring matches that are farther apart For example, if `minProximity` is 2, neighboring matches and matches with one word between them would have the same score.  (default: 1)
  --responseFields: list # Properties to include in the API response of search and browse requests By default, all response properties are included. To reduce the response size, you can select which properties should be included An empty list may lead to an empty API response (except properties you can't exclude) You can't exclude these properties: `message`, `warning`, `cursor`, `abTestVariantID`, or any property added by setting `getRankingInfo` to true Your search depends on the `hits` field. If you omit this field, searches won't return any results. Your UI might also depend on other properties, for example, for pagination. Before restricting the response size, check the impact on your search experience.  (default: [*])
  --maxValuesPerFacet: int # Maximum number of facet values to return for each facet. (default: 100)
  --sortFacetValuesBy: string # Order in which to retrieve facet values - `count`.   Facet values are retrieved by decreasing count.   The count is the number of matching records containing this facet value - `alpha`.   Retrieve facet values alphabetically This setting doesn't influence how facet values are displayed in your UI (see `renderingContent`). For more information, see [facet value display](https://www.algolia.com/doc/guides/building-search-ui/ui-and-ux-patterns/facet-display/js).  (default: count)
  --attributeCriteriaComputedByMinProximity: oneof<nothing, bool> # Whether the best matching attribute should be determined by minimum proximity This setting only affects ranking if the Attribute ranking criterion comes before Proximity in the `ranking` setting. If true, the best matching attribute is selected based on the minimum proximity of multiple matches. Otherwise, the best matching attribute is determined by the order in the `searchableAttributes` setting.  (default: false)
  --renderingContent: record # Extra data that can be used in the search UI.  You can use this to control aspects of your search UI, such as the order of facet names and values without changing your frontend code. — shape: {facetOrdering?: record, redirect?: record, widgets?: record}
  --enableReRanking: oneof<nothing, bool> # Whether this search will use [Dynamic Re-Ranking](https://www.algolia.com/doc/guides/algolia-ai/re-ranking) This setting only has an effect if you activated Dynamic Re-Ranking for this index in the Algolia dashboard.  (default: true)
  --reRankingApplyFilter: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/settings" $qp)
  let body = {attributesForFaceting: $attributesForFaceting, replicas: $replicas, paginationLimitedTo: $paginationLimitedTo, unretrievableAttributes: $unretrievableAttributes, disableTypoToleranceOnWords: $disableTypoToleranceOnWords, attributesToTransliterate: $attributesToTransliterate, camelCaseAttributes: $camelCaseAttributes, decompoundedAttributes: $decompoundedAttributes, indexLanguages: $indexLanguages, disablePrefixOnAttributes: $disablePrefixOnAttributes, allowCompressionOfIntegerArray: $allowCompressionOfIntegerArray, numericAttributesForFiltering: $numericAttributesForFiltering, separatorsToIndex: $separatorsToIndex, searchableAttributes: $searchableAttributes, userData: $userData, customNormalization: $customNormalization, attributeForDistinct: $attributeForDistinct, maxFacetHits: $maxFacetHits, keepDiacriticsOnCharacters: $keepDiacriticsOnCharacters, customRanking: $customRanking, attributesToRetrieve: $attributesToRetrieve, ranking: $ranking, relevancyStrictness: $relevancyStrictness, attributesToHighlight: $attributesToHighlight, attributesToSnippet: $attributesToSnippet, highlightPreTag: $highlightPreTag, highlightPostTag: $highlightPostTag, snippetEllipsisText: $snippetEllipsisText, restrictHighlightAndSnippetArrays: $restrictHighlightAndSnippetArrays, hitsPerPage: $hitsPerPage, minWordSizefor1Typo: $minWordSizefor1Typo, minWordSizefor2Typos: $minWordSizefor2Typos, typoTolerance: $typoTolerance, allowTyposOnNumericTokens: $allowTyposOnNumericTokens, disableTypoToleranceOnAttributes: $disableTypoToleranceOnAttributes, ignorePlurals: $ignorePlurals, removeStopWords: $removeStopWords, queryLanguages: $queryLanguages, decompoundQuery: $decompoundQuery, enableRules: $enableRules, enablePersonalization: $enablePersonalization, queryType: $queryType, removeWordsIfNoResults: $removeWordsIfNoResults, mode: $mode, semanticSearch: $semanticSearch, advancedSyntax: $advancedSyntax, optionalWords: $optionalWords, disableExactOnAttributes: $disableExactOnAttributes, exactOnSingleWordQuery: $exactOnSingleWordQuery, alternativesAsExact: $alternativesAsExact, advancedSyntaxFeatures: $advancedSyntaxFeatures, distinct: $distinct, replaceSynonymsInHighlight: $replaceSynonymsInHighlight, minProximity: $minProximity, responseFields: $responseFields, maxValuesPerFacet: $maxValuesPerFacet, sortFacetValuesBy: $sortFacetValuesBy, attributeCriteriaComputedByMinProximity: $attributeCriteriaComputedByMinProximity, renderingContent: $renderingContent, enableReRanking: $enableReRanking, reRankingApplyFilter: $reRankingApplyFilter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve a synonym
#
# GET /1/indexes/{indexName}/synonyms/{objectID}
# operationId: getSynonym
export def "1-indexes-synonyms get" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<objectID: string, type: string, synonyms: list<string>, input: string, word: string, corrections: list<string>, placeholder: string, replacements: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/synonyms/($objectID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace a synonym
#
# PUT /1/indexes/{indexName}/synonyms/{objectID}
# operationId: saveSynonym
export def "1-indexes-synonyms saveSynonym" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
  --body-objectID: string # Unique identifier of a synonym object. (e.g. synonymID)
  type: string@type-completer # Synonym type. (e.g. onewaysynonym)
  --synonyms: list # Words or phrases considered equivalent. (e.g. [vehicle, auto])
  --input: string # Word or phrase to appear in query strings (for [`onewaysynonym`s](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/adding-synonyms/in-depth/one-way-synonyms)). (e.g. car)
  --word: string # Word or phrase to appear in query strings (for [`altcorrection1` and `altcorrection2`](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/adding-synonyms/in-depth/synonyms-alternative-corrections)). (e.g. car)
  --corrections: list # Words to be matched in records. (e.g. [vehicle, auto])
  --placeholder: string # [Placeholder token](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/adding-synonyms/in-depth/synonyms-placeholders) to be put inside records.  (e.g. <Street>)
  --replacements: list # Query words that will match the [placeholder token](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/adding-synonyms/in-depth/synonyms-placeholders). (e.g. [street, st])
]: any -> record<taskID: int, updatedAt: string, id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/synonyms/($objectID)" $qp)
  let body = {objectID: $body_objectID, type: $type, synonyms: $synonyms, input: $input, word: $word, corrections: $corrections, placeholder: $placeholder, replacements: $replacements} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a synonym
#
# DELETE /1/indexes/{indexName}/synonyms/{objectID}
# operationId: deleteSynonym
export def "1-indexes-synonyms delete" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/synonyms/($objectID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace synonyms
#
# POST /1/indexes/{indexName}/synonyms/batch
# operationId: saveSynonyms
export def "1-indexes-synonyms-batch saveSynonyms" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
  --replaceExistingSynonyms: oneof<nothing, bool> # Whether to replace all synonyms in the index with the ones sent with this request.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar") (serialize-qp "replaceExistingSynonyms" $replaceExistingSynonyms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/synonyms/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete all synonyms
#
# POST /1/indexes/{indexName}/synonyms/clear
# operationId: clearSynonyms
export def "1-indexes-synonyms-clear clearSynonyms" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/synonyms/clear" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for synonyms
#
# POST /1/indexes/{indexName}/synonyms/search
# operationId: searchSynonyms
export def "1-indexes-synonyms-search searchSynonyms" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string # Search query. (default: )
  --type: string@type-completer # Synonym type. (e.g. onewaysynonym)
  --page: int # Page of search results to retrieve. (default: 0)
  --hitsPerPage: int # Number of hits per page. (default: 20)
]: any -> record<hits: table<objectID: string, type: string, synonyms: list, input: string, word: string, corrections: list, placeholder: string, replacements: list>, nbHits: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/synonyms/search")
  let body = {query: $body_query, type: $type, page: $page, hitsPerPage: $hitsPerPage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List API keys
#
# GET /1/keys
# operationId: listApiKeys
export def "1-keys listApiKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keys: table<value: string, createdAt: int, acl: list, description: string, indexes: list, maxHitsPerQuery: int, maxQueriesPerIPPerHour: int, queryParameters: string, referers: list, validity: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an API key
#
# POST /1/keys
# operationId: addApiKey
export def "1-keys addApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  acl: list # Permissions that determine the type of API requests this key can make. The required ACL is listed in each endpoint's reference. For more information, see [access control list](https://www.algolia.com/doc/guides/security/api-keys/#access-control-list-acl).  (default: [], e.g. [search, addObject])
  --description: string # Description of an API key to help you identify this API key. (default: , e.g. Used for indexing by the CLI)
  --indexes: list # Index names or patterns that this API key can access. By default, an API key can access all indices in the same application.  You can use leading and trailing wildcard characters (`*`):  - `dev_*` matches all indices starting with "dev_" - `*_dev` matches all indices ending with "_dev" - `*_products_*` matches all indices containing "_products_".  (default: [], e.g. [dev_*, prod_en_products])
  --maxHitsPerQuery: int # Maximum number of results this API key can retrieve in one query. By default, there's no limit.  (default: 0)
  --maxQueriesPerIPPerHour: int # Maximum number of API requests allowed per IP address or [user token](https://www.algolia.com/doc/guides/sending-events/concepts/usertoken) per hour.  If this limit is reached, the API returns an error with status code `429`. By default, there's no limit.  (default: 0)
  --queryParameters: string # Query parameters to add when making API requests with this API key.  To restrict this API key to specific IP addresses, add the `restrictSources` parameter. You can only add a single source, but you can provide a range of IP addresses.  Creating an API key fails if the request is made from an IP address outside the restricted range.  (default: , e.g. typoTolerance=strict&restrictSources=192.168.1.0/24)
  --referers: list # Allowed HTTP referrers for this API key.  By default, all referrers are allowed. You can use leading and trailing wildcard characters (`*`):  - `https://algolia.com/*` allows all referrers starting with "https://algolia.com/" - `*.algolia.com` allows all referrers ending with ".algolia.com" - `*algolia.com*` allows all referrers in the domain "algolia.com".  Like all HTTP headers, referrers can be spoofed. Don't rely on them to secure your data. For more information, see [HTTP referrer restrictions](https://www.algolia.com/doc/guides/security/security-best-practices/#http-referrers-restrictions).  (default: [], e.g. [*algolia.com*])
  --validity: int # Duration (in seconds) after which the API key expires. By default, API keys don't expire.  (default: 0, e.g. 86400)
]: any -> record<key: string, createdAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/keys")
  let body = {acl: $acl, description: $description, indexes: $indexes, maxHitsPerQuery: $maxHitsPerQuery, maxQueriesPerIPPerHour: $maxQueriesPerIPPerHour, queryParameters: $queryParameters, referers: $referers, validity: $validity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve API key permissions
#
# GET /1/keys/{key}
# operationId: getApiKey
export def "1-keys get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: string, createdAt: int, acl: list<string>, description: string, indexes: list<string>, maxHitsPerQuery: int, maxQueriesPerIPPerHour: int, queryParameters: string, referers: list<string>, validity: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/keys/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an API key
#
# PUT /1/keys/{key}
# operationId: updateApiKey
export def "1-keys updateApiKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  acl: list # Permissions that determine the type of API requests this key can make. The required ACL is listed in each endpoint's reference. For more information, see [access control list](https://www.algolia.com/doc/guides/security/api-keys/#access-control-list-acl).  (default: [], e.g. [search, addObject])
  --description: string # Description of an API key to help you identify this API key. (default: , e.g. Used for indexing by the CLI)
  --indexes: list # Index names or patterns that this API key can access. By default, an API key can access all indices in the same application.  You can use leading and trailing wildcard characters (`*`):  - `dev_*` matches all indices starting with "dev_" - `*_dev` matches all indices ending with "_dev" - `*_products_*` matches all indices containing "_products_".  (default: [], e.g. [dev_*, prod_en_products])
  --maxHitsPerQuery: int # Maximum number of results this API key can retrieve in one query. By default, there's no limit.  (default: 0)
  --maxQueriesPerIPPerHour: int # Maximum number of API requests allowed per IP address or [user token](https://www.algolia.com/doc/guides/sending-events/concepts/usertoken) per hour.  If this limit is reached, the API returns an error with status code `429`. By default, there's no limit.  (default: 0)
  --queryParameters: string # Query parameters to add when making API requests with this API key.  To restrict this API key to specific IP addresses, add the `restrictSources` parameter. You can only add a single source, but you can provide a range of IP addresses.  Creating an API key fails if the request is made from an IP address outside the restricted range.  (default: , e.g. typoTolerance=strict&restrictSources=192.168.1.0/24)
  --referers: list # Allowed HTTP referrers for this API key.  By default, all referrers are allowed. You can use leading and trailing wildcard characters (`*`):  - `https://algolia.com/*` allows all referrers starting with "https://algolia.com/" - `*.algolia.com` allows all referrers ending with ".algolia.com" - `*algolia.com*` allows all referrers in the domain "algolia.com".  Like all HTTP headers, referrers can be spoofed. Don't rely on them to secure your data. For more information, see [HTTP referrer restrictions](https://www.algolia.com/doc/guides/security/security-best-practices/#http-referrers-restrictions).  (default: [], e.g. [*algolia.com*])
  --validity: int # Duration (in seconds) after which the API key expires. By default, API keys don't expire.  (default: 0, e.g. 86400)
]: any -> record<key: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/keys/($key)")
  let body = {acl: $acl, description: $description, indexes: $indexes, maxHitsPerQuery: $maxHitsPerQuery, maxQueriesPerIPPerHour: $maxQueriesPerIPPerHour, queryParameters: $queryParameters, referers: $referers, validity: $validity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an API key
#
# DELETE /1/keys/{key}
# operationId: deleteApiKey
export def "1-keys delete" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/keys/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restore an API key
#
# POST /1/keys/{key}/restore
# operationId: restoreApiKey
export def "1-keys-restore restoreApiKey" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<key: string, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/keys/($key)/restore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a rule
#
# GET /1/indexes/{indexName}/rules/{objectID}
# operationId: getRule
export def "1-indexes-rules get" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<objectID: string, conditions: table<pattern: string, anchoring: string, alternatives: bool, context: string, filters: string>, consequence: record<params: record<similarQuery: string, filters: string, facetFilters: any, optionalFilters: any, numericFilters: any, tagFilters: any, sumOrFiltersScores: bool, restrictSearchableAttributes: list, facets: list, facetingAfterDistinct: bool, page: int, offset: int, length: int, aroundLatLng: string, aroundLatLngViaIP: bool, aroundRadius: any, aroundPrecision: any, minimumAroundRadius: int, insideBoundingBox: any, insidePolygon: list, naturalLanguages: list, ruleContexts: list, personalizationImpact: int, userToken: string, getRankingInfo: bool, synonyms: bool, clickAnalytics: bool, analytics: bool, analyticsTags: list, percentileComputation: bool, enableABTest: bool, attributesToRetrieve: list, ranking: list, relevancyStrictness: int, attributesToHighlight: list, attributesToSnippet: list, highlightPreTag: string, highlightPostTag: string, snippetEllipsisText: string, restrictHighlightAndSnippetArrays: bool, hitsPerPage: int, minWordSizefor1Typo: int, minWordSizefor2Typos: int, typoTolerance: any, allowTyposOnNumericTokens: bool, disableTypoToleranceOnAttributes: list, ignorePlurals: any, removeStopWords: any, queryLanguages: list, decompoundQuery: bool, enableRules: bool, enablePersonalization: bool, queryType: string, removeWordsIfNoResults: string, mode: string, semanticSearch: record, advancedSyntax: bool, optionalWords: any, disableExactOnAttributes: list, exactOnSingleWordQuery: string, alternativesAsExact: list, advancedSyntaxFeatures: list, distinct: any, replaceSynonymsInHighlight: bool, minProximity: int, responseFields: list, maxValuesPerFacet: int, sortFacetValuesBy: string, attributeCriteriaComputedByMinProximity: bool, renderingContent: record, enableReRanking: bool, reRankingApplyFilter: any, query: any, automaticFacetFilters: any, automaticOptionalFacetFilters: any>, promote: list<any>, filterPromotes: bool, hide: list<record>, redirect: record<indexName: string>, userData: record>, description: string, enabled: bool, validity: table<from: int, until: int>, tags: list<string>, scope: string, condition: record<pattern: string, anchoring: string, alternatives: bool, context: string, filters: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/rules/($objectID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace a rule
#
# PUT /1/indexes/{indexName}/rules/{objectID}
# operationId: saveRule
# --conditions item shape: {pattern?: string, anchoring?: "is"|"startsWith"|"endsWith"|"contains", alternatives?: bool, context?: string, filters?: string}
# --consequence shape: {params?: any, promote?: list, filterPromotes?: bool, hide?: list, redirect?: record, userData?: record}
# --validity item shape: {from?: int, until?: int}
# --condition shape: {pattern?: string, anchoring?: "is"|"startsWith"|"endsWith"|"contains", alternatives?: bool, context?: string, filters?: string}
export def "1-indexes-rules saveRule" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
  --body-objectID: string # Unique identifier of a rule object.
  --conditions: list # Conditions that trigger a rule.  Some consequences require specific conditions or don't require any condition. For more information, see [Conditions](https://www.algolia.com/doc/guides/managing-results/rules/rules-overview/#conditions). — item shape: {pattern?: string, anchoring?: "is"|"startsWith"|"endsWith"|"contains", alternatives?: bool, context?: string, filters?: string}
  consequence: record # Effect of the rule.  For more information, see [Consequences](https://www.algolia.com/doc/guides/managing-results/rules/rules-overview/#consequences). — shape: {params?: any, promote?: list, filterPromotes?: bool, hide?: list, redirect?: record, userData?: record}
  --description: string # Description of the rule's purpose to help you distinguish between different rules. (e.g. Display a promotional banner)
  --enabled: oneof<nothing, bool> # Whether the rule is active. (default: true)
  --validity: list # Time periods when the rule is active. — item shape: {from?: int, until?: int}
  --tags: list
  --scope: string
  --condition: record # shape: {pattern?: string, anchoring?: "is"|"startsWith"|"endsWith"|"contains", alternatives?: bool, context?: string, filters?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/rules/($objectID)" $qp)
  let body = {objectID: $body_objectID, conditions: $conditions, consequence: $consequence, description: $description, enabled: $enabled, validity: $validity, tags: $tags, scope: $scope, condition: $condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a rule
#
# DELETE /1/indexes/{indexName}/rules/{objectID}
# operationId: deleteRule
export def "1-indexes-rules delete" [
  indexName: string
  objectID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/rules/($objectID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update rules
#
# POST /1/indexes/{indexName}/rules/batch
# operationId: saveRules
export def "1-indexes-rules-batch saveRules" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
  --clearExistingRules: oneof<nothing, bool> # Whether existing rules should be deleted before adding this batch.
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar") (serialize-qp "clearExistingRules" $clearExistingRules "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/rules/batch" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete all rules
#
# POST /1/indexes/{indexName}/rules/clear
# operationId: clearRules
export def "1-indexes-rules-clear clearRules" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --forwardToReplicas: oneof<nothing, bool> # Whether changes are applied to replica indices.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "forwardToReplicas" $forwardToReplicas "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/1/indexes/($indexName)/rules/clear" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for rules
#
# POST /1/indexes/{indexName}/rules/search
# operationId: searchRules
export def "1-indexes-rules-search searchRules" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string # Search query for rules. (default: )
  --anchoring: string@anchoring-completer # Which part of the search query the pattern should match:  - `startsWith`. The pattern must match the beginning of the query. - `endsWith`. The pattern must match the end of the query. - `is`. The pattern must match the query exactly. - `contains`. The pattern must match anywhere in the query.  Empty queries are only allowed as patterns with `anchoring: is`.
  --context: string # Only return rules that match the context (exact match). (e.g. mobile)
  --page: int # Requested page of the API response.  Algolia uses `page` and `hitsPerPage` to control how search results are displayed ([paginated](https://www.algolia.com/doc/guides/building-search-ui/ui-and-ux-patterns/pagination/js)).  - `hitsPerPage`: sets the number of search results (_hits_) displayed per page. - `page`: specifies the page number of the search results you want to retrieve. Page numbering starts at 0, so the first page is `page=0`, the second is `page=1`, and so on.  For example, to display 10 results per page starting from the third page, set `hitsPerPage` to 10 and `page` to 2.
  --hitsPerPage: int # Maximum number of hits per page.  Algolia uses `page` and `hitsPerPage` to control how search results are displayed ([paginated](https://www.algolia.com/doc/guides/building-search-ui/ui-and-ux-patterns/pagination/js)).  - `hitsPerPage`: sets the number of search results (_hits_) displayed per page. - `page`: specifies the page number of the search results you want to retrieve. Page numbering starts at 0, so the first page is `page=0`, the second is `page=1`, and so on.  For example, to display 10 results per page starting from the third page, set `hitsPerPage` to 10 and `page` to 2.  (default: 20)
  --enabled: any
]: any -> record<hits: table<objectID: string, conditions: list, consequence: record, description: string, enabled: bool, validity: list, tags: list, scope: string, condition: record>, nbHits: int, page: int, nbPages: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/rules/search")
  let body = {query: $body_query, anchoring: $anchoring, context: $context, page: $page, hitsPerPage: $hitsPerPage, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add or delete dictionary entries
#
# POST /1/dictionaries/{dictionaryName}/batch
# operationId: batchDictionaryEntries
# --requests item shape: {action: "addEntry"|"deleteEntry", body: record}
export def "1-dictionaries-batch batchDictionaryEntries" [
  dictionaryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --clearExistingDictionaryEntries: oneof<nothing, bool> # Whether to replace all custom entries in the dictionary with the ones sent with this request. (default: false)
  requests: list # List of additions and deletions to your dictionaries. — item shape: {action: "addEntry"|"deleteEntry", body: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/dictionaries/($dictionaryName)/batch")
  let body = {clearExistingDictionaryEntries: $clearExistingDictionaryEntries, requests: $requests} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search dictionary entries
#
# POST /1/dictionaries/{dictionaryName}/search
# operationId: searchDictionaryEntries
export def "1-dictionaries-search searchDictionaryEntries" [
  dictionaryName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string # Search query. (default: )
  --page: int # Page of search results to retrieve. (default: 0)
  --hitsPerPage: int # Number of hits per page. (default: 20)
  --language: string@language-completer # ISO code for a supported language.
]: any -> record<hits: table<objectID: string, language: string, word: string, words: list, decomposition: list, state: string, type: string>, page: int, nbHits: int, nbPages: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/dictionaries/($dictionaryName)/search")
  let body = {query: $body_query, page: $page, hitsPerPage: $hitsPerPage, language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve dictionary settings
#
# GET /1/dictionaries/*/settings
# operationId: getDictionarySettings
export def "1-dictionaries-settings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<disableStandardEntries: record<plurals: any, stopwords: any, compounds: any>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/dictionaries/*/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update dictionary settings
#
# PUT /1/dictionaries/*/settings
# operationId: setDictionarySettings
# --disableStandardEntries shape: {plurals?: any, stopwords?: any, compounds?: any}
export def "1-dictionaries-settings setDictionarySettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  disableStandardEntries: record # Key-value pairs of [supported language ISO codes](https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/supported-languages) and boolean values. — shape: {plurals?: any, stopwords?: any, compounds?: any}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/dictionaries/*/settings")
  let body = {disableStandardEntries: $disableStandardEntries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List available languages
#
# GET /1/dictionaries/*/languages
# Docs: https://www.algolia.com/doc/guides/managing-results/optimize-search-results/handling-natural-languages-nlp/in-depth/supported-languages — Supported languages.
# operationId: getDictionaryLanguages
export def "1-dictionaries-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/dictionaries/*/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign or move a user ID
#
# POST /1/clusters/mapping
# DEPRECATED
# operationId: assignUserId
@deprecated
export def "1-clusters-mapping assignUserId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Algolia-User-ID: string # Unique identifier of the user who makes the search request. (e.g. user1)
  cluster: string # Cluster name. (e.g. c11-test)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/clusters/mapping")
  let body = {cluster: $cluster} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Algolia-User-ID": $X_Algolia_User_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List user IDs
#
# GET /1/clusters/mapping
# DEPRECATED
# operationId: listUserIds
@deprecated
export def "1-clusters-mapping listUserIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Requested page of the API response. If `null`, the API response is not paginated.
  --hitsPerPage: int # Number of hits per page. (default: 100)
]: nothing -> record<userIDs: table<userID: string, clusterName: string, nbRecords: int, dataSize: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "hitsPerPage" $hitsPerPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/clusters/mapping" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign multiple userIDs
#
# POST /1/clusters/mapping/batch
# DEPRECATED
# operationId: batchAssignUserIds
@deprecated
export def "1-clusters-mapping-batch batchAssignUserIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Algolia-User-ID: string # Unique identifier of the user who makes the search request. (e.g. user1)
  cluster: string # Cluster name. (e.g. c11-test)
  users: list # User IDs to assign. (e.g. [einstein, bohr, feynman])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/clusters/mapping/batch")
  let body = {cluster: $cluster, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Algolia-User-ID": $X_Algolia_User_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get top user IDs
#
# GET /1/clusters/mapping/top
# DEPRECATED
# operationId: getTopUserIds
@deprecated
export def "1-clusters-mapping-top get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<topUsers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/clusters/mapping/top")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve user ID
#
# GET /1/clusters/mapping/{userID}
# DEPRECATED
# operationId: getUserId
@deprecated
export def "1-clusters-mapping get" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<userID: string, clusterName: string, nbRecords: int, dataSize: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/clusters/mapping/($userID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user ID
#
# DELETE /1/clusters/mapping/{userID}
# DEPRECATED
# operationId: removeUserId
@deprecated
export def "1-clusters-mapping removeUserId" [
  userID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/clusters/mapping/($userID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List clusters
#
# GET /1/clusters
# DEPRECATED
# operationId: listClusters
@deprecated
export def "1-clusters listClusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<topUsers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/clusters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search for user IDs
#
# POST /1/clusters/mapping/search
# DEPRECATED
# operationId: searchUserIds
@deprecated
export def "1-clusters-mapping-search searchUserIds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-query: string
  --clusterName: string # Cluster name. (e.g. c11-test)
  --page: int # Page of search results to retrieve. (default: 0)
  --hitsPerPage: int # Number of hits per page. (default: 20)
]: any -> record<hits: table<userID: string, clusterName: string, nbRecords: int, dataSize: int, objectID: string, _highlightResult: record>, nbHits: int, page: int, hitsPerPage: int, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/clusters/mapping/search")
  let body = {query: $body_query, clusterName: $clusterName, page: $page, hitsPerPage: $hitsPerPage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get migration and user mapping status
#
# GET /1/clusters/mapping/pending
# DEPRECATED
# operationId: hasPendingMappings
@deprecated
export def "1-clusters-mapping-pending hasPendingMappings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --getClusters: oneof<nothing, bool> # Whether to include the cluster's pending mapping state in the response.
]: nothing -> record<pending: bool, clusters: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "getClusters" $getClusters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/clusters/mapping/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List allowed sources
#
# GET /1/security/sources
# operationId: getSources
export def "1-security-sources get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<source: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/security/sources")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace allowed sources
#
# PUT /1/security/sources
# operationId: replaceSources
export def "1-security-sources replaceSources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/security/sources")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a source
#
# POST /1/security/sources/append
# operationId: appendSource
export def "1-security-sources-append appendSource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-source: string # IP address range of the source. (e.g. 10.0.0.1/32)
  --description: string # Source description. (e.g. Server subnet)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/1/security/sources/append")
  let body = {source: $body_source, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a source
#
# DELETE /1/security/sources/{source}
# operationId: deleteSource
export def "1-security-sources delete" [
  source: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<deletedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/security/sources/($source)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve log entries
#
# GET /1/logs
# operationId: getLogs
export def "1-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # First log entry to retrieve. The most recent entries are listed first. (default: 0)
  --length: int # Maximum number of entries to retrieve. (default: 10)
  --indexName: string # Index for which to retrieve log entries. By default, log entries are retrieved for all indices.  (e.g. products)
  --type: string@type-completer-1 # Type of log entries to retrieve. By default, all log entries are retrieved.  (default: all)
]: nothing -> record<logs: table<timestamp: string, method: string, answer_code: string, query_body: string, answer: string, url: string, ip: string, query_headers: string, sha1: string, nb_api_calls: string, processing_time_ms: string, index: string, query_params: string, query_nb_hits: string, inner_queries: list>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "length" $length "scalar") (serialize-qp "indexName" $indexName "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check application task status
#
# GET /1/task/{taskID}
# operationId: getAppTask
export def "1-task get" [
  taskID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/task/($taskID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check task status
#
# GET /1/indexes/{indexName}/task/{taskID}
# operationId: getTask
export def "1-indexes-task get" [
  indexName: string
  taskID: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/task/($taskID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Copy or move an index
#
# POST /1/indexes/{indexName}/operation
# operationId: operationIndex
export def "1-indexes-operation operationIndex" [
  indexName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  operation: string@operation-completer # Operation to perform on the index. (e.g. copy)
  destination: string # Index name (case-sensitive). (e.g. products)
  --scope: list # **Only for copying.**  If you specify a scope, only the selected scopes are copied. Records and the other scopes are left unchanged. If you omit the `scope` parameter, everything is copied: records, settings, synonyms, and rules.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/1/indexes/($indexName)/operation")
  let body = {operation: $operation, destination: $destination, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List indices
#
# GET /1/indexes
# operationId: listIndices
export def "1-indexes listIndices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: string # Requested page of the API response. If `null`, the API response is not paginated.
  --hitsPerPage: int # Number of hits per page. (default: 100)
]: nothing -> record<items: table<name: string, createdAt: string, updatedAt: string, entries: int, dataSize: int, fileSize: int, lastBuildTimeS: int, numberOfPendingTasks: int, pendingTask: bool, primary: string, replicas: list, virtual: bool, abTest: record, sourceABTest: string>, nbPages: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "hitsPerPage" $hitsPerPage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/1/indexes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wait for an API key operation
#
# GET /waitForApiKey
# operationId: waitForApiKey
export def "wait-for-api-key waitForApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # API key to wait for.
  --operation: string@operation-completer-1 # Whether the API key was created, updated, or deleted.
  --apiKey: record # Used to compare fields of the `getApiKey` response on an `update` operation, to check if the `key` has been updated.
]: nothing -> record<value: string, createdAt: int, acl: list<string>, description: string, indexes: list<string>, maxHitsPerQuery: int, maxQueriesPerIPPerHour: int, queryParameters: string, referers: list<string>, validity: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar") (serialize-qp "operation" $operation "scalar") (serialize-qp "apiKey" $apiKey "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/waitForApiKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wait for operation to complete
#
# GET /waitForTask
# operationId: waitForTask
export def "wait-for-task waitForTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The name of the index on which the operation was performed.
  --taskID: int # The taskID returned by the operation. (format: int64)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "taskID" $taskID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/waitForTask" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Wait for application-level operation to complete
#
# GET /waitForAppTask
# operationId: waitForAppTask
export def "wait-for-app-task waitForAppTask" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --taskID: int # The taskID returned by the operation. (format: int64)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "taskID" $taskID "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/waitForAppTask" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all records from an index
#
# GET /browseObjects
# operationId: browseObjects
export def "browse-objects browseObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The name of the index on which the operation was performed.
  --browseParams: string # Browse parameters.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "browseParams" $browseParams "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/browseObjects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create secured API keys
#
# GET /generateSecuredApiKey
# operationId: generateSecuredApiKey
export def "generate-secured-api-key generateSecuredApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parentApiKey: string # API key from which the secured API key will inherit its restrictions.
  --restrictions: record # Restrictions to add to the API key.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentApiKey" $parentApiKey "scalar") (serialize-qp "restrictions" $restrictions "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/generateSecuredApiKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Copies the given `sourceIndexName` records, rules and synonyms to an other Algolia application for the given `destinationIndexName`
#
# GET /accountCopyIndex
# operationId: accountCopyIndex
export def "account-copy-index accountCopyIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceIndexName: string # The name of the index to copy.
  --destinationAppID: string # The application ID to write the index to.
  --destinationApiKey: string # The API Key of the `destinationAppID` to write the index to, must have write ACLs.
  --destinationIndexName: string # The name of the index to write the copied index to.
  --batchSize: int # The size of the chunk of `objects`. Defaults to 1,000. (default: 1000)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sourceIndexName" $sourceIndexName "scalar") (serialize-qp "destinationAppID" $destinationAppID "scalar") (serialize-qp "destinationApiKey" $destinationApiKey "scalar") (serialize-qp "destinationIndexName" $destinationIndexName "scalar") (serialize-qp "batchSize" $batchSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accountCopyIndex" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace all records in an index
#
# GET /replaceAllObjects
# operationId: replaceAllObjects
export def "replace-all-objects replaceAllObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The `indexName` to replace `objects` in.
  --objects: list # List of objects to replace the current objects with.
  --batchSize: int # The size of the chunk of `objects`. The number of `batch` calls will be equal to `length(objects) / batchSize`. Defaults to 1,000. (default: 1000)
  --scopes: list # List of scopes to keep in the index. Defaults to `settings`, `synonyms`, and `rules`.
]: nothing -> record<copyOperationResponse: record<taskID: int, updatedAt: string>, batchResponses: table<taskID: int, objectIDs: list>, moveOperationResponse: record<taskID: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "objects" $objects "multi") (serialize-qp "batchSize" $batchSize "scalar") (serialize-qp "scopes" $scopes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/replaceAllObjects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace all records in an index
#
# GET /replaceAllObjectsWithTransformation
# operationId: replaceAllObjectsWithTransformation
export def "replace-all-objects-with-transformation replaceAllObjectsWithTransformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The `indexName` to replace `objects` in.
  --objects: list # List of objects to replace the current objects with.
  --batchSize: int # The size of the chunk of `objects`. The number of `batch` calls will be equal to `length(objects) / batchSize`. Defaults to 1,000. (default: 1000)
  --scopes: list # List of scopes to keep in the index. Defaults to `settings`, `synonyms`, and `rules`.
]: nothing -> record<copyOperationResponse: record<taskID: int, updatedAt: string>, watchResponses: table<runID: string, eventID: string, data: list, events: list, message: string, createdAt: string>, moveOperationResponse: record<taskID: int, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "objects" $objects "multi") (serialize-qp "batchSize" $batchSize "scalar") (serialize-qp "scopes" $scopes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/replaceAllObjectsWithTransformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replace all records in an index
#
# GET /chunkedBatch
# operationId: chunkedBatch
export def "chunked-batch chunkedBatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The `indexName` to replace `objects` in.
  --objects: list # List of objects to replace the current objects with.
  --action: string@action-completer # The `batch` `action` to perform on the given array of `objects`, defaults to `addObject`.
  --waitForTasks: oneof<nothing, bool> # Whether to wait until every `batch` task has been processed. This may take longer but is more reliable.
  --batchSize: int # The size of the chunk of `objects`. The number of `batch` calls will be equal to `length(objects) / batchSize`. Defaults to 1,000.
]: nothing -> table<taskID: int, objectIDs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "objects" $objects "multi") (serialize-qp "action" $action "scalar") (serialize-qp "waitForTasks" $waitForTasks "scalar") (serialize-qp "batchSize" $batchSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/chunkedBatch" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Saves the given array of objects in the given index
#
# GET /saveObjects
# operationId: saveObjects
export def "save-objects saveObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The `indexName` to save `objects` into.
  --objects: list # The objects to save in the index.
  --waitForTasks: oneof<nothing, bool> # Whether to wait until every `batch` task has been processed. This may take longer but is more reliable. (default: false)
  --batchSize: int # The size of the chunk of `objects`. The number of `batch` calls will be equal to `length(objects) / batchSize`. Defaults to 1,000. (default: 1000)
  --requestOptions: record # The request options to pass to the `batch` method.
]: nothing -> table<taskID: int, objectIDs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "objects" $objects "multi") (serialize-qp "waitForTasks" $waitForTasks "scalar") (serialize-qp "batchSize" $batchSize "scalar") (serialize-qp "requestOptions" $requestOptions "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/saveObjects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save objects to an Algolia index by leveraging the Transformation pipeline setup using the Push connector (https://www.algolia.com/doc/guides/sending-and-managing-data/send-and-update-your-data/connectors/push)
#
# GET /saveObjectsWithTransformation
# operationId: saveObjectsWithTransformation
export def "save-objects-with-transformation saveObjectsWithTransformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The `indexName` to save `objects` into.
  --objects: list # The objects to save in the index.
  --waitForTasks: oneof<nothing, bool> # Whether to wait until every `batch` task has been processed. This may take longer but is more reliable. (default: false)
  --batchSize: int # The size of the chunk of `objects`. The number of `batch` calls will be equal to `length(objects) / batchSize`. Defaults to 1,000. (default: 1000)
  --requestOptions: record # The request options to pass to the `batch` method.
]: nothing -> table<runID: string, eventID: string, data: list<record>, events: list<record>, message: string, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "objects" $objects "multi") (serialize-qp "waitForTasks" $waitForTasks "scalar") (serialize-qp "batchSize" $batchSize "scalar") (serialize-qp "requestOptions" $requestOptions "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/saveObjectsWithTransformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes every records for the given objectIDs
#
# POST /deleteObjects
# operationId: deleteObjects
export def "delete-objects post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The `indexName` to delete `objectIDs` from.
  --objectIDs: list # The objectIDs to delete.
  --waitForTasks: oneof<nothing, bool> # Whether to wait until every `batch` task has been processed. This may take longer but is more reliable.
  --batchSize: int # The size of the chunk of `objects`. The number of `batch` calls will be equal to `length(objects) / batchSize`. Defaults to 1,000.
  --requestOptions: record # The request options to pass to the `batch` method.
]: nothing -> table<taskID: int, objectIDs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "objectIDs" $objectIDs "multi") (serialize-qp "waitForTasks" $waitForTasks "scalar") (serialize-qp "batchSize" $batchSize "scalar") (serialize-qp "requestOptions" $requestOptions "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/deleteObjects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Replaces object content of all the given objects according to their respective `objectID` field
#
# POST /partialUpdateObjects
# operationId: partialUpdateObjects
export def "partial-update-objects partialUpdateObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The `indexName` where to update `objects`.
  --objects: list # The objects to update.
  --createIfNotExists: oneof<nothing, bool> # To be provided if non-existing objects are passed, otherwise, the call will fail. (default: false)
  --waitForTasks: oneof<nothing, bool> # Whether to wait until every `batch` task has been processed. This may take longer but is more reliable. (default: false)
  --batchSize: int # The size of the chunk of `objects`. The number of `batch` calls will be equal to `length(objects) / batchSize`. Defaults to 1,000. (default: 1000)
  --requestOptions: record # The request options to pass to the `batch` method.
]: nothing -> table<taskID: int, objectIDs: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "objects" $objects "multi") (serialize-qp "createIfNotExists" $createIfNotExists "scalar") (serialize-qp "waitForTasks" $waitForTasks "scalar") (serialize-qp "batchSize" $batchSize "scalar") (serialize-qp "requestOptions" $requestOptions "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/partialUpdateObjects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save objects to an Algolia index by leveraging the Transformation pipeline setup using the Push connector (https://www.algolia.com/doc/guides/sending-and-managing-data/send-and-update-your-data/connectors/push)
#
# POST /partialUpdateObjectsWithTransformation
# operationId: partialUpdateObjectsWithTransformation
export def "partial-update-objects-with-transformation partialUpdateObjectsWithTransformation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The `indexName` where to update `objects`.
  --objects: list # The objects to update.
  --createIfNotExists: oneof<nothing, bool> # To be provided if non-existing objects are passed, otherwise, the call will fail. (default: false)
  --waitForTasks: oneof<nothing, bool> # Whether to wait until every `batch` task has been processed. This may take longer but is more reliable. (default: false)
  --batchSize: int # The size of the chunk of `objects`. The number of `batch` calls will be equal to `length(objects) / batchSize`. Defaults to 1,000. (default: 1000)
  --requestOptions: record # The request options to pass to the `batch` method.
]: nothing -> table<runID: string, eventID: string, data: list<record>, events: list<record>, message: string, createdAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar") (serialize-qp "objects" $objects "multi") (serialize-qp "createIfNotExists" $createIfNotExists "scalar") (serialize-qp "waitForTasks" $waitForTasks "scalar") (serialize-qp "batchSize" $batchSize "scalar") (serialize-qp "requestOptions" $requestOptions "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/partialUpdateObjectsWithTransformation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check if an index exists or not
#
# GET /indexExists
# operationId: indexExists
export def "index-exists indexExists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --indexName: string # The name of the index to check.
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "indexName" $indexName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/indexExists" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Switch the API key used to authenticate requests
#
# GET /setClientApiKey
# operationId: setClientApiKey
export def "set-client-api-key setClientApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apiKey: string # API key to use for subsequent requests.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-algolia-application-id"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "apiKey" $apiKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/setClientApiKey" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
