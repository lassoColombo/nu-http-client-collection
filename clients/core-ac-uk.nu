# Auto-generated client for CORE API v2 v2.0
# Source: https://api.apis.guru/v2/specs/core.ac.uk/2.0/swagger.json
# Auth: --token flag or $env.CORE_API_V2_TOKEN

const BASE_URL = "http://core.ac.uk/api-v2"
const DEFAULT_AUTH = "query-apiKey"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CORE_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "query-apiKey" => { {headers: {}, query: $"apiKey=($token_val)"} }
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

def base-url-completer [] { ["http://core.ac.uk/api-v2"] }
def auth-scheme-completer [] { ["query-apiKey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "articles-dedup create-near-duplicate" } } | get name | first)
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

# Get all near duplicate articles
#
# POST /articles/dedup
# operationId: nearDuplicateArticles
export def "articles-dedup create-near-duplicate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --doi: string # The DOI for which the duplicates will be identified
  --title: string # Title to match when looking for duplicate articles. Only useful when either value for @year or @description is supplied.
  --year: string # Year the article was published. Only useful when value for @title is supplied.
  --description: string # Abstract for an article based on which its duplicates will be found. Only useful when value for @title is supplied.
  --fulltext: string # Full text for an article based on which its duplicates will be found.
  --identifier: string # Article identifier for which the duplicates will be identified. Only useful when either values for @doi or (@title and @year) or (@title and @abstract) or @fulltext are supplied.
  --repository-id: string # Limit the duplicates search to particular repository id.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "doi" $doi "scalar") (serialize-qp "title" $title "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "description" $description "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "identifier" $identifier "scalar") (serialize-qp "repositoryId" $repository_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles/dedup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch operation for retrieving articles by CORE ID
#
# POST /articles/get
# operationId: getArticleByCoreIdBatch
export def "articles-get get-by-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: oneof<nothing, bool> # Whether to retrieve the full article metadata or only the IDs. The default value is true (default: true)
  --fulltext: oneof<nothing, bool> # Whether to retrieve fulltexts of the articles. The default value is false (default: false)
  --citations: oneof<nothing, bool> # Whether to retrieve citations found in the articles. The default value is false (default: false)
  --similar: oneof<nothing, bool> # Whether to retrieve lists of similar articles. The default value is false. Because the similar articles are calculated on demand, setting this parameter to true might slightly slow down the response time (default: false)
  --duplicate: oneof<nothing, bool> # Whether to retrieve CORE IDs of different versions of the articles. The default value is false (default: false)
  --urls: oneof<nothing, bool> # Whether to retrieve lists of URLs of the article fulltexts. The default value is false (default: false)
  --faithful-metadata: oneof<nothing, bool> # Returns the records raw XML metadata from the original repository. The default value is false (default: false)
  --body: record
]: any -> table<data: record<authors: list, citations: list, contributors: list, datePublished: string, description: string, doi: string, downloadUrl: string, fulltext: string, fulltextIdentifier: string, fulltextUrls: list, id: int, identifiers: list, journals: list, language: record, oai: string, publisher: string, rawRecordXml: record, relations: list, repositories: list, repositoryDocument: any, similarities: list, subjects: list, title: string, topics: list, types: list, year: int>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles/get" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get article by CORE ID
#
# GET /articles/get/{coreId}
# operationId: getArticleByCoreId
export def "articles-get get" [
  core_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: oneof<nothing, bool> # Whether to retrieve the full article metadata or only the ID. The default value is true. (default: true)
  --fulltext: oneof<nothing, bool> # Whether to retrieve full text of the article. The default value is false (default: false)
  --citations: oneof<nothing, bool> # Whether to retrieve citations found in the article. The default value is false (default: false)
  --similar: oneof<nothing, bool> # Whether to retrieve a list of similar articles. The default value is false. Because the similar articles are calculated on demand, setting this parameter to true might slightly slow down the response time (default: false)
  --duplicate: oneof<nothing, bool> # Whether to retrieve a list of CORE IDs of different versions of the article. The default value is false (default: false)
  --urls: oneof<nothing, bool> # Whether to retrieve a list of URLs from which the article can be downloaded. This can include links to PDFs as well as HTML pages. The default value is false (default: false)
  --faithful-metadata: oneof<nothing, bool> # Returns the records raw XML metadata from the original repository. The default value is false (default: false)
]: nothing -> record<data: record<authors: list<string>, citations: list<record>, contributors: list<string>, datePublished: string, description: string, doi: string, downloadUrl: string, fulltext: string, fulltextIdentifier: string, fulltextUrls: list<string>, id: int, identifiers: list<string>, journals: list<record>, language: record<deletedStatus: int, depositedDate: string, indexed: int, metadataUpdated: string, pdfOrigin: string, pdfSize: int, pdfStatus: int, tdmOnly: bool, textStatus: int, timestamp: string>, oai: string, publisher: string, rawRecordXml: record<datetime: string, metadata: string>, relations: list<string>, repositories: list<record>, repositoryDocument: any, similarities: list<record>, subjects: list<string>, title: string, topics: list<string>, types: list<string>, year: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({core_id: (encode-path-segment $core_id)} | format pattern "/articles/get/{core_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get fulltext PDF by CORE ID
#
# GET /articles/get/{coreId}/download/pdf
# operationId: getArticlePdfByCoreId
export def "articles-get-download-pdf get" [
  core_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({core_id: (encode-path-segment $core_id)} | format pattern "/articles/get/{core_id}/download/pdf"))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get article history by CORE ID
#
# GET /articles/get/{coreId}/history
# operationId: getArticleHistoryByCoreId
export def "articles-get-history get" [
  core_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the history results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
]: nothing -> record<data: table<datetime: string, metadata: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({core_id: (encode-path-segment $core_id)} | format pattern "/articles/get/{core_id}/history") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch operation for search through articles
#
# POST /articles/search
# operationId: searchArticlesBatch
export def "articles-search list-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: oneof<nothing, bool> # Whether to retrieve the full article metadata or only the ID. The default value is true. (default: true)
  --fulltext: oneof<nothing, bool> # Whether to retrieve full text of the article. The default value is false (default: false)
  --citations: oneof<nothing, bool> # Whether to retrieve citations found in the article. The default value is false (default: false)
  --similar: oneof<nothing, bool> # Whether to retrieve a list of similar articles. The default value is false. Because the similar articles are calculated on demand, setting this parameter to true might slightly slow down the response time (default: false)
  --duplicate: oneof<nothing, bool> # Whether to retrieve a list of CORE IDs of different versions of the article. The default value is false (default: false)
  --urls: oneof<nothing, bool> # Whether to retrieve a list of URLs from which the article can be downloaded. This can include links to PDFs as well as HTML pages. The default value is false (default: false)
  --faithful-metadata: oneof<nothing, bool> # Whether to retrieve the raw XML metadata of the article. The default value is false (default: false)
  --body: record
]: any -> table<data: list<record>, status: string, totalHits: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles/search" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search through all documents
#
# GET /articles/search/{query}
# operationId: searchArticles
export def "articles-search list" [
  query: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the search results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
  --metadata: oneof<nothing, bool> # Whether to retrieve the full article metadata or only the ID. The default value is true. (default: true)
  --fulltext: oneof<nothing, bool> # Whether to retrieve full text of the article. The default value is false (default: false)
  --citations: oneof<nothing, bool> # Whether to retrieve citations found in the article. The default value is false (default: false)
  --similar: oneof<nothing, bool> # Whether to retrieve a list of similar articles. The default value is false. Because the similar articles are calculated on demand, setting this parameter to true might slightly slow down the response time (default: false)
  --duplicate: oneof<nothing, bool> # Whether to retrieve a list of CORE IDs of different versions of the article. The default value is false (default: false)
  --urls: oneof<nothing, bool> # Whether to retrieve a list of URLs from which the article can be downloaded. This can include links to PDFs as well as HTML pages. The default value is false (default: false)
  --faithful-metadata: oneof<nothing, bool> # Returns the records raw XML metadata from the original repository. The default value is false (default: false)
]: nothing -> record<data: table<authors: list, citations: list, contributors: list, datePublished: string, description: string, doi: string, downloadUrl: string, fulltext: string, fulltextIdentifier: string, fulltextUrls: list, id: int, identifiers: list, journals: list, language: record, oai: string, publisher: string, rawRecordXml: record, relations: list, repositories: list, repositoryDocument: any, similarities: list, subjects: list, title: string, topics: list, types: list, year: int>, status: string, totalHits: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/articles/search/{query}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get articles by similarity to a text
#
# POST /articles/similar
# operationId: similarArticles
export def "articles-similar create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: int # How many similar articles to retrieve at most. Can be any number betwen 1 and 100, default is 10 (default: 10)
  --metadata: oneof<nothing, bool> # Whether to retrieve the full article metadata or only the IDs of the similar articles. The default value is true (default: true)
  --fulltext: oneof<nothing, bool> # Whether to retrieve fulltexts of the similar articles. The default value is false (default: false)
  --citations: oneof<nothing, bool> # Whether to retrieve citations found in the articles. The default value is false (default: false)
  --similar: oneof<nothing, bool> # Whether to retrieve lists of similar articles. The default value is false. Because the similar articles are calculated on demand, setting this parameter to true might slightly slow down the response time (default: false)
  --duplicate: oneof<nothing, bool> # Whether to retrieve CORE IDs of different versions of the articles. The default value is false (default: false)
  --urls: oneof<nothing, bool> # Whether to retrieve lists of URLs of the article fulltexts. The default value is false (default: false)
  --faithful-metadata: oneof<nothing, bool> # Whether to retrieve the raw XML metadata of the articles. The default value is false (default: false)
  text: string # Find Similar articles based on this string
]: any -> record<data: table<authors: list, citations: list, contributors: list, datePublished: string, description: string, doi: string, downloadUrl: string, fulltext: string, fulltextIdentifier: string, fulltextUrls: list, id: int, identifiers: list, journals: list, language: record, oai: string, publisher: string, rawRecordXml: record, relations: list, repositories: list, repositoryDocument: any, similarities: list, subjects: list, title: string, topics: list, types: list, year: int>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles/similar" $qp)
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Batch operation for retrieving journals by ISSN
#
# POST /journals/get
# operationId: getJournalByIssnBatch
export def "journals-get get-by-issn-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<data: record<identifiers: list, language: string, publisher: string, rights: string, subjects: list, title: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/journals/get")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Find journal by ISSN
#
# GET /journals/get/{issn}
# operationId: getJournalByIssn
export def "journals-get get" [
  issn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<identifiers: list<string>, language: string, publisher: string, rights: string, subjects: list<string>, title: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({issn: (encode-path-segment $issn)} | format pattern "/journals/get/{issn}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch operation for search through journals
#
# POST /journals/search
export def "journals-search create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<data: record<identifiers: list, language: string, publisher: string, rights: string, subjects: list, title: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/journals/search")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search through journals
#
# GET /journals/search/{query}
export def "journals-search get" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the search results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
]: nothing -> record<data: table<identifiers: list, language: string, publisher: string, rights: string, subjects: list, title: string>, status: string, totalHits: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/journals/search/{query}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch operation for retrieving repositories by CORE repository ID
#
# POST /repositories/get
# operationId: getRepositoryByIdBatch
export def "repositories-get get-repository-by-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stats: oneof<nothing, bool> # Whether to retrieve statistics about the repository. The default value is false (default: false)
  --deposit-history: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --deposit-history-cumulative: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --body: record
]: any -> table<data: record<dataProviderSourceStats: list, history: list, historyCumulative: list, id: int, lastSeen: string, name: string, openDoarId: int, repositoryLocation: record, repositoryStats: record, uri: string, urlHomepage: string, urlOaipmh: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stats" $stats "scalar") (serialize-qp "depositHistory" $deposit_history "scalar") (serialize-qp "depositHistoryCumulative" $deposit_history_cumulative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories/get" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get repository by CORE repository ID
#
# GET /repositories/get/{repositoryId}
# operationId: getRepositoryById
export def "repositories-get get-repository" [
  repository_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stats: oneof<nothing, bool> # Whether to retrieve statistics about the repository. The default value is false (default: false)
  --deposit-history: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --deposit-history-cumulative: oneof<nothing, bool> # Returns deposit history over time (default: false)
]: nothing -> record<data: record<dataProviderSourceStats: list<any>, history: list<any>, historyCumulative: list<any>, id: int, lastSeen: string, name: string, openDoarId: int, repositoryLocation: record<country: string, countryCode: string, id: int, latitude: int, longitude: int, repositoryName: string>, repositoryStats: record<countFulltext: int, countMetadata: int, dateLastProcessed: string>, uri: string, urlHomepage: string, urlOaipmh: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stats" $stats "scalar") (serialize-qp "depositHistory" $deposit_history "scalar") (serialize-qp "depositHistoryCumulative" $deposit_history_cumulative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({repository_id: (encode-path-segment $repository_id)} | format pattern "/repositories/get/{repository_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch operation for searching through repositories
#
# POST /repositories/search
export def "repositories-search create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stats: oneof<nothing, bool> # Whether to retrieve statistics about the repository. The default value is false (default: false)
  --deposit-history: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --deposit-history-cumulative: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --body: record
]: any -> record<data: table<dataProviderSourceStats: list, history: list, historyCumulative: list, id: int, lastSeen: string, name: string, openDoarId: int, repositoryLocation: record, repositoryStats: record, uri: string, urlHomepage: string, urlOaipmh: string>, status: string, totalHits: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stats" $stats "scalar") (serialize-qp "depositHistory" $deposit_history "scalar") (serialize-qp "depositHistoryCumulative" $deposit_history_cumulative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories/search" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search through all repositories
#
# GET /repositories/search/{query}
export def "repositories-search get" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the search results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
  --stats: oneof<nothing, bool> # Whether to retrieve statistics about the repository. The default value is false (default: false)
  --deposit-history: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --deposit-history-cumulative: oneof<nothing, bool> # Returns deposit history over time (default: false)
]: nothing -> record<data: table<dataProviderSourceStats: list, history: list, historyCumulative: list, id: int, lastSeen: string, name: string, openDoarId: int, repositoryLocation: record, repositoryStats: record, uri: string, urlHomepage: string, urlOaipmh: string>, status: string, totalHits: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "depositHistory" $deposit_history "scalar") (serialize-qp "depositHistoryCumulative" $deposit_history_cumulative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/repositories/search/{query}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Batch operation for search through all resources
#
# POST /search
export def "search create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> table<data: list<record>, status: string, totalHits: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Search through all resources
#
# GET /search/{query}
export def "search get" [
  query: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the search results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
]: nothing -> record<data: table<id: string, type: string>, status: string, totalHits: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/search/{query}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
