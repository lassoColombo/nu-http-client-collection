# Auto-generated client for SearchIndexClient v2019-05-06-Preview
# Source: https://api.apis.guru/v2/specs/azure.com/search-searchindex/2019-05-06-Preview/swagger.json
# Auth: --token flag or $env.SEARCHINDEXCLIENT_TOKEN

const BASE_URL = "https://{searchServiceName}.search.windows.net/indexes('{indexName}')"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SEARCHINDEXCLIENT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://{searchServiceName}.search.windows.net/indexes('{indexName}')"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def query-type-completer [] { ["full" "simple"] }
def search-mode-completer [] { ["all" "any"] }
def autocomplete-mode-completer [] { ["oneTerm" "oneTermWithContext" "twoTerms"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "docs list-documents-get" } } | get name | first)
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

# Searches for documents in the index.
#
# GET /docs
# Docs: https://docs.microsoft.com/rest/api/searchservice/Search-Documents
# operationId: Documents_SearchGet
export def "docs list-documents-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # A full-text search query expression; Use "*" or omit this parameter to match all documents.
  --count: oneof<nothing, bool> # A value that specifies whether to fetch the total count of results. Default is false. Setting this value to true may have a performance impact. Note that the count returned is an approximation.
  --facet: list<string> # The list of facet expressions to apply to the search query. Each facet expression contains a field name, optionally followed by a comma-separated list of name:value pairs.
  --filter: string # The OData $filter expression to apply to the search query.
  --highlight: list<string> # The list of field names to use for hit highlights. Only searchable fields can be used for hit highlighting.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. Default is </em>.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. Default is <em>.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by a search query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 100. (format: double)
  --orderby: list<string> # The list of OData $orderby expressions by which to sort the results. Each expression can be either a field name or a call to either the geo.distance() or the search.score() functions. Each expression can be followed by asc to indicate ascending, and desc to indicate descending. The default is ascending order. Ties will be broken by the match scores of documents. If no OrderBy is specified, the default sort order is descending by document match score. There can be at most 32 $orderby clauses.
  --query-type: string@query-type-completer # A value that specifies the syntax of the search query. The default is 'simple'. Use 'full' if your query uses the Lucene query syntax.
  --scoring-parameter: list<string> # The list of parameter values to be used in scoring functions (for example, referencePointParameter) using the format name-values. For example, if the scoring profile defines a function with a parameter called 'mylocation' the parameter string would be "mylocation--122.2,44.8" (without the quotes).
  --scoring-profile: string # The name of a scoring profile to evaluate match scores for matching documents in order to sort the results.
  --search-fields: list<string> # The list of field names to which to scope the full-text search. When using fielded search (fieldName:searchExpression) in a full Lucene query, the field names of each fielded search expression take precedence over any field names listed in this parameter.
  --search-mode: string@search-mode-completer # A value that specifies whether any or all of the search terms must be matched in order to count the document as a match.
  --select: list<string> # The list of fields to retrieve. If unspecified, all fields marked as retrievable in the schema are included.
  --skip: int # The number of search results to skip. This value cannot be greater than 100,000. If you need to scan documents in sequence, but cannot use $skip due to this limitation, consider using $orderby on a totally-ordered key and $filter with a range query instead. (format: int32)
  --top: int # The number of search results to retrieve. This can be used in conjunction with $skip to implement client-side paging of search results. If results are truncated due to server-side paging, the response will include a continuation token that can be used to issue another Search request for the next page of results. (format: int32)
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<_odata_count: int, _odata_nextLink: string, _search_coverage: float, _search_facets: record, _search_nextPageParameters: record<count: bool, facets: list<string>, filter: string, highlight: string, highlightPostTag: string, highlightPreTag: string, minimumCoverage: float, orderby: string, queryType: string, scoringParameters: list<string>, scoringProfile: string, search: string, searchFields: string, searchMode: string, select: string, skip: int, top: int>, value: table<_search_highlights: record, _search_score: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "$count" $count "scalar") (serialize-qp "facet" $facet "multi") (serialize-qp "$filter" $filter "scalar") (serialize-qp "highlight" $highlight "csv") (serialize-qp "highlightPostTag" $highlight_post_tag "scalar") (serialize-qp "highlightPreTag" $highlight_pre_tag "scalar") (serialize-qp "minimumCoverage" $minimum_coverage "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "queryType" $query_type "scalar") (serialize-qp "scoringParameter" $scoring_parameter "multi") (serialize-qp "scoringProfile" $scoring_profile "scalar") (serialize-qp "searchFields" $search_fields "csv") (serialize-qp "searchMode" $search_mode "scalar") (serialize-qp "$select" $select "csv") (serialize-qp "$skip" $skip "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "$count": $count, "facet": $facet, "$filter": $filter, "highlight": $highlight, "highlightPostTag": $highlight_post_tag, "highlightPreTag": $highlight_pre_tag, "minimumCoverage": $minimum_coverage, "$orderby": $orderby, "queryType": $query_type, "scoringParameter": $scoring_parameter, "scoringProfile": $scoring_profile, "searchFields": $search_fields, "searchMode": $search_mode, "$select": $select, "$skip": $skip, "$top": $top, "api-version": $api_version} | compact), body: null}
}

# Retrieves a document from the index.
#
# GET /docs('{key}')
# Docs: https://docs.microsoft.com/rest/api/searchservice/lookup-document
# operationId: Documents_Get
export def "docs get-documents" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --select: list<string> # List of field names to retrieve for the document; Any field not retrieved will be missing from the returned document.
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let qp = [(serialize-qp "$select" $select "csv") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/docs('{key}')") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"$select": $select, "api-version": $api_version} | compact), body: null}
}

# Queries the number of documents in the index.
#
# GET /docs/$count
# Docs: https://docs.microsoft.com/rest/api/searchservice/Count-Documents
# operationId: Documents_Count
export def "docs-count get-documents-count" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> oneof<int, string, record, nothing> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs/$count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Autocompletes incomplete query terms based on input text and matching terms in the index.
#
# GET /docs/search.autocomplete
# Docs: https://docs.microsoft.com/rest/api/searchservice/autocomplete
# operationId: Documents_AutocompleteGet
export def "docs-search-autocomplete get-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --search: string # The incomplete term which should be auto-completed.
  --suggester-name: string # The name of the suggester as specified in the suggesters collection that's part of the index definition.
  --autocomplete-mode: string@autocomplete-mode-completer # Specifies the mode for Autocomplete. The default is 'oneTerm'. Use 'twoTerms' to get shingles and 'oneTermWithContext' to use the current context while producing auto-completed terms.
  --filter: string # An OData expression that filters the documents used to produce completed terms for the Autocomplete result.
  --fuzzy: oneof<nothing, bool> # A value indicating whether to use fuzzy matching for the autocomplete query. Default is false. When set to true, the query will find terms even if there's a substituted or missing character in the search text. While this provides a better experience in some scenarios, it comes at a performance cost as fuzzy autocomplete queries are slower and consume more resources.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. If omitted, hit highlighting is disabled.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. If omitted, hit highlighting is disabled.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by an autocomplete query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 80. (format: double)
  --search-fields: list<string> # The list of field names to consider when querying for auto-completed terms. Target fields must be included in the specified suggester.
  --top: int # The number of auto-completed terms to retrieve. This must be a value between 1 and 100. The default is 5. (format: int32)
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<value: table<queryPlusText: string, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "suggesterName" $suggester_name "scalar") (serialize-qp "autocompleteMode" $autocomplete_mode "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "fuzzy" $fuzzy "scalar") (serialize-qp "highlightPostTag" $highlight_post_tag "scalar") (serialize-qp "highlightPreTag" $highlight_pre_tag "scalar") (serialize-qp "minimumCoverage" $minimum_coverage "scalar") (serialize-qp "searchFields" $search_fields "csv") (serialize-qp "$top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs/search.autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "search": $search, "suggesterName": $suggester_name, "autocompleteMode": $autocomplete_mode, "$filter": $filter, "fuzzy": $fuzzy, "highlightPostTag": $highlight_post_tag, "highlightPreTag": $highlight_pre_tag, "minimumCoverage": $minimum_coverage, "searchFields": $search_fields, "$top": $top} | compact), body: null}
}

# Sends a batch of document write actions to the index.
#
# POST /docs/search.index
# Docs: https://docs.microsoft.com/rest/api/searchservice/addupdate-or-delete-documents
# operationId: Documents_Index
# --value item shape: {@search.action?: "upload"|"merge"|"mergeOrUpload"|"delete"}
export def "docs-search-index create-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  value: list # The actions in the batch. — item shape: {@search.action?: "upload"|"merge"|"mergeOrUpload"|"delete"}
]: any -> record<value: table<errorMessage: string, key: string, status: bool, statusCode: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs/search.index" $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Autocompletes incomplete query terms based on input text and matching terms in the index.
#
# POST /docs/search.post.autocomplete
# Docs: https://docs.microsoft.com/rest/api/searchservice/autocomplete
# operationId: Documents_AutocompletePost
export def "docs-search-post-autocomplete create-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --autocomplete-mode: string@autocomplete-mode-completer # Specifies the mode for Autocomplete. The default is 'oneTerm'. Use 'twoTerms' to get shingles and 'oneTermWithContext' to use the current context in producing autocomplete terms.
  --filter: string # An OData expression that filters the documents used to produce completed terms for the Autocomplete result.
  --fuzzy: oneof<nothing, bool> # A value indicating whether to use fuzzy matching for the autocomplete query. Default is false. When set to true, the query will autocomplete terms even if there's a substituted or missing character in the search text. While this provides a better experience in some scenarios, it comes at a performance cost as fuzzy autocomplete queries are slower and consume more resources.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. If omitted, hit highlighting is disabled.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. If omitted, hit highlighting is disabled.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by an autocomplete query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 80. (format: double)
  --search: string # The search text on which to base autocomplete results.
  --search-fields: string # The comma-separated list of field names to consider when querying for auto-completed terms. Target fields must be included in the specified suggester.
  --suggester-name: string # The name of the suggester as specified in the suggesters collection that's part of the index definition.
  --top: int # The number of auto-completed terms to retrieve. This must be a value between 1 and 100. The default is 5. (format: int32)
]: any -> record<value: table<queryPlusText: string, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs/search.post.autocomplete" $qp)
  let req_body = {"autocompleteMode": $autocomplete_mode, "filter": $filter, "fuzzy": $fuzzy, "highlightPostTag": $highlight_post_tag, "highlightPreTag": $highlight_pre_tag, "minimumCoverage": $minimum_coverage, "search": $search, "searchFields": $search_fields, "suggesterName": $suggester_name, "top": $top} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Searches for documents in the index.
#
# POST /docs/search.post.search
# Docs: https://docs.microsoft.com/rest/api/searchservice/Search-Documents
# operationId: Documents_SearchPost
export def "docs-search-post-search list-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --count: oneof<nothing, bool> # A value that specifies whether to fetch the total count of results. Default is false. Setting this value to true may have a performance impact. Note that the count returned is an approximation.
  --facets: list<string> # The list of facet expressions to apply to the search query. Each facet expression contains a field name, optionally followed by a comma-separated list of name:value pairs.
  --filter: string # The OData $filter expression to apply to the search query.
  --highlight: string # The comma-separated list of field names to use for hit highlights. Only searchable fields can be used for hit highlighting.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. Default is </em>.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. Default is <em>.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by a search query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 100. (format: double)
  --orderby: string # The comma-separated list of OData $orderby expressions by which to sort the results. Each expression can be either a field name or a call to either the geo.distance() or the search.score() functions. Each expression can be followed by asc to indicate ascending, or desc to indicate descending. The default is ascending order. Ties will be broken by the match scores of documents. If no $orderby is specified, the default sort order is descending by document match score. There can be at most 32 $orderby clauses.
  --query-type: string@query-type-completer # Specifies the syntax of the search query. The default is 'simple'. Use 'full' if your query uses the Lucene query syntax.
  --scoring-parameters: list<string> # The list of parameter values to be used in scoring functions (for example, referencePointParameter) using the format name-values. For example, if the scoring profile defines a function with a parameter called 'mylocation' the parameter string would be "mylocation--122.2,44.8" (without the quotes).
  --scoring-profile: string # The name of a scoring profile to evaluate match scores for matching documents in order to sort the results.
  --search: string # A full-text search query expression; Use "*" or omit this parameter to match all documents.
  --search-fields: string # The comma-separated list of field names to which to scope the full-text search. When using fielded search (fieldName:searchExpression) in a full Lucene query, the field names of each fielded search expression take precedence over any field names listed in this parameter.
  --search-mode: string@search-mode-completer # Specifies whether any or all of the search terms must be matched in order to count the document as a match.
  --select: string # The comma-separated list of fields to retrieve. If unspecified, all fields marked as retrievable in the schema are included.
  --skip: int # The number of search results to skip. This value cannot be greater than 100,000. If you need to scan documents in sequence, but cannot use skip due to this limitation, consider using orderby on a totally-ordered key and filter with a range query instead. (format: int32)
  --top: int # The number of search results to retrieve. This can be used in conjunction with $skip to implement client-side paging of search results. If results are truncated due to server-side paging, the response will include a continuation token that can be used to issue another Search request for the next page of results. (format: int32)
]: any -> record<_odata_count: int, _odata_nextLink: string, _search_coverage: float, _search_facets: record, _search_nextPageParameters: record<count: bool, facets: list<string>, filter: string, highlight: string, highlightPostTag: string, highlightPreTag: string, minimumCoverage: float, orderby: string, queryType: string, scoringParameters: list<string>, scoringProfile: string, search: string, searchFields: string, searchMode: string, select: string, skip: int, top: int>, value: table<_search_highlights: record, _search_score: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs/search.post.search" $qp)
  let req_body = {"count": $count, "facets": $facets, "filter": $filter, "highlight": $highlight, "highlightPostTag": $highlight_post_tag, "highlightPreTag": $highlight_pre_tag, "minimumCoverage": $minimum_coverage, "orderby": $orderby, "queryType": $query_type, "scoringParameters": $scoring_parameters, "scoringProfile": $scoring_profile, "search": $search, "searchFields": $search_fields, "searchMode": $search_mode, "select": $select, "skip": $skip, "top": $top} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Suggests documents in the index that match the given partial query text.
#
# POST /docs/search.post.suggest
# Docs: https://docs.microsoft.com/rest/api/searchservice/suggestions
# operationId: Documents_SuggestPost
export def "docs-search-post-suggest create-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
  --filter: string # An OData expression that filters the documents considered for suggestions.
  --fuzzy: oneof<nothing, bool> # A value indicating whether to use fuzzy matching for the suggestion query. Default is false. When set to true, the query will find suggestions even if there's a substituted or missing character in the search text. While this provides a better experience in some scenarios, it comes at a performance cost as fuzzy suggestion searches are slower and consume more resources.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. If omitted, hit highlighting of suggestions is disabled.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. If omitted, hit highlighting of suggestions is disabled.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by a suggestion query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 80. (format: double)
  --orderby: string # The comma-separated list of OData $orderby expressions by which to sort the results. Each expression can be either a field name or a call to either the geo.distance() or the search.score() functions. Each expression can be followed by asc to indicate ascending, or desc to indicate descending. The default is ascending order. Ties will be broken by the match scores of documents. If no $orderby is specified, the default sort order is descending by document match score. There can be at most 32 $orderby clauses.
  --search: string # The search text to use to suggest documents. Must be at least 1 character, and no more than 100 characters.
  --search-fields: string # The comma-separated list of field names to search for the specified search text. Target fields must be included in the specified suggester.
  --select: string # The comma-separated list of fields to retrieve. If unspecified, only the key field will be included in the results.
  --suggester-name: string # The name of the suggester as specified in the suggesters collection that's part of the index definition.
  --top: int # The number of suggestions to retrieve. This must be a value between 1 and 100. The default is 5. (format: int32)
]: any -> record<_search_coverage: float, value: table<_search_text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs/search.post.suggest" $qp)
  let req_body = {"filter": $filter, "fuzzy": $fuzzy, "highlightPostTag": $highlight_post_tag, "highlightPreTag": $highlight_pre_tag, "minimumCoverage": $minimum_coverage, "orderby": $orderby, "search": $search, "searchFields": $search_fields, "select": $select, "suggesterName": $suggester_name, "top": $top} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Suggests documents in the index that match the given partial query text.
#
# GET /docs/search.suggest
# Docs: https://docs.microsoft.com/rest/api/searchservice/suggestions
# operationId: Documents_SuggestGet
export def "docs-search-suggest get-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # The search text to use to suggest documents. Must be at least 1 character, and no more than 100 characters.
  --suggester-name: string # The name of the suggester as specified in the suggesters collection that's part of the index definition.
  --filter: string # An OData expression that filters the documents considered for suggestions.
  --fuzzy: oneof<nothing, bool> # A value indicating whether to use fuzzy matching for the suggestions query. Default is false. When set to true, the query will find terms even if there's a substituted or missing character in the search text. While this provides a better experience in some scenarios, it comes at a performance cost as fuzzy suggestions queries are slower and consume more resources.
  --highlight-post-tag: string # A string tag that is appended to hit highlights. Must be set with highlightPreTag. If omitted, hit highlighting of suggestions is disabled.
  --highlight-pre-tag: string # A string tag that is prepended to hit highlights. Must be set with highlightPostTag. If omitted, hit highlighting of suggestions is disabled.
  --minimum-coverage: float # A number between 0 and 100 indicating the percentage of the index that must be covered by a suggestions query in order for the query to be reported as a success. This parameter can be useful for ensuring search availability even for services with only one replica. The default is 80. (format: double)
  --orderby: list<string> # The list of OData $orderby expressions by which to sort the results. Each expression can be either a field name or a call to either the geo.distance() or the search.score() functions. Each expression can be followed by asc to indicate ascending, or desc to indicate descending. The default is ascending order. Ties will be broken by the match scores of documents. If no $orderby is specified, the default sort order is descending by document match score. There can be at most 32 $orderby clauses.
  --search-fields: list<string> # The list of field names to search for the specified search text. Target fields must be included in the specified suggester.
  --select: list<string> # The list of fields to retrieve. If unspecified, only the key field will be included in the results.
  --top: int # The number of suggestions to retrieve. The value must be a number between 1 and 100. The default is 5. (format: int32)
  --api-version: string # Client Api Version.
  --client-request-id: string # The tracking ID sent with the request to help with debugging.
]: nothing -> record<_search_coverage: float, value: table<_search_text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "suggesterName" $suggester_name "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "fuzzy" $fuzzy "scalar") (serialize-qp "highlightPostTag" $highlight_post_tag "scalar") (serialize-qp "highlightPreTag" $highlight_pre_tag "scalar") (serialize-qp "minimumCoverage" $minimum_coverage "scalar") (serialize-qp "$orderby" $orderby "csv") (serialize-qp "searchFields" $search_fields "csv") (serialize-qp "$select" $select "csv") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/docs/search.suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"client-request-id": $client_request_id} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"search": $search, "suggesterName": $suggester_name, "$filter": $filter, "fuzzy": $fuzzy, "highlightPostTag": $highlight_post_tag, "highlightPreTag": $highlight_pre_tag, "minimumCoverage": $minimum_coverage, "$orderby": $orderby, "searchFields": $search_fields, "$select": $select, "$top": $top, "api-version": $api_version} | compact), body: null}
}
