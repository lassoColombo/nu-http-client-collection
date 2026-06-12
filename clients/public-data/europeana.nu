# Auto-generated client for Europeana Search & Record API vversion unknown
# Source: https://api.apis.guru/v2/specs/europeana.eu/version%20unknown/swagger.json
# Auth: --token flag or $env.EUROPEANA_SEARCH_RECORD_API_TOKEN

const BASE_URL = "https://api.europeana.eu"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EUROPEANA_SEARCH_RECORD_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.europeana.eu"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/rss+xml" "application/xhtml+xml" "application/xml"] }
def accept-completer-1 [] { ["application/json;charset=UTF-8" "application/ld+json;charset=UTF-8"] }
def accept-completer-2 [] { ["application/turtle" "application/x-turtle" "text/turtle"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "record-opensearchrss openSearch" } } | get name | first)
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
export def "record-opensearchrss openSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --count: int # count (format: int32, default: 12)
  --searchTerms: string # searchTerms
  --startIndex: int # startIndex (format: int32, default: 1)
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "searchTerms" $searchTerms "scalar") (serialize-qp "startIndex" $startIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/record/v2/opensearch.rss" $qp)
  let accept_val = ($accept | default "application/xml")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# search for records
#
# GET /record/v2/search.json
# operationId: searchRecords
export def "record-searchjson searchRecords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --boost: string # boost
  --callback: string # callback
  --colourpalette: list # colourpalette
  --cursor: string # cursor
  --facet: list # facet
  --hitfl: string # hit.fl
  --hitselectors: string # hit.selectors
  --landingpage: oneof<nothing, bool> # landingpage
  --lang: string # lang
  --media: oneof<nothing, bool> # media
  --profile: string # profile (default: standard)
  --qsource: string # q.source
  --qtarget: string # q.target
  --qf: list # qf
  --qp-query: string # query
  --reusability: list # reusability
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
  let qp = [(serialize-qp "boost" $boost "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "colourpalette" $colourpalette "multi") (serialize-qp "cursor" $cursor "scalar") (serialize-qp "facet" $facet "multi") (serialize-qp "hit.fl" $hitfl "scalar") (serialize-qp "hit.selectors" $hitselectors "scalar") (serialize-qp "landingpage" $landingpage "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "media" $media "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "q.source" $qsource "scalar") (serialize-qp "q.target" $qtarget "scalar") (serialize-qp "qf" $qf "multi") (serialize-qp "query" $qp_query "scalar") (serialize-qp "reusability" $reusability "multi") (serialize-qp "rows" $rows "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "text_fulltext" $text_fulltext "scalar") (serialize-qp "theme" $theme "scalar") (serialize-qp "thumbnail" $thumbnail "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/record/v2/search.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# search for records post
#
# POST /record/v2/search.json
# operationId: searchRecordsPost
# --hit shape: {fl?: string, selectors?: string}
export def "record-searchjson searchRecordsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --wskey: string # wskey
  --boost: string
  --callback: string
  --colourPalette: list
  --cursor: string
  --facet: list
  --hit: record # shape: {fl?: string, selectors?: string}
  --landingPage: oneof<nothing, bool>
  --media: oneof<nothing, bool>
  --profile: list
  --qf: list
  --body-query: string
  --reusability: list
  --rows: int # format: int32
  --body-sort: list
  --start: int # format: int32
  --textFulltext: oneof<nothing, bool>
  --theme: string
  --thumbnail: oneof<nothing, bool>
]: any -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/record/v2/search.json" $qp)
  let body = {boost: $boost, callback: $callback, colourPalette: $colourPalette, cursor: $cursor, facet: $facet, hit: $hit, landingPage: $landingPage, media: $media, profile: $profile, qf: $qf, query: $body_query, reusability: $reusability, rows: $rows, sort: $body_sort, start: $start, textFulltext: $textFulltext, theme: $theme, thumbnail: $thumbnail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# translate a term to different languages
#
# GET /record/v2/translateQuery.json
# operationId: translateQueryUsingGET
export def "record-translate-queryjson translateQueryUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # callback
  --languageCodes: list # languageCodes
  --profile: string # profile
  --term: string # term
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "languageCodes" $languageCodes "multi") (serialize-qp "profile" $profile "scalar") (serialize-qp "term" $term "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/record/v2/translateQuery.json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get a single record in JSON format
#
# GET /record/v2/{collectionId}/{recordId}.json
# operationId: getSingleRecordJson
export def "record get-by-collectionId-recordId" [
  collectionId: string
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback: string # callback
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/record/v2/($collectionId)/($recordId).json" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get single record in JSON LD format
#
# GET /record/v2/{collectionId}/{recordId}.jsonld
# operationId: getSingleRecordJsonLD
export def "record get-by-collectionId-recordId-1" [
  collectionId: string
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --callback: string # callback
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/record/v2/($collectionId)/($recordId).jsonld" $qp)
  let accept_val = ($accept | default "application/json;charset=UTF-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get single record in RDF format)
#
# GET /record/v2/{collectionId}/{recordId}.rdf
# operationId: getSingleRecordRDF
export def "record get-by-collectionId-recordId-2" [
  collectionId: string
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/record/v2/($collectionId)/($recordId).rdf" $qp)
  let accept_val = "application/rdf+xml;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get single record in Schema.org JSON LD format
#
# GET /record/v2/{collectionId}/{recordId}.schema.jsonld
# operationId: getSingleRecordSchemaOrg
export def "record get-by-collectionId-recordId-3" [
  collectionId: string
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --callback: string # callback
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callback" $callback "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/record/v2/($collectionId)/($recordId).schema.jsonld" $qp)
  let accept_val = ($accept | default "application/json;charset=UTF-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# get single record in turtle format)
#
# GET /record/v2/{collectionId}/{recordId}.ttl
# operationId: getSingleRecordTurtle
export def "record get-by-collectionId-recordId-4" [
  collectionId: string
  recordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-2 # Response content type
  --lang: string # lang
  --profile: string # profile (default: standard)
  --wskey: string # wskey
]: nothing -> record<empty: bool, model: record, modelMap: record, reference: bool, status: string, view: record<contentType: string>, viewName: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "profile" $profile "scalar") (serialize-qp "wskey" $wskey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/record/v2/($collectionId)/($recordId).ttl" $qp)
  let accept_val = ($accept | default "application/x-turtle")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
