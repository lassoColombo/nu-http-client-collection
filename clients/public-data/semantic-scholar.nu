# Auto-generated client for Academic Graph API v1.0
# Source: https://api.semanticscholar.org/graph/v1/swagger.json
# Auth: --token flag or $env.ACADEMIC_GRAPH_API_TOKEN

const BASE_URL = "https://localhost/graph/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACADEMIC_GRAPH_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost/graph/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "author-batch authors" } } | get name | first)
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

# Get details for multiple authors at once
#
# POST /author/batch
# operationId: post_graph_get_authors
export def "author-batch authors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of Response Schema below for a list of all available fields that can be returned. The <code>authorId</code> field is always returned. If the fields parameter is omitted, only the <code>authorId</code> and <code>name</code> will be returned. <p>Use a period (“.”) for subfields of <code>papers</code>.<br><br> Examples: <ul>     <li><code>fields=name,affiliations,papers</code></li>     <li><code>fields=url,papers.year,papers.authors</code></li> </ul>
  --ids: list
]: any -> record<authorId: string, externalIds: record, url: string, name: string, affiliations: list<string>, homepage: string, paperCount: string, citationCount: string, hIndex: string, papers: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/author/batch" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for authors by name
#
# GET /author/search
# operationId: get_graph_get_author_search
export def "author-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Used for pagination. When returning a list of results, start with the element at this position in the list. (default: 0)
  --limit: int # The maximum number of results to return.<br> Must be <= 1000 (default: 100)
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of the <code>data</code> array in Response Schema below for a list of all available fields that can be returned. The <code>authorId</code> field is always returned. If the fields parameter is omitted, only the <code>authorId</code> and <code>name</code> will be returned. <p>Use a period (“.”) for subfields of <code>papers</code>.<br><br> Examples: <ul>     <li><code>fields=name,affiliations,papers</code></li>     <li><code>fields=url,papers.year,papers.authors</code></li> </ul>
  --qp-query: string # A plain-text search query string. * No special query syntax is supported. * Hyphenated query terms yield no matches (replace it with space to find matches)
]: nothing -> record<total: string, offset: int, next: int, data: table<authorId: string, externalIds: record, url: string, name: string, affiliations: list, homepage: string, paperCount: string, citationCount: string, hIndex: string, papers: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/author/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Details about an author
#
# GET /author/{author_id}
# operationId: get_graph_get_author
export def "author author" [
  author_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of Response Schema below for a list of all available fields that can be returned. The <code>authorId</code> field is always returned. If the fields parameter is omitted, only the <code>authorId</code> and <code>name</code> will be returned. <p>Use a period (“.”) for subfields of <code>papers</code>.<br><br> Examples: <ul>     <li><code>fields=name,affiliations,papers</code></li>     <li><code>fields=url,papers.year,papers.authors</code></li> </ul>
]: nothing -> record<authorId: string, externalIds: record, url: string, name: string, affiliations: list<string>, homepage: string, paperCount: string, citationCount: string, hIndex: string, papers: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/author/($author_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Details about an author's papers
#
# GET /author/{author_id}/papers
# operationId: get_graph_get_author_papers
export def "author-papers papers" [
  author_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --publicationDateOrYear: string # Restricts results to the given range of publication dates or years (inclusive). Accepts the format <code>&lt;startDate&gt;:&lt;endDate&gt;</code> with each date in <code>YYYY-MM-DD</code> format.  <br> <br> Each term is optional, allowing for specific dates, fixed ranges, or open-ended ranges. In addition, prefixes are supported as a shorthand, e.g. <code>2020-06</code> matches all dates in June 2020. <br> <br> Specific dates are not known for all papers, so some records returned with this filter will have a <code>null</code> value for </code>publicationDate</code>. <code>year</code>, however, will always be present. For records where a specific publication date is not known, they will be treated as if published on January 1st of their publication year. <br> <br> Examples: <ul>     <li><code>2019-03-05</code> on March 5th, 2019</li>     <li><code>2019-03</code> during March 2019</li>     <li><code>2019</code> during 2019</li>     <li><code>2016-03-05:2020-06-06</code> as early as March 5th, 2016 or as late as June 6th, 2020</li>     <li><code>1981-08-25:</code> on or after August 25th, 1981</li>     <li><code>:2015-01</code> before or on January 31st, 2015</li>     <li><code>2015:2020</code> between January 1st, 2015 and December 31st, 2020</li> </ul>
  --offset: int # Used for pagination. When returning a list of results, start with the element at this position in the list. (default: 0)
  --limit: int # The maximum number of results to return.<br> Must be <= 1000 (default: 100)
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of the <code>data</code> array in Response Schema below for a list of all available fields that can be returned. The <code>paperId</code> field is always returned. If the fields parameter is omitted, only the <code>paperId</code> and <code>title</code> will be returned. To fetch more references or citations per paper, reduce the number of papers in the batch with <code>limit=</code>. <p>Use a period (“.”) for subfields of <code>citations</code> and <code>references</code>.<br><br> Examples: <ul>     <li><code>fields=title,fieldsOfStudy,references</code></li>     <li><code>fields=abstract,citations.url,citations.venue</code></li> </ul>
]: nothing -> record<offset: int, next: int, data: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list, citations: list, references: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "publicationDateOrYear" $publicationDateOrYear "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/author/($author_id)/papers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Suggest paper query completions
#
# GET /paper/autocomplete
# operationId: get_graph_get_paper_autocomplete
export def "paper-autocomplete autocomplete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Plain-text partial query string. Will be truncated to first 100 characters.
]: nothing -> record<matches: table<id: string, title: string, authorsYear: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paper/autocomplete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details for multiple papers at once
#
# POST /paper/batch
# operationId: post_graph_get_papers
export def "paper-batch papers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of Response Schema below for a list of all available fields that can be returned. The <code>paperId</code> field is always returned. If the fields parameter is omitted, only the <code>paperId</code> and <code>title</code> will be returned. <p>Use a period (“.”) for fields that have version numbers or subfields, such as the <code>embedding</code>, <code>authors</code>, <code>citations</code>, and <code>references</code> fields: <ul>     <li>When requesting <code>authors</code>, the <code>authorId</code> and <code>name</code> subfields are returned by default. To request other subfields, use the format <code>author.url,author.paperCount</code>, etc. See the Response Schema below for available subfields.</li>     <li>When requesting <code>citations</code> and <code>references</code>, the <code>paperId</code> and <code>title</code> subfields are returned by default. To request other subfields, use the format <code>citations.title,citations.abstract</code>, etc. See the Response Schema below for available subfields.</li>     <li>When requesting <code>embedding</code>, the default <a href="https://github.com/allenai/specter">Spector embedding version</a> is v1. Specify <code>embedding.specter_v2</code> to select v2 embeddings.</li> </ul> Examples: <ul>     <li><code>fields=title,url</code></li>     <li><code>fields=title,embedding.specter_v2</code></li>     <li><code>fields=title,authors,citations.title,citations.abstract</code></li> </ul>
  --ids: list
]: any -> record<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list<string>, s2FieldsOfStudy: list<record>, publicationTypes: list<string>, publicationDate: string, journal: record, citationStyles: record, authors: table<authorId: string, externalIds: record, url: string, name: string, affiliations: list, homepage: string, paperCount: string, citationCount: string, hIndex: string, normalizedAffiliations: list>, citations: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list>, references: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list>, embedding: record<model: string, vector: record>, tldr: record<model: string, text: string>, textAvailability: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paper/batch" $qp)
  let body = {ids: $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Paper relevance search
#
# GET /paper/search
# operationId: get_graph_paper_relevance_search
export def "paper-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A plain-text search query string. * No special query syntax is supported. * Hyphenated query terms yield no matches (replace it with space to find matches)  See our <a href="https://medium.com/ai2-blog/building-a-better-search-engine-for-semantic-scholar-ea23a0b661e7">blog post</a> for a description of our search relevance algorithm.  Example: <code>graph/v1/paper/search?query=generative ai</code>
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of the <code>data</code> array in Response Schema below for a list of all available fields that can be returned. The <code>paperId</code> field is always returned. If the fields parameter is omitted, only the <code>paperId</code> and <code>title</code> will be returned. <p>Use a period (“.”) for fields that have version numbers or subfields, such as the <code>embedding</code>, <code>authors</code>, <code>citations</code>, and <code>references</code> fields: <ul>     <li>When requesting <code>authors</code>, the <code>authorId</code> and <code>name</code> subfields are returned by default. To request other subfields, use the format <code>author.url,author.paperCount</code>, etc. See the Response Schema below for available subfields.</li>     <li>When requesting <code>citations</code> and <code>references</code>, the <code>paperId</code> and <code>title</code> subfields are returned by default. To request other subfields, use the format <code>citations.title,citations.abstract</code>, etc. See the Response Schema below for available subfields.</li>     <li>When requesting <code>embedding</code>, the default <a href="https://github.com/allenai/specter">Spector embedding version</a> is v1. Specify <code>embedding.specter_v2</code> to select v2 embeddings.</li> </ul> Examples: <ul>     <li><code>fields=title,url</code></li>     <li><code>fields=title,embedding.specter_v2</code></li>     <li><code>fields=title,authors,citations.title,citations.abstract</code></li> </ul>
  --publicationTypes: string # Restricts results to any of the following paper publication types: <ul>     <li>Review</li>     <li>JournalArticle</li>     <li>CaseReport</li>     <li>ClinicalTrial</li>     <li>Conference</li>     <li>Dataset</li>     <li>Editorial</li>     <li>LettersAndComments</li>     <li>MetaAnalysis</li>     <li>News</li>     <li>Study</li>     <li>Book</li>     <li>BookSection</li> </ul>  Use a comma-separated list to include papers with any of the listed publication types. <br><br> Example: <code>Review,JournalArticle</code> will return papers with publication types Review and/or JournalArticle.
  --openAccessPdf: string # Restricts results to only include papers with a public PDF. This parameter does not accept any values.
  --minCitationCount: string # Restricts results to only include papers with the minimum number of citations. <br> <br> Example: <code>minCitationCount=200</code>
  --publicationDateOrYear: string # Restricts results to the given range of publication dates or years (inclusive). Accepts the format <code>&lt;startDate&gt;:&lt;endDate&gt;</code> with each date in <code>YYYY-MM-DD</code> format.  <br> <br> Each term is optional, allowing for specific dates, fixed ranges, or open-ended ranges. In addition, prefixes are supported as a shorthand, e.g. <code>2020-06</code> matches all dates in June 2020. <br> <br> Specific dates are not known for all papers, so some records returned with this filter will have a <code>null</code> value for </code>publicationDate</code>. <code>year</code>, however, will always be present. For records where a specific publication date is not known, they will be treated as if published on January 1st of their publication year. <br> <br> Examples: <ul>     <li><code>2019-03-05</code> on March 5th, 2019</li>     <li><code>2019-03</code> during March 2019</li>     <li><code>2019</code> during 2019</li>     <li><code>2016-03-05:2020-06-06</code> as early as March 5th, 2016 or as late as June 6th, 2020</li>     <li><code>1981-08-25:</code> on or after August 25th, 1981</li>     <li><code>:2015-01</code> before or on January 31st, 2015</li>     <li><code>2015:2020</code> between January 1st, 2015 and December 31st, 2020</li> </ul>
  --year: string # Restricts results to the given publication year or range of years (inclusive). <br> <br> Examples: <ul>     <li><code>2019</code> in 2019</li>     <li><code>2016-2020</code> as early as 2016 or as late as 2020</li>     <li><code>2010-</code> during or after 2010</li>     <li><code>-2015</code> before or during 2015</li> </ul>
  --venue: string # Restricts results to papers published in the given venues, formatted as a comma-separated list. <br><br> Input could also be an ISO4 abbreviation. Examples include: <ul>     <li>Nature</li>     <li>New England Journal of Medicine</li>     <li>Radiology</li>     <li>N. Engl. J. Med.</li> </ul>  Example: <code>Nature,Radiology</code> will return papers from venues Nature and/or Radiology.
  --fieldsOfStudy: string # Restricts results to papers in the given fields of study, formatted as a comma-separated list: <ul> <li>Computer Science</li> <li>Medicine</li> <li>Chemistry</li> <li>Biology</li> <li>Materials Science</li> <li>Physics</li> <li>Geology</li> <li>Psychology</li> <li>Art</li> <li>History</li> <li>Geography</li> <li>Sociology</li> <li>Business</li> <li>Political Science</li> <li>Economics</li> <li>Philosophy</li> <li>Mathematics</li> <li>Engineering</li> <li>Environmental Science</li> <li>Agricultural and Food Sciences</li> <li>Education</li> <li>Law</li> <li>Linguistics</li> </ul>  Example: <code>Physics,Mathematics</code> will return papers with either Physics or Mathematics in their list of fields-of-study.
  --offset: int # Used for pagination. When returning a list of results, start with the element at this position in the list. (default: 0)
  --limit: int # The maximum number of results to return.<br> Must be <= 100 (default: 100)
]: nothing -> record<total: string, offset: int, next: int, data: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list, citations: list, references: list, embedding: record, tldr: record, textAvailability: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "publicationTypes" $publicationTypes "scalar") (serialize-qp "openAccessPdf" $openAccessPdf "scalar") (serialize-qp "minCitationCount" $minCitationCount "scalar") (serialize-qp "publicationDateOrYear" $publicationDateOrYear "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "venue" $venue "scalar") (serialize-qp "fieldsOfStudy" $fieldsOfStudy "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paper/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Paper bulk search
#
# GET /paper/search/bulk
# operationId: get_graph_paper_bulk_search
export def "paper-search-bulk search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Text query that will be matched against the paper's title and abstract. All terms are stemmed in English. By default all terms in the query must be present in the paper.  The match query supports the following syntax: <ul> <li><code>+</code> for AND operation</li> <li><code>|</code> for OR operation</li> <li><code>-</code> negates a term </li> <li><code>"</code> collects terms into a phrase</li> <li><code>*</code> can be used to match a prefix</li>     <li><code>(</code> and <code>)</code> for precedence</li> <li><code>~N</code> after a word matches within the edit distance of N (Defaults to 2 if N is omitted)</li> <li><code>~N</code> after a phrase matches with the phrase terms separated up to N terms apart (Defaults to 2 if N is omitted)</li> </ul>  Examples: <ul>     <li><code>fish ladder</code> matches papers that contain "fish" and "ladder"</li>     <li><code>fish -ladder</code> matches papers that contain "fish" but not "ladder"</li>     <li><code>fish | ladder</code> matches papers that contain "fish" or "ladder"</li>     <li><code>"fish ladder"</code> matches papers that contain the phrase "fish ladder"</li>     <li><code>(fish ladder) | outflow</code> matches papers that contain "fish" and "ladder" OR "outflow"</li>     <li><code>fish~</code> matches papers that contain "fish", "fist", "fihs", etc. </li>     <li><code>"fish ladder"~3</code> mathces papers that contain the phrase "fish ladder" or "fish is on a ladder"</li> </ul>
  --qp-token: string # Used for pagination. This string token is provided when the original query returns, and is used to fetch the next batch of papers. Each call will return a new token.
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of the <code>data</code> array in Response Schema below for a list of all available fields that can be returned.<br><br> The <code>paperId</code> field is always returned. If the fields parameter is omitted, only the <code>paperId</code> and <code>title</code> will be returned.<br><br> Examples: <code>https://api.semanticscholar.org/graph/v1/paper/search/bulk?query=covid&fields=venue,s2FieldsOfStudy</code>
  --qp-sort: string # Provides the option to sort the results by the following fields: <ul>     <li><code>paperId</code></li>     <li><code>publicationDate</code></li>     <li><code>citationCount</code></li> </ul> Uses the format <code>field:order</code>. Ties are broken by <code>paperId</code>. The default field is <code>paperId</code> and the default order is asc. Records for which the sort value are not defined will appear at the end of sort, regardless of asc/desc order. <br> <br> Examples: <ul>     <li><code>publicationDate:asc</code> - return oldest papers first.</li>     <li><code>citationCount:desc</code> - return most highly-cited papers first.</li>     <li><code>paperId</code> - return papers in ID order, low-to-high.</li> </ul> <br> Please be aware that if the relevant data changes while paging through results, records can be returned in an unexpected way. The default <code>paperId</code> sort avoids this edge case.
  --publicationTypes: string # Restricts results to any of the following paper publication types: <ul>     <li>Review</li>     <li>JournalArticle</li>     <li>CaseReport</li>     <li>ClinicalTrial</li>     <li>Conference</li>     <li>Dataset</li>     <li>Editorial</li>     <li>LettersAndComments</li>     <li>MetaAnalysis</li>     <li>News</li>     <li>Study</li>     <li>Book</li>     <li>BookSection</li> </ul>  Use a comma-separated list to include papers with any of the listed publication types. <br><br> Example: <code>Review,JournalArticle</code> will return papers with publication types Review and/or JournalArticle.
  --openAccessPdf: string # Restricts results to only include papers with a public PDF. This parameter does not accept any values.
  --minCitationCount: string # Restricts results to only include papers with the minimum number of citations. <br> <br> Example: <code>minCitationCount=200</code>
  --publicationDateOrYear: string # Restricts results to the given range of publication dates or years (inclusive). Accepts the format <code>&lt;startDate&gt;:&lt;endDate&gt;</code> with each date in <code>YYYY-MM-DD</code> format.  <br> <br> Each term is optional, allowing for specific dates, fixed ranges, or open-ended ranges. In addition, prefixes are supported as a shorthand, e.g. <code>2020-06</code> matches all dates in June 2020. <br> <br> Specific dates are not known for all papers, so some records returned with this filter will have a <code>null</code> value for </code>publicationDate</code>. <code>year</code>, however, will always be present. For records where a specific publication date is not known, they will be treated as if published on January 1st of their publication year. <br> <br> Examples: <ul>     <li><code>2019-03-05</code> on March 5th, 2019</li>     <li><code>2019-03</code> during March 2019</li>     <li><code>2019</code> during 2019</li>     <li><code>2016-03-05:2020-06-06</code> as early as March 5th, 2016 or as late as June 6th, 2020</li>     <li><code>1981-08-25:</code> on or after August 25th, 1981</li>     <li><code>:2015-01</code> before or on January 31st, 2015</li>     <li><code>2015:2020</code> between January 1st, 2015 and December 31st, 2020</li> </ul>
  --year: string # Restricts results to the given publication year or range of years (inclusive). <br> <br> Examples: <ul>     <li><code>2019</code> in 2019</li>     <li><code>2016-2020</code> as early as 2016 or as late as 2020</li>     <li><code>2010-</code> during or after 2010</li>     <li><code>-2015</code> before or during 2015</li> </ul>
  --venue: string # Restricts results to papers published in the given venues, formatted as a comma-separated list. <br><br> Input could also be an ISO4 abbreviation. Examples include: <ul>     <li>Nature</li>     <li>New England Journal of Medicine</li>     <li>Radiology</li>     <li>N. Engl. J. Med.</li> </ul>  Example: <code>Nature,Radiology</code> will return papers from venues Nature and/or Radiology.
  --fieldsOfStudy: string # Restricts results to papers in the given fields of study, formatted as a comma-separated list: <ul> <li>Computer Science</li> <li>Medicine</li> <li>Chemistry</li> <li>Biology</li> <li>Materials Science</li> <li>Physics</li> <li>Geology</li> <li>Psychology</li> <li>Art</li> <li>History</li> <li>Geography</li> <li>Sociology</li> <li>Business</li> <li>Political Science</li> <li>Economics</li> <li>Philosophy</li> <li>Mathematics</li> <li>Engineering</li> <li>Environmental Science</li> <li>Agricultural and Food Sciences</li> <li>Education</li> <li>Law</li> <li>Linguistics</li> </ul>  Example: <code>Physics,Mathematics</code> will return papers with either Physics or Mathematics in their list of fields-of-study.
]: nothing -> record<total: string, token: string, data: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list, citations: list, references: list, embedding: record, tldr: record, textAvailability: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "token" $qp_token "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "publicationTypes" $publicationTypes "scalar") (serialize-qp "openAccessPdf" $openAccessPdf "scalar") (serialize-qp "minCitationCount" $minCitationCount "scalar") (serialize-qp "publicationDateOrYear" $publicationDateOrYear "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "venue" $venue "scalar") (serialize-qp "fieldsOfStudy" $fieldsOfStudy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paper/search/bulk" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Paper title search
#
# GET /paper/search/match
# operationId: get_graph_paper_title_search
export def "paper-search-match search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # A plain-text search query string. * No special query syntax is supported.  See our <a href="https://medium.com/ai2-blog/building-a-better-search-engine-for-semantic-scholar-ea23a0b661e7">blog post</a> for a description of our search relevance algorithm.
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of the <code>data</code> array in Response Schema below for a list of all available fields that can be returned. The <code>paperId</code> field is always returned. If the fields parameter is omitted, only the <code>paperId</code> and <code>title</code> will be returned. <p>Use a period (“.”) for fields that have version numbers or subfields, such as the <code>embedding</code>, <code>authors</code>, <code>citations</code>, and <code>references</code> fields: <ul>     <li>When requesting <code>authors</code>, the <code>authorId</code> and <code>name</code> subfields are returned by default. To request other subfields, use the format <code>author.url,author.paperCount</code>, etc. See the Response Schema below for available subfields.</li>     <li>When requesting <code>citations</code> and <code>references</code>, the <code>paperId</code> and <code>title</code> subfields are returned by default. To request other subfields, use the format <code>citations.title,citations.abstract</code>, etc. See the Response Schema below for available subfields.</li>     <li>When requesting <code>embedding</code>, the default <a href="https://github.com/allenai/specter">Spector embedding version</a> is v1. Specify <code>embedding.specter_v2</code> to select v2 embeddings.</li> </ul> Examples: <ul>     <li><code>fields=title,url</code></li>     <li><code>fields=title,embedding.specter_v2</code></li>     <li><code>fields=title,authors,citations.title,citations.abstract</code></li> </ul>
  --publicationTypes: string # Restricts results to any of the following paper publication types: <ul>     <li>Review</li>     <li>JournalArticle</li>     <li>CaseReport</li>     <li>ClinicalTrial</li>     <li>Conference</li>     <li>Dataset</li>     <li>Editorial</li>     <li>LettersAndComments</li>     <li>MetaAnalysis</li>     <li>News</li>     <li>Study</li>     <li>Book</li>     <li>BookSection</li> </ul>  Use a comma-separated list to include papers with any of the listed publication types. <br><br> Example: <code>Review,JournalArticle</code> will return papers with publication types Review and/or JournalArticle.
  --openAccessPdf: string # Restricts results to only include papers with a public PDF. This parameter does not accept any values.
  --minCitationCount: string # Restricts results to only include papers with the minimum number of citations. <br> <br> Example: <code>minCitationCount=200</code>
  --publicationDateOrYear: string # Restricts results to the given range of publication dates or years (inclusive). Accepts the format <code>&lt;startDate&gt;:&lt;endDate&gt;</code> with each date in <code>YYYY-MM-DD</code> format.  <br> <br> Each term is optional, allowing for specific dates, fixed ranges, or open-ended ranges. In addition, prefixes are supported as a shorthand, e.g. <code>2020-06</code> matches all dates in June 2020. <br> <br> Specific dates are not known for all papers, so some records returned with this filter will have a <code>null</code> value for </code>publicationDate</code>. <code>year</code>, however, will always be present. For records where a specific publication date is not known, they will be treated as if published on January 1st of their publication year. <br> <br> Examples: <ul>     <li><code>2019-03-05</code> on March 5th, 2019</li>     <li><code>2019-03</code> during March 2019</li>     <li><code>2019</code> during 2019</li>     <li><code>2016-03-05:2020-06-06</code> as early as March 5th, 2016 or as late as June 6th, 2020</li>     <li><code>1981-08-25:</code> on or after August 25th, 1981</li>     <li><code>:2015-01</code> before or on January 31st, 2015</li>     <li><code>2015:2020</code> between January 1st, 2015 and December 31st, 2020</li> </ul>
  --year: string # Restricts results to the given publication year or range of years (inclusive). <br> <br> Examples: <ul>     <li><code>2019</code> in 2019</li>     <li><code>2016-2020</code> as early as 2016 or as late as 2020</li>     <li><code>2010-</code> during or after 2010</li>     <li><code>-2015</code> before or during 2015</li> </ul>
  --venue: string # Restricts results to papers published in the given venues, formatted as a comma-separated list. <br><br> Input could also be an ISO4 abbreviation. Examples include: <ul>     <li>Nature</li>     <li>New England Journal of Medicine</li>     <li>Radiology</li>     <li>N. Engl. J. Med.</li> </ul>  Example: <code>Nature,Radiology</code> will return papers from venues Nature and/or Radiology.
  --fieldsOfStudy: string # Restricts results to papers in the given fields of study, formatted as a comma-separated list: <ul> <li>Computer Science</li> <li>Medicine</li> <li>Chemistry</li> <li>Biology</li> <li>Materials Science</li> <li>Physics</li> <li>Geology</li> <li>Psychology</li> <li>Art</li> <li>History</li> <li>Geography</li> <li>Sociology</li> <li>Business</li> <li>Political Science</li> <li>Economics</li> <li>Philosophy</li> <li>Mathematics</li> <li>Engineering</li> <li>Environmental Science</li> <li>Agricultural and Food Sciences</li> <li>Education</li> <li>Law</li> <li>Linguistics</li> </ul>  Example: <code>Physics,Mathematics</code> will return papers with either Physics or Mathematics in their list of fields-of-study.
]: nothing -> record<data: table<matchScore: int, paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list, citations: list, references: list, embedding: record, tldr: record, textAvailability: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "publicationTypes" $publicationTypes "scalar") (serialize-qp "openAccessPdf" $openAccessPdf "scalar") (serialize-qp "minCitationCount" $minCitationCount "scalar") (serialize-qp "publicationDateOrYear" $publicationDateOrYear "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "venue" $venue "scalar") (serialize-qp "fieldsOfStudy" $fieldsOfStudy "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/paper/search/match" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Details about a paper
#
# GET /paper/{paper_id}
# operationId: get_graph_get_paper
export def "paper paper" [
  paper_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of Response Schema below for a list of all available fields that can be returned. The <code>paperId</code> field is always returned. If the fields parameter is omitted, only the <code>paperId</code> and <code>title</code> will be returned. <p>Use a period (“.”) for fields that have version numbers or subfields, such as the <code>embedding</code>, <code>authors</code>, <code>citations</code>, and <code>references</code> fields: <ul>     <li>When requesting <code>authors</code>, the <code>authorId</code> and <code>name</code> subfields are returned by default. To request other subfields, use the format <code>author.url,author.paperCount</code>, etc. See the Response Schema below for available subfields.</li>     <li>When requesting <code>citations</code> and <code>references</code>, the <code>paperId</code> and <code>title</code> subfields are returned by default. To request other subfields, use the format <code>citations.title,citations.abstract</code>, etc. See the Response Schema below for available subfields.</li>     <li>When requesting <code>embedding</code>, the default <a href="https://github.com/allenai/specter">Spector embedding version</a> is v1. Specify <code>embedding.specter_v2</code> to select v2 embeddings.</li> </ul> Examples: <ul>     <li><code>fields=title,url</code></li>     <li><code>fields=title,embedding.specter_v2</code></li>     <li><code>fields=title,authors,citations.title,citations.abstract</code></li> </ul>
]: nothing -> record<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list<string>, s2FieldsOfStudy: list<record>, publicationTypes: list<string>, publicationDate: string, journal: record, citationStyles: record, authors: table<authorId: string, externalIds: record, url: string, name: string, affiliations: list, homepage: string, paperCount: string, citationCount: string, hIndex: string, normalizedAffiliations: list>, citations: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list>, references: table<paperId: string, corpusId: int, externalIds: record, url: string, title: string, abstract: string, venue: string, publicationVenue: record, year: int, referenceCount: int, citationCount: int, influentialCitationCount: int, isOpenAccess: bool, openAccessPdf: record, fieldsOfStudy: list, s2FieldsOfStudy: list, publicationTypes: list, publicationDate: string, journal: record, citationStyles: record, authors: list>, embedding: record<model: string, vector: record>, tldr: record<model: string, text: string>, textAvailability: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/paper/($paper_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Details about a paper's authors
#
# GET /paper/{paper_id}/authors
# operationId: get_graph_get_paper_authors
export def "paper-authors authors" [
  paper_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Used for pagination. When returning a list of results, start with the element at this position in the list. (default: 0)
  --limit: int # The maximum number of results to return.<br> Must be <= 1000 (default: 100)
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of the <code>data</code> array in Response Schema below for a list of all available fields that can be returned. The <code>authorId</code> field is always returned. If the fields parameter is omitted, only the <code>authorId</code> and <code>name</code> will be returned. <p>Use a period (“.”) for subfields of <code>papers</code>.<br><br> Examples: <ul>     <li><code>fields=name,affiliations,papers</code></li>     <li><code>fields=url,papers.year,papers.authors</code></li> </ul>
]: nothing -> record<offset: int, next: int, data: table<authorId: string, externalIds: record, url: string, name: string, affiliations: list, homepage: string, paperCount: string, citationCount: string, hIndex: string, normalizedAffiliations: list, papers: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/paper/($paper_id)/authors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Details about a paper's citations
#
# GET /paper/{paper_id}/citations
# operationId: get_graph_get_paper_citations
export def "paper-citations citations" [
  paper_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --publicationDateOrYear: string # Restricts results to the given range of publication dates or years (inclusive). Accepts the format <code>&lt;startDate&gt;:&lt;endDate&gt;</code> with each date in <code>YYYY-MM-DD</code> format.  <br> <br> Each term is optional, allowing for specific dates, fixed ranges, or open-ended ranges. In addition, prefixes are supported as a shorthand, e.g. <code>2020-06</code> matches all dates in June 2020. <br> <br> Specific dates are not known for all papers, so some records returned with this filter will have a <code>null</code> value for </code>publicationDate</code>. <code>year</code>, however, will always be present. For records where a specific publication date is not known, they will be treated as if published on January 1st of their publication year. <br> <br> Examples: <ul>     <li><code>2019-03-05</code> on March 5th, 2019</li>     <li><code>2019-03</code> during March 2019</li>     <li><code>2019</code> during 2019</li>     <li><code>2016-03-05:2020-06-06</code> as early as March 5th, 2016 or as late as June 6th, 2020</li>     <li><code>1981-08-25:</code> on or after August 25th, 1981</li>     <li><code>:2015-01</code> before or on January 31st, 2015</li>     <li><code>2015:2020</code> between January 1st, 2015 and December 31st, 2020</li> </ul>
  --offset: int # Used for pagination. When returning a list of results, start with the element at this position in the list. (default: 0)
  --limit: int # The maximum number of results to return.<br> Must be <= 1000 (default: 100)
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of the <code>data</code> array in Response Schema below for a list of all available fields that can be returned. If the fields parameter is omitted, only the <code>paperId</code> and <code>title</code> will be returned. <p>Request fields nested within <code>citedPaper</code> the same way as fields like <code>contexts</code>.<br><br> Examples: <ul>     <li><code>fields=contexts,isInfluential</code></li>     <li><code>fields=contexts,title,authors</code></li> </ul>
]: nothing -> record<offset: int, next: int, data: table<contexts: list, intents: list, contextsWithIntent: list, isInfluential: bool, citingPaper: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "publicationDateOrYear" $publicationDateOrYear "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/paper/($paper_id)/citations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Details about a paper's references
#
# GET /paper/{paper_id}/references
# operationId: get_graph_get_paper_references
export def "paper-references references" [
  paper_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Used for pagination. When returning a list of results, start with the element at this position in the list. (default: 0)
  --limit: int # The maximum number of results to return.<br> Must be <= 1000 (default: 100)
  --qp-fields: string # A comma-separated list of the fields to be returned. See the contents of the <code>data</code> array in Response Schema below for a list of all available fields that can be returned. If the fields parameter is omitted, only the <code>paperId</code> and <code>title</code> will be returned. <p>Request fields nested within <code>citedPaper</code> the same way as fields like <code>contexts</code>.<br><br> Examples: <ul>     <li><code>fields=contexts,isInfluential</code></li>     <li><code>fields=contexts,title,authors</code></li> </ul>
]: nothing -> record<offset: int, next: int, data: table<contexts: list, intents: list, contextsWithIntent: list, isInfluential: bool, citedPaper: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "fields" $qp_fields "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/paper/($paper_id)/references" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Text snippet search
#
# GET /snippet/search
# operationId: get_snippet_search
export def "snippet-search search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # A comma-separated list of the fields to be returned with each snippet element.  Paper info and the score are currently always returned. What you can specify using this <code>fields</code> param is which fields under the 'snippet' section (see the response schema) will be returned.  Examples: <ul>     <li><code>fields=snippet.text</code>: you'll get just the <code>text</code> field in the snippet section</li>     <li><code>fields=snippet.text,snippet.snippetKind</code>: you'll get just the <code>text</code> and <code>snippetKind</code> fields in the snippet section</li>     <li><code>fields=snippet.annotations.sentences</code>: you'll get just the sentence annotations in the snippet section</li> </ul>  In general, you can use periods to identify nested fields (as in the examples above).  Not all fields in the response schema can be identified using this <code>fields</code> param though. E.g. you can't pick what you get within <code>snippet.snippetOffset</code> - you can either get the snippet offset with all the possible snippet offset fields, or you can not get it at all. You also can't provide <code>paper</code> or <code>score</code> or anything under <code>paper</code>, since those are always provided.  If you attempt to identify a field that's not supported, you'll get an error with the relevant field name. E.g.  <code>Unrecognized or unsupported fields: [paper]</code>  If you don't specify the fields param, you'll get a default set of fields in the snippet section. These are the default fields: - <code>snippet.text</code> - <code>snippet.snippetKind</code> - <code>snippet.section</code> - <code>snippet.snippetOffset</code> (including nested <code>start</code> and <code>end</code>) - <code>snippet.annotations.refMentions</code> (including nested <code>start</code>, <code>end</code>, and <code>matchedPaperCorpusId</code> for each element) - <code>snippet.annotations.sentences</code> (including nested <code>start</code> and <code>end</code> for each element)
  --paperIds: string # Restricts results to snippets from specific papers. To specify papers, provide a comma-separated list of their IDs. You can provide up to approximately 100 IDs.  The following types of IDs are supported: <ul>     <li><code>&lt;sha&gt;</code> - a Semantic Scholar ID, e.g. <code>649def34f8be52c8b66281af98ae884c09aef38b</code></li>     <li><code>CorpusId:&lt;id&gt;</code> - a Semantic Scholar numerical ID, e.g. <code>CorpusId:215416146</code></li>     <li><code>DOI:&lt;doi&gt;</code> - a <a href="http://doi.org">Digital Object Identifier</a>,         e.g. <code>DOI:10.18653/v1/N18-3011</code></li>     <li><code>ARXIV:&lt;id&gt;</code> - <a href="https://arxiv.org/">arXiv.rg</a>, e.g. <code>ARXIV:2106.15928</code></li>     <li><code>MAG:&lt;id&gt;</code> - Microsoft Academic Graph, e.g. <code>MAG:112218234</code></li>     <li><code>ACL:&lt;id&gt;</code> - Association for Computational Linguistics, e.g. <code>ACL:W12-3903</code></li>     <li><code>PMID:&lt;id&gt;</code> - PubMed/Medline, e.g. <code>PMID:19872477</code></li>     <li><code>PMCID:&lt;id&gt;</code> - PubMed Central, e.g. <code>PMCID:2323736</code></li>     <li><code>URL:&lt;url&gt;</code> - URL from one of the sites listed below, e.g. <code>URL:https://arxiv.org/abs/2106.15928v1</code></li> </ul>  URLs are recognized from the following sites: <ul>     <li><a href="https://www.semanticscholar.org/">semanticscholar.org</a></li>     <li><a href="https://arxiv.org/">arxiv.org</a></li>     <li><a href="https://www.aclweb.org">aclweb.org</a></li>     <li><a href="https://www.acm.org/">acm.org</a></li>     <li><a href="https://www.biorxiv.org/">biorxiv.org</a></li> </ul>
  --authors: string # Restricts results to papers with authors matching the given names, formatted as a comma-separated list (<code>...?authors=name1,name2,...</code>). The search criteria are 'fuzzy', so matches that are <em>close</em> will also return results. <br><br>  Example: <code>galileo,kepler</code> will return papers that include <em>both</em> an author similar to "galileo" <em>and</em> an author similar to "kepler" as co-authors. This query will also match fuzzy variations like 'keppler' and 'Kepler' (default max 'edit distance' is 2).  <strong>Important:</strong> Multiple author names are combined with AND logic, meaning results must include <em>all</em> specified authors. Adding more authors will narrow your results, not expand them. To search for papers by <em>any</em> of several authors (OR logic), perform separate searches for each author name. The maximum number of author filters is by default <code>10</code> and will return an HTTP code 400 (Bad Request) if more than 10 are supplied.
  --minCitationCount: string # Restricts results to only include papers with the minimum number of citations. <br> <br> Example: <code>minCitationCount=200</code>
  --insertedBefore: string # Restricts results to snippets from papers inserted into the index before the provided date (excludes things inserted on the provided date).  Acceptable formats: YYYY-MM-DD, YYYY-MM, YYYY
  --publicationDateOrYear: string # Restricts results to the given range of publication dates or years (inclusive). Accepts the format <code>&lt;startDate&gt;:&lt;endDate&gt;</code> with each date in <code>YYYY-MM-DD</code> format.  <br> <br> Each term is optional, allowing for specific dates, fixed ranges, or open-ended ranges. In addition, prefixes are supported as a shorthand, e.g. <code>2020-06</code> matches all dates in June 2020. <br> <br> Specific dates are not known for all papers, so some records returned with this filter will have a <code>null</code> value for </code>publicationDate</code>. <code>year</code>, however, will always be present. For records where a specific publication date is not known, they will be treated as if published on January 1st of their publication year. <br> <br> Examples: <ul>     <li><code>2019-03-05</code> on March 5th, 2019</li>     <li><code>2019-03</code> during March 2019</li>     <li><code>2019</code> during 2019</li>     <li><code>2016-03-05:2020-06-06</code> as early as March 5th, 2016 or as late as June 6th, 2020</li>     <li><code>1981-08-25:</code> on or after August 25th, 1981</li>     <li><code>:2015-01</code> before or on January 31st, 2015</li>     <li><code>2015:2020</code> between January 1st, 2015 and December 31st, 2020</li> </ul>
  --year: string # Restricts results to the given publication year or range of years (inclusive). <br> <br> Examples: <ul>     <li><code>2019</code> in 2019</li>     <li><code>2016-2020</code> as early as 2016 or as late as 2020</li>     <li><code>2010-</code> during or after 2010</li>     <li><code>-2015</code> before or during 2015</li> </ul>
  --venue: string # Restricts results to papers published in the given venues, formatted as a comma-separated list. <br><br> Input could also be an ISO4 abbreviation. Examples include: <ul>     <li>Nature</li>     <li>New England Journal of Medicine</li>     <li>Radiology</li>     <li>N. Engl. J. Med.</li> </ul>  Example: <code>Nature,Radiology</code> will return papers from venues Nature and/or Radiology.
  --fieldsOfStudy: string # Restricts results to papers in the given fields of study, formatted as a comma-separated list: <ul> <li>Computer Science</li> <li>Medicine</li> <li>Chemistry</li> <li>Biology</li> <li>Materials Science</li> <li>Physics</li> <li>Geology</li> <li>Psychology</li> <li>Art</li> <li>History</li> <li>Geography</li> <li>Sociology</li> <li>Business</li> <li>Political Science</li> <li>Economics</li> <li>Philosophy</li> <li>Mathematics</li> <li>Engineering</li> <li>Environmental Science</li> <li>Agricultural and Food Sciences</li> <li>Education</li> <li>Law</li> <li>Linguistics</li> </ul>  Example: <code>Physics,Mathematics</code> will return papers with either Physics or Mathematics in their list of fields-of-study.
  --qp-query: string # A plain-text search query string. * No special query syntax is supported.
  --limit: int # The maximum number of results to return.<br> Must be <= 1000 (default: 10)
]: nothing -> record<data: table<snippet: record, score: float, paper: record>, retrievalVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "paperIds" $paperIds "scalar") (serialize-qp "authors" $authors "scalar") (serialize-qp "minCitationCount" $minCitationCount "scalar") (serialize-qp "insertedBefore" $insertedBefore "scalar") (serialize-qp "publicationDateOrYear" $publicationDateOrYear "scalar") (serialize-qp "year" $year "scalar") (serialize-qp "venue" $venue "scalar") (serialize-qp "fieldsOfStudy" $fieldsOfStudy "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/snippet/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
