# Auto-generated client for CORE API v2 v2.0
# Source: https://api.apis.guru/v2/specs/core.ac.uk/2.0/swagger.json
# Auth: --token flag or $env.CORE_API_V2_TOKEN

const BASE_URL = "http://core.ac.uk/api-v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o CORE_API_V2_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-apiKey" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "apiKey")=(encode-path-segment $token_val)", location: "query"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["http://core.ac.uk/api-v2"] }
def auth-scheme-completer [] { ["query-apiKey"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/articles/dedup" $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"doi": $doi, "title": $title, "year": $year, "description": $description, "fulltext": $fulltext, "identifier": $identifier, "repositoryId": $repository_id} | compact)
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req null $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: oneof<nothing, bool> # Whether to retrieve the full article metadata or only the IDs. The default value is true (default: true)
  --fulltext: oneof<nothing, bool> # Whether to retrieve fulltexts of the articles. The default value is false (default: false)
  --citations: oneof<nothing, bool> # Whether to retrieve citations found in the articles. The default value is false (default: false)
  --similar: oneof<nothing, bool> # Whether to retrieve lists of similar articles. The default value is false. Because the similar articles are calculated on demand, setting this parameter to true might slightly slow down the response time (default: false)
  --duplicate: oneof<nothing, bool> # Whether to retrieve CORE IDs of different versions of the articles. The default value is false (default: false)
  --urls: oneof<nothing, bool> # Whether to retrieve lists of URLs of the article fulltexts. The default value is false (default: false)
  --faithful-metadata: oneof<nothing, bool> # Returns the records raw XML metadata from the original repository. The default value is false (default: false)
  --body: list
]: any -> table<data: record<authors: list, citations: list, contributors: list, datePublished: string, description: string, doi: string, downloadUrl: string, fulltext: string, fulltextIdentifier: string, fulltextUrls: list, id: int, identifiers: list, journals: list, language: record, oai: string, publisher: string, rawRecordXml: record, relations: list, repositories: list, repositoryDocument: any, similarities: list, subjects: list, title: string, topics: list, types: list, year: int>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles/get" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"metadata": $metadata, "fulltext": $fulltext, "citations": $citations, "similar": $similar, "duplicate": $duplicate, "urls": $urls, "faithfulMetadata": $faithful_metadata} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($core_id | is-empty) { error make --unspanned { msg: "path parameter 'coreId' must be non-empty" } }
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({core_id: (encode-path-segment $core_id)} | format pattern "/articles/get/{core_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"metadata": $metadata, "fulltext": $fulltext, "citations": $citations, "similar": $similar, "duplicate": $duplicate, "urls": $urls, "faithfulMetadata": $faithful_metadata} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($core_id | is-empty) { error make --unspanned { msg: "path parameter 'coreId' must be non-empty" } }
  let full_url = (build-url $base ({core_id: (encode-path-segment $core_id)} | format pattern "/articles/get/{core_id}/download/pdf") $auth.query)
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the history results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
]: nothing -> record<data: table<datetime: string, metadata: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($core_id | is-empty) { error make --unspanned { msg: "path parameter 'coreId' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({core_id: (encode-path-segment $core_id)} | format pattern "/articles/get/{core_id}/history") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: oneof<nothing, bool> # Whether to retrieve the full article metadata or only the ID. The default value is true. (default: true)
  --fulltext: oneof<nothing, bool> # Whether to retrieve full text of the article. The default value is false (default: false)
  --citations: oneof<nothing, bool> # Whether to retrieve citations found in the article. The default value is false (default: false)
  --similar: oneof<nothing, bool> # Whether to retrieve a list of similar articles. The default value is false. Because the similar articles are calculated on demand, setting this parameter to true might slightly slow down the response time (default: false)
  --duplicate: oneof<nothing, bool> # Whether to retrieve a list of CORE IDs of different versions of the article. The default value is false (default: false)
  --urls: oneof<nothing, bool> # Whether to retrieve a list of URLs from which the article can be downloaded. This can include links to PDFs as well as HTML pages. The default value is false (default: false)
  --faithful-metadata: oneof<nothing, bool> # Whether to retrieve the raw XML metadata of the article. The default value is false (default: false)
  --body: list
]: any -> table<data: list<record>, status: string, totalHits: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/articles/search" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"metadata": $metadata, "fulltext": $fulltext, "citations": $citations, "similar": $similar, "duplicate": $duplicate, "urls": $urls, "faithfulMetadata": $faithful_metadata} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "metadata" $metadata "scalar") (serialize-qp "fulltext" $fulltext "scalar") (serialize-qp "citations" $citations "scalar") (serialize-qp "similar" $similar "scalar") (serialize-qp "duplicate" $duplicate "scalar") (serialize-qp "urls" $urls "scalar") (serialize-qp "faithfulMetadata" $faithful_metadata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/articles/search/{query}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "metadata": $metadata, "fulltext": $fulltext, "citations": $citations, "similar": $similar, "duplicate": $duplicate, "urls": $urls, "faithfulMetadata": $faithful_metadata} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base "/articles/similar" $qp $auth.query)
  let req_body = {"text": $text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"limit": $limit, "metadata": $metadata, "fulltext": $fulltext, "citations": $citations, "similar": $similar, "duplicate": $duplicate, "urls": $urls, "faithfulMetadata": $faithful_metadata} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<data: record<identifiers: list, language: string, publisher: string, rights: string, subjects: list, title: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/journals/get" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<identifiers: list<string>, language: string, publisher: string, rights: string, subjects: list<string>, title: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($issn | is-empty) { error make --unspanned { msg: "path parameter 'issn' must be non-empty" } }
  let full_url = (build-url $base ({issn: (encode-path-segment $issn)} | format pattern "/journals/get/{issn}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<data: record<identifiers: list, language: string, publisher: string, rights: string, subjects: list, title: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/journals/search" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the search results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
]: nothing -> record<data: table<identifiers: list, language: string, publisher: string, rights: string, subjects: list, title: string>, status: string, totalHits: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/journals/search/{query}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stats: oneof<nothing, bool> # Whether to retrieve statistics about the repository. The default value is false (default: false)
  --deposit-history: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --deposit-history-cumulative: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --body: list
]: any -> table<data: record<dataProviderSourceStats: list, history: list, historyCumulative: list, id: int, lastSeen: string, name: string, openDoarId: int, repositoryLocation: record, repositoryStats: record, uri: string, urlHomepage: string, urlOaipmh: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stats" $stats "scalar") (serialize-qp "depositHistory" $deposit_history "scalar") (serialize-qp "depositHistoryCumulative" $deposit_history_cumulative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories/get" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"stats": $stats, "depositHistory": $deposit_history, "depositHistoryCumulative": $deposit_history_cumulative} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stats: oneof<nothing, bool> # Whether to retrieve statistics about the repository. The default value is false (default: false)
  --deposit-history: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --deposit-history-cumulative: oneof<nothing, bool> # Returns deposit history over time (default: false)
]: nothing -> record<data: record<dataProviderSourceStats: list<any>, history: list<any>, historyCumulative: list<any>, id: int, lastSeen: string, name: string, openDoarId: int, repositoryLocation: record<country: string, countryCode: string, id: int, latitude: int, longitude: int, repositoryName: string>, repositoryStats: record<countFulltext: int, countMetadata: int, dateLastProcessed: string>, uri: string, urlHomepage: string, urlOaipmh: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($repository_id | is-empty) { error make --unspanned { msg: "path parameter 'repositoryId' must be non-empty" } }
  let qp = [(serialize-qp "stats" $stats "scalar") (serialize-qp "depositHistory" $deposit_history "scalar") (serialize-qp "depositHistoryCumulative" $deposit_history_cumulative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({repository_id: (encode-path-segment $repository_id)} | format pattern "/repositories/get/{repository_id}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"stats": $stats, "depositHistory": $deposit_history, "depositHistoryCumulative": $deposit_history_cumulative} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --stats: oneof<nothing, bool> # Whether to retrieve statistics about the repository. The default value is false (default: false)
  --deposit-history: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --deposit-history-cumulative: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --body: list
]: any -> record<data: table<dataProviderSourceStats: list, history: list, historyCumulative: list, id: int, lastSeen: string, name: string, openDoarId: int, repositoryLocation: record, repositoryStats: record, uri: string, urlHomepage: string, urlOaipmh: string>, status: string, totalHits: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stats" $stats "scalar") (serialize-qp "depositHistory" $deposit_history "scalar") (serialize-qp "depositHistoryCumulative" $deposit_history_cumulative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/repositories/search" $qp $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: ({"stats": $stats, "depositHistory": $deposit_history, "depositHistoryCumulative": $deposit_history_cumulative} | compact)
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the search results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
  --stats: oneof<nothing, bool> # Whether to retrieve statistics about the repository. The default value is false (default: false)
  --deposit-history: oneof<nothing, bool> # Returns deposit history over time (default: false)
  --deposit-history-cumulative: oneof<nothing, bool> # Returns deposit history over time (default: false)
]: nothing -> record<data: table<dataProviderSourceStats: list, history: list, historyCumulative: list, id: int, lastSeen: string, name: string, openDoarId: int, repositoryLocation: record, repositoryStats: record, uri: string, urlHomepage: string, urlOaipmh: string>, status: string, totalHits: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "stats" $stats "scalar") (serialize-qp "depositHistory" $deposit_history "scalar") (serialize-qp "depositHistoryCumulative" $deposit_history_cumulative "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/repositories/search/{query}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size, "stats": $stats, "depositHistory": $deposit_history, "depositHistoryCumulative": $deposit_history_cumulative} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: list
]: any -> table<data: list<record>, status: string, totalHits: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search" $auth.query)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Which page of the search results should be retrieved. Can be any number betwen 1 and 100, default is 1 (first page). (format: int32, default: 1)
  --page-size: int # The number of results to return per page. Can be any number between 10 and 100, default is 10. (format: int32, default: 10)
]: nothing -> record<data: table<id: string, type: string>, status: string, totalHits: int> {
  let auth = (build-auth $token ($auth_scheme | default "query-apiKey"))
  let base = ($base_url | default $BASE_URL)
  if ($query | is-empty) { error make --unspanned { msg: "path parameter 'query' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({query: (encode-path-segment $query)} | format pattern "/search/{query}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"page": $page, "pageSize": $page_size} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}
