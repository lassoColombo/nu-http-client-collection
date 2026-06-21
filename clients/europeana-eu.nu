# Auto-generated client for Europeana Search & Record API vversion unknown
# Source: https://api.apis.guru/v2/specs/europeana.eu/version unknown/swagger.json
# Auth: --token flag or $env.EUROPEANA_SEARCH_RECORD_API_TOKEN

const BASE_URL = "https://api.europeana.eu"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EUROPEANA_SEARCH_RECORD_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.europeana.eu"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/rss+xml" "application/xhtml+xml" "application/xml"] }
def accept-completer-1 [] { ["application/json;charset=UTF-8" "application/ld+json;charset=UTF-8"] }
def accept-completer-2 [] { ["application/turtle" "application/x-turtle" "text/turtle"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "record-opensearch-rss open-list" } } | get name | first)
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

# basic search function following the OpenSearch specification
#
# GET /record/v2/opensearch.rss
# operationId: openSearch
export def "record-opensearch-rss open-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --count: int # count (format: int32, default: 12)
  --search-terms: string # searchTerms
  --start-index: int # startIndex (format: int32, default: 1)
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "searchTerms" $search_terms "scalar") (serialize-qp "startIndex" $start_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/record/v2/opensearch.rss" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "searchTerms": $search_terms, "startIndex": $start_index} | compact), body: null}
}

# search for records
#
# GET /record/v2/search.json
# operationId: searchRecords
export def "record-search-json list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --boost: string # boost
  --callback: string # callback
  --colourpalette: list<string> # colourpalette
  --cursor: string # cursor
  --facet: list<string> # facet
  --hit-fl: string # hit.fl
  --hit-selectors: string # hit.selectors
  --landingpage: oneof<nothing, bool> # landingpage
  --lang: string # lang
  --media: oneof<nothing, bool> # media
  --profile: string # profile (default: standard)
  --q-source: string # q.source
  --q-target: string # q.target
  --qf: list<string> # qf
  --query: string # query
  --reusability: list<string> # reusability
  --rows: int # rows (format: int32, default: 12)
  --qp-sort: string # sort
  --start: int # start (format: int32, default: 1)
  --text-fulltext: oneof<nothing, bool> # text_fulltext
  --theme: string # theme
  --thumbnail: oneof<nothing, bool> # thumbnail
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "boost" $boost "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "colourpalette" $colourpalette "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "facet" $facet "multi") (serialize-qp "hit.fl" $hit_fl "scalar") (serialize-qp "hit.selectors" $hit_selectors "scalar") (serialize-qp "landingpage" $landingpage "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "media" $media "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "q.source" $q_source "scalar") (serialize-qp "q.target" $q_target "scalar") (serialize-qp "qf" $qf "multi") (serialize-qp "query" $query "scalar") (serialize-qp "reusability" $reusability "multi") (serialize-qp "rows" $rows "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "text_fulltext" $text_fulltext "scalar") (serialize-qp "theme" $theme "scalar") (serialize-qp "thumbnail" $thumbnail "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/record/v2/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"boost": $boost, "callback": $callback, "colourpalette": $colourpalette, "cursor": $cursor, "facet": $facet, "hit.fl": $hit_fl, "hit.selectors": $hit_selectors, "landingpage": $landingpage, "lang": $lang, "media": $media, "profile": $profile, "q.source": $q_source, "q.target": $q_target, "qf": $qf, "query": $query, "reusability": $reusability, "rows": $rows, "sort": $qp_sort, "start": $start, "text_fulltext": $text_fulltext, "theme": $theme, "thumbnail": $thumbnail, "wskey": $wskey} | compact), body: null}
}

# search for records post
#
# POST /record/v2/search.json
# operationId: searchRecordsPost
# --hit shape: {fl?: string, selectors?: string}
export def "record-search-json create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --wskey: string # wskey
  --boost: string
  --callback: string
  --colour-palette: list<string>
  --cursor: string
  --facet: list<string>
  --hit: record # shape: {fl?: string, selectors?: string}
  --landing-page: oneof<nothing, bool>
  --media: oneof<nothing, bool>
  --profile: list<string>
  --qf: list<string>
  query: string
  --reusability: list<string>
  --rows: int # format: int32
  --body-sort: list<string>
  --start: int # format: int32
  --text-fulltext: oneof<nothing, bool>
  --theme: string
  --thumbnail: oneof<nothing, bool>
]: any -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/record/v2/search.json" $qp)
  let req_body = {"boost": $boost, "callback": $callback, "colourPalette": $colour_palette, "cursor": $cursor, "facet": $facet, "hit": $hit, "landingPage": $landing_page, "media": $media, "profile": $profile, "qf": $qf, "query": $query, "reusability": $reusability, "rows": $rows, "sort": $body_sort, "start": $start, "textFulltext": $text_fulltext, "theme": $theme, "thumbnail": $thumbnail} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"wskey": $wskey} | compact), body: $req_body}
}

# translate a term to different languages
#
# GET /record/v2/translateQuery.json
# operationId: translateQueryUsingGET
export def "record-translate-query-json get-using" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # callback
  --language-codes: list<string> # languageCodes
  --profile: string # profile
  --term: string # term
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "languageCodes" $language_codes "multi") (serialize-qp "profile" $profile "scalar") (serialize-qp "term" $term "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/record/v2/translateQuery.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"callback": $callback, "languageCodes": $language_codes, "profile": $profile, "term": $term, "wskey": $wskey} | compact), body: null}
}

# get a single record in JSON format
#
# GET /record/v2/{collectionId}/{recordId}.json
# operationId: getSingleRecordJson
export def "record get-single-json" [
  collection_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # callback
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionId' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), record_id: (encode-path-segment $record_id)} | format pattern "/record/v2/{collection_id}/{record_id}.json") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"callback": $callback, "lang": $lang, "profile": $profile, "wskey": $wskey} | compact), body: null}
}

# get single record in JSON LD format
#
# GET /record/v2/{collectionId}/{recordId}.jsonld
# operationId: getSingleRecordJsonLD
export def "record get-single-json-ld" [
  collection_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --callback: string # callback
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionId' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), record_id: (encode-path-segment $record_id)} | format pattern "/record/v2/{collection_id}/{record_id}.jsonld") $qp)
  let accept_val = ($accept | default "application/json;charset=UTF-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"callback": $callback, "lang": $lang, "profile": $profile, "wskey": $wskey} | compact), body: null}
}

# get single record in RDF format)
#
# GET /record/v2/{collectionId}/{recordId}.rdf
# operationId: getSingleRecordRDF
export def "record get-single-rdf" [
  collection_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionId' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), record_id: (encode-path-segment $record_id)} | format pattern "/record/v2/{collection_id}/{record_id}.rdf") $qp)
  let accept_val = "application/rdf+xml;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "profile": $profile, "wskey": $wskey} | compact), body: null}
}

# get single record in Schema.org JSON LD format
#
# GET /record/v2/{collectionId}/{recordId}.schema.jsonld
# operationId: getSingleRecordSchemaOrg
export def "record get-single-schema-org" [
  collection_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --callback: string # callback
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionId' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), record_id: (encode-path-segment $record_id)} | format pattern "/record/v2/{collection_id}/{record_id}.schema.jsonld") $qp)
  let accept_val = ($accept | default "application/json;charset=UTF-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"callback": $callback, "lang": $lang, "profile": $profile, "wskey": $wskey} | compact), body: null}
}

# get single record in turtle format)
#
# GET /record/v2/{collectionId}/{recordId}.ttl
# operationId: getSingleRecordTurtle
export def "record get-single-turtle" [
  collection_id: string
  record_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($collection_id | is-empty) { error make --unspanned { msg: "path parameter 'collectionId' must be non-empty" } }
  if ($record_id | is-empty) { error make --unspanned { msg: "path parameter 'recordId' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), record_id: (encode-path-segment $record_id)} | format pattern "/record/v2/{collection_id}/{record_id}.ttl") $qp)
  let accept_val = ($accept | default "application/x-turtle")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "profile": $profile, "wskey": $wskey} | compact), body: null}
}
