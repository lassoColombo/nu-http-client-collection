# Auto-generated client for Bungie.Net API v2.18.0
# Source: https://api.apis.guru/v2/specs/bungie.net/2.18.0/openapi.json
# Auth: --token flag or $env.BUNGIE_NET_API_TOKEN

const BASE_URL = "https://www.bungie.net/Platform"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUNGIE_NET_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-API-Key: $token_val}, query: "", location: "header"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://www.bungie.net/Platform"] }
def auth-scheme-completer [] { ["x-api-key" "bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "app-api-usage get-application" } } | get name | first)
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

# Get API usage by application for time frame specified. You can go as far back as 30 days ago, and can ask for up to a 48 hour window of time in a single request. You must be authenticated with at least the ReadUserData permission to access this endpoint.
#
# GET /App/ApiUsage/{applicationId}/
# operationId: App.GetApplicationApiUsage
export def "app-api-usage get-application" [
  application_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --end: string # End time for query. Goes to now if not specified. (format: date-time)
  --start: string # Start time for query. Goes to 24 hours ago if not specified. (format: date-time)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($application_id | is-empty) { error make --unspanned { msg: "path parameter 'applicationId' must be non-empty" } }
  let qp = [(serialize-qp "end" $end "scalar") (serialize-qp "start" $start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({application_id: (encode-path-segment $application_id)} | format pattern "/App/ApiUsage/{application_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"end": $end, "start": $start} | compact), body: null}
}

# Get list of applications created by Bungie.
#
# GET /App/FirstParty/
# operationId: App.GetBungieApplications
export def "app-first-party get-bungie-applications" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/App/FirstParty/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns community content.
#
# GET /CommunityContent/Get/{sort}/{mediaFilter}/{page}/
# operationId: CommunityContent.GetCommunityContent
export def "community-content-get get" [
  sort: int
  media_filter: int
  page: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($sort | is-empty) { error make --unspanned { msg: "path parameter 'sort' must be non-empty" } }
  if ($media_filter | is-empty) { error make --unspanned { msg: "path parameter 'mediaFilter' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let full_url = (build-url $base ({sort: (encode-path-segment $sort), media_filter: (encode-path-segment $media_filter), page: (encode-path-segment $page)} | format pattern "/CommunityContent/Get/{sort}/{media_filter}/{page}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a content item referenced by id
#
# GET /Content/GetContentById/{id}/{locale}/
# operationId: Content.GetContentById
export def "content-get-content-by-id get" [
  id: int
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --head: oneof<nothing, bool> # false
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($locale | is-empty) { error make --unspanned { msg: "path parameter 'locale' must be non-empty" } }
  let qp = [(serialize-qp "head" $head "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), locale: (encode-path-segment $locale)} | format pattern "/Content/GetContentById/{id}/{locale}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"head": $head} | compact), body: null}
}

# Returns the newest item that matches a given tag and Content Type.
#
# GET /Content/GetContentByTagAndType/{tag}/{type}/{locale}/
# operationId: Content.GetContentByTagAndType
export def "content-get-content-by-tag-and-type get" [
  tag: string
  type: string
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --head: oneof<nothing, bool> # Not used.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($locale | is-empty) { error make --unspanned { msg: "path parameter 'locale' must be non-empty" } }
  let qp = [(serialize-qp "head" $head "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag: (encode-path-segment $tag), type: (encode-path-segment $type), locale: (encode-path-segment $locale)} | format pattern "/Content/GetContentByTagAndType/{tag}/{type}/{locale}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"head": $head} | compact), body: null}
}

# Gets an object describing a particular variant of content.
#
# GET /Content/GetContentType/{type}/
# operationId: Content.GetContentType
export def "content-get-content-type get" [
  type: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/Content/GetContentType/{type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a JSON string response that is the RSS feed for news articles.
#
# GET /Content/Rss/NewsArticles/{pageToken}/
# operationId: Content.RssNewsArticles
export def "content-rss-news-articles get" [
  page_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --categoryfilter: string # Optionally filter response to only include news items in a certain category.
  --includebody: oneof<nothing, bool> # Optionally include full content body for each news item.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($page_token | is-empty) { error make --unspanned { msg: "path parameter 'pageToken' must be non-empty" } }
  let qp = [(serialize-qp "categoryfilter" $categoryfilter "scalar") (serialize-qp "includebody" $includebody "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({page_token: (encode-path-segment $page_token)} | format pattern "/Content/Rss/NewsArticles/{page_token}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"categoryfilter": $categoryfilter, "includebody": $includebody} | compact), body: null}
}

# Gets content based on querystring information passed in. Provides basic search and text search capabilities.
#
# GET /Content/Search/{locale}/
# operationId: Content.SearchContentWithText
export def "content-search list-with-text" [
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ctype: string # Content type tag: Help, News, etc. Supply multiple ctypes separated by space.
  --currentpage: int # Page number for the search results, starting with page 1. (format: int32)
  --head: oneof<nothing, bool> # Not used.
  --searchtext: string # Word or phrase for the search.
  --qp-source: string # For analytics, hint at the part of the app that triggered the search. Optional.
  --tag: string # Tag used on the content to be searched.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($locale | is-empty) { error make --unspanned { msg: "path parameter 'locale' must be non-empty" } }
  let qp = [(serialize-qp "ctype" $ctype "scalar") (serialize-qp "currentpage" $currentpage "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "searchtext" $searchtext "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "tag" $tag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({locale: (encode-path-segment $locale)} | format pattern "/Content/Search/{locale}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"ctype": $ctype, "currentpage": $currentpage, "head": $head, "searchtext": $searchtext, "source": $qp_source, "tag": $tag} | compact), body: null}
}

# Searches for Content Items that match the given Tag and Content Type.
#
# GET /Content/SearchContentByTagAndType/{tag}/{type}/{locale}/
# operationId: Content.SearchContentByTagAndType
export def "content-search-content-by-tag-and-type list" [
  tag: string
  type: string
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number for the search results starting with page 1. (format: int32)
  --head: oneof<nothing, bool> # Not used.
  --itemsperpage: int # Not used. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($tag | is-empty) { error make --unspanned { msg: "path parameter 'tag' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($locale | is-empty) { error make --unspanned { msg: "path parameter 'locale' must be non-empty" } }
  let qp = [(serialize-qp "currentpage" $currentpage "scalar") (serialize-qp "head" $head "scalar") (serialize-qp "itemsperpage" $itemsperpage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tag: (encode-path-segment $tag), type: (encode-path-segment $type), locale: (encode-path-segment $locale)} | format pattern "/Content/SearchContentByTagAndType/{tag}/{type}/{locale}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currentpage": $currentpage, "head": $head, "itemsperpage": $itemsperpage} | compact), body: null}
}

# Search for Help Articles.
#
# GET /Content/SearchHelpArticles/{searchtext}/{size}/
# operationId: Content.SearchHelpArticles
export def "content-search-help-articles list" [
  searchtext: string
  size: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($searchtext | is-empty) { error make --unspanned { msg: "path parameter 'searchtext' must be non-empty" } }
  if ($size | is-empty) { error make --unspanned { msg: "path parameter 'size' must be non-empty" } }
  let full_url = (build-url $base ({searchtext: (encode-path-segment $searchtext), size: (encode-path-segment $size)} | format pattern "/Content/SearchHelpArticles/{searchtext}/{size}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Equip an item. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Items/EquipItem/
# operationId: Destiny2.EquipItem
export def "destiny2-actions-items-equip-item create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/EquipItem/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Equip a list of items by itemInstanceIds. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline. Any items not found on your character will be ignored.
#
# POST /Destiny2/Actions/Items/EquipItems/
# operationId: Destiny2.EquipItems
export def "destiny2-actions-items-equip-items create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/EquipItems/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Insert a plug into a socketed item. I know how it sounds, but I assure you it's much more G-rated than you might be guessing. We haven't decided yet whether this will be able to insert plugs that have side effects, but if we do it will require special scope permission for an application attempting to do so. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline. Request must include proof of permission for 'InsertPlugs' from the account owner.
#
# POST /Destiny2/Actions/Items/InsertSocketPlug/
# operationId: Destiny2.InsertSocketPlug
export def "destiny2-actions-items-insert-socket-plug create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/InsertSocketPlug/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Insert a 'free' plug into an item's socket. This does not require 'Advanced Write Action' authorization and is available to 3rd-party apps, but will only work on 'free and reversible' socket actions (Perks, Armor Mods, Shaders, Ornaments, etc.). You must have a valid Destiny Account, and the character must either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Items/InsertSocketPlugFree/
# operationId: Destiny2.InsertSocketPlugFree
export def "destiny2-actions-items-insert-socket-plug-free create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/InsertSocketPlugFree/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Extract an item from the Postmaster, with whatever implications that may entail. You must have a valid Destiny account. You must also pass BOTH a reference AND an instance ID if it's an instanced item.
#
# POST /Destiny2/Actions/Items/PullFromPostmaster/
# operationId: Destiny2.PullFromPostmaster
export def "destiny2-actions-items-pull-from-post-master pull" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/PullFromPostmaster/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set the Lock State for an instanced item. You must have a valid Destiny Account.
#
# POST /Destiny2/Actions/Items/SetLockState/
# operationId: Destiny2.SetItemLockState
export def "destiny2-actions-items-set-lock-state update" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/SetLockState/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Set the Tracking State for an instanced item, if that item is a Quest or Bounty. You must have a valid Destiny Account. Yeah, it's an item.
#
# POST /Destiny2/Actions/Items/SetTrackedState/
# operationId: Destiny2.SetQuestTrackedState
export def "destiny2-actions-items-set-tracked-state update-quest" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/SetTrackedState/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Transfer an item to/from your vault. You must have a valid Destiny account. You must also pass BOTH a reference AND an instance ID if it's an instanced item. itshappening.gif
#
# POST /Destiny2/Actions/Items/TransferItem/
# operationId: Destiny2.TransferItem
export def "destiny2-actions-items-transfer-item create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Items/TransferItem/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Clear the identifiers and items of a loadout.
#
# POST /Destiny2/Actions/Loadouts/ClearLoadout/
# operationId: Destiny2.ClearLoadout
export def "destiny2-actions-loadouts-clear-loadout create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Loadouts/ClearLoadout/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Equip a loadout. You must have a valid Destiny Account, and either be in a social space, in orbit, or offline.
#
# POST /Destiny2/Actions/Loadouts/EquipLoadout/
# operationId: Destiny2.EquipLoadout
export def "destiny2-actions-loadouts-equip-loadout create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Loadouts/EquipLoadout/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Snapshot a loadout with the currently equipped items.
#
# POST /Destiny2/Actions/Loadouts/SnapshotLoadout/
# operationId: Destiny2.SnapshotLoadout
export def "destiny2-actions-loadouts-snapshot-loadout create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Loadouts/SnapshotLoadout/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the color, icon, and name of a loadout.
#
# POST /Destiny2/Actions/Loadouts/UpdateLoadoutIdentifiers/
# operationId: Destiny2.UpdateLoadoutIdentifiers
export def "destiny2-actions-loadouts-update-loadout-identifiers update" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Actions/Loadouts/UpdateLoadoutIdentifiers/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a page list of Destiny items.
#
# GET /Destiny2/Armory/Search/{type}/{searchTerm}/
# operationId: Destiny2.SearchDestinyEntities
export def "destiny2-armory-search list-destiny-entities" [
  type: string
  search_term: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # Page number to return, starting with 0. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  if ($search_term | is-empty) { error make --unspanned { msg: "path parameter 'searchTerm' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), search_term: (encode-path-segment $search_term)} | format pattern "/Destiny2/Armory/Search/{type}/{search_term}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page} | compact), body: null}
}

# Provide the result of the user interaction. Called by the Bungie Destiny App to approve or reject a request.
#
# POST /Destiny2/Awa/AwaProvideAuthorizationResult/
# operationId: Destiny2.AwaProvideAuthorizationResult
export def "destiny2-awa-awa-provide-authorization-result create" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Awa/AwaProvideAuthorizationResult/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the action token if user approves the request.
#
# GET /Destiny2/Awa/GetActionToken/{correlationId}/
# operationId: Destiny2.AwaGetActionToken
export def "destiny2-awa-get-action-token get" [
  correlation_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($correlation_id | is-empty) { error make --unspanned { msg: "path parameter 'correlationId' must be non-empty" } }
  let full_url = (build-url $base ({correlation_id: (encode-path-segment $correlation_id)} | format pattern "/Destiny2/Awa/GetActionToken/{correlation_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Initialize a request to perform an advanced write action.
#
# POST /Destiny2/Awa/Initialize/
# operationId: Destiny2.AwaInitializeRequest
export def "destiny2-awa-initialize request" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Awa/Initialize/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the dictionary of values for the Clan Banner
#
# GET /Destiny2/Clan/ClanBannerDictionary/
# operationId: Destiny2.GetClanBannerSource
export def "destiny2-clan-clan-banner-dictionary get-source" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Clan/ClanBannerDictionary/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns information on the weekly clan rewards and if the clan has earned them or not. Note that this will always report rewards as not redeemed.
#
# GET /Destiny2/Clan/{groupId}/WeeklyRewardState/
# operationId: Destiny2.GetClanWeeklyRewardState
export def "destiny2-clan-weekly-reward-state get" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/Destiny2/Clan/{group_id}/WeeklyRewardState/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the current version of the manifest as a json object.
#
# GET /Destiny2/Manifest/
# operationId: Destiny2.GetDestinyManifest
export def "destiny2-manifest get-destiny" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Manifest/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the static definition of an entity of the given Type and hash identifier. Examine the API Documentation for the Type Names of entities that have their own definitions. Note that the return type will always *inherit from* DestinyDefinition, but the specific type returned will be the requested entity type if it can be found. Please don't use this as a chatty alternative to the Manifest database if you require large sets of data, but for simple and one-off accesses this should be handy.
#
# GET /Destiny2/Manifest/{entityType}/{hashIdentifier}/
# operationId: Destiny2.GetDestinyEntityDefinition
export def "destiny2-manifest get-destiny-entity-definition" [
  entity_type: string
  hash_identifier: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($entity_type | is-empty) { error make --unspanned { msg: "path parameter 'entityType' must be non-empty" } }
  if ($hash_identifier | is-empty) { error make --unspanned { msg: "path parameter 'hashIdentifier' must be non-empty" } }
  let full_url = (build-url $base ({entity_type: (encode-path-segment $entity_type), hash_identifier: (encode-path-segment $hash_identifier)} | format pattern "/Destiny2/Manifest/{entity_type}/{hash_identifier}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets public information about currently available Milestones.
#
# GET /Destiny2/Milestones/
# operationId: Destiny2.GetPublicMilestones
export def "destiny2-milestones get-public" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Milestones/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets custom localized content for the milestone of the given hash, if it exists.
#
# GET /Destiny2/Milestones/{milestoneHash}/Content/
# operationId: Destiny2.GetPublicMilestoneContent
export def "destiny2-milestones-content get-public" [
  milestone_hash: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($milestone_hash | is-empty) { error make --unspanned { msg: "path parameter 'milestoneHash' must be non-empty" } }
  let full_url = (build-url $base ({milestone_hash: (encode-path-segment $milestone_hash)} | format pattern "/Destiny2/Milestones/{milestone_hash}/Content/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of Destiny memberships given a global Bungie Display Name. This method will hide overridden memberships due to cross save.
#
# POST /Destiny2/SearchDestinyPlayerByBungieName/{membershipType}/
# operationId: Destiny2.SearchDestinyPlayerByBungieName
export def "destiny2-search-destiny-player-by-bungie-name list" [
  membership_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type)} | format pattern "/Destiny2/SearchDestinyPlayerByBungieName/{membership_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets aggregated stats for a clan using the same categories as the clan leaderboards. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/AggregateClanStats/{groupId}/
# operationId: Destiny2.GetClanAggregateStats
export def "destiny2-stats-aggregate-clan-stats get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "modes" $modes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/Destiny2/Stats/AggregateClanStats/{group_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"modes": $modes} | compact), body: null}
}

# Gets historical stats definitions.
#
# GET /Destiny2/Stats/Definition/
# operationId: Destiny2.GetHistoricalStatsDefinition
export def "destiny2-stats-definition get-historical" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Destiny2/Stats/Definition/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/Leaderboards/Clans/{groupId}/
# operationId: Destiny2.GetClanLeaderboards
export def "destiny2-stats-leaderboards-clans get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "maxtop" $maxtop "scalar") (serialize-qp "modes" $modes "scalar") (serialize-qp "statid" $statid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/Destiny2/Stats/Leaderboards/Clans/{group_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxtop": $maxtop, "modes": $modes, "statid": $statid} | compact), body: null}
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint is still in beta, and may experience rough edges. The schema is in final form, but there may be bugs that prevent desirable operation.
#
# GET /Destiny2/Stats/Leaderboards/{membershipType}/{destinyMembershipId}/{characterId}/
# operationId: Destiny2.GetLeaderboardsForCharacter
export def "destiny2-stats-leaderboards get-for-character" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  let qp = [(serialize-qp "maxtop" $maxtop "scalar") (serialize-qp "modes" $modes "scalar") (serialize-qp "statid" $statid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id)} | format pattern "/Destiny2/Stats/Leaderboards/{membership_type}/{destiny_membership_id}/{character_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxtop": $maxtop, "modes": $modes, "statid": $statid} | compact), body: null}
}

# Gets the available post game carnage report for the activity ID.
#
# GET /Destiny2/Stats/PostGameCarnageReport/{activityId}/
# operationId: Destiny2.GetPostGameCarnageReport
export def "destiny2-stats-post-game-carnage-report get" [
  activity_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityId' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/Destiny2/Stats/PostGameCarnageReport/{activity_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Report a player that you met in an activity that was engaging in ToS-violating activities. Both you and the offending player must have played in the activityId passed in. Please use this judiciously and only when you have strong suspicions of violation, pretty please.
#
# POST /Destiny2/Stats/PostGameCarnageReport/{activityId}/Report/
# operationId: Destiny2.ReportOffensivePostGameCarnageReportPlayer
export def "destiny2-stats-post-game-carnage-report-report create-offensive-player" [
  activity_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityId' must be non-empty" } }
  let full_url = (build-url $base ({activity_id: (encode-path-segment $activity_id)} | format pattern "/Destiny2/Stats/PostGameCarnageReport/{activity_id}/Report/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get items available from vendors where the vendors have items for sale that are common for everyone. If any portion of the Vendor's available inventory is character or account specific, we will be unable to return their data from this endpoint due to the way that available inventory is computed. As I am often guilty of saying: 'It's a long story...'
#
# GET /Destiny2/Vendors/
# operationId: Destiny2.GetPublicVendors
export def "destiny2-vendors get-public" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "components" $components "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/Destiny2/Vendors/" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"components": $components} | compact), body: null}
}

# Gets historical stats for indicated character.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/
# operationId: Destiny2.GetHistoricalStats
export def "destiny2-account-character-stats get-historical" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --dayend: string # Last day to return when daily stats are requested. Use the format YYYY-MM-DD. Currently, we cannot allow more than 31 days of daily data to be requested in a single request. (format: date-time)
  --daystart: string # First day to return when daily stats are requested. Use the format YYYY-MM-DD. Currently, we cannot allow more than 31 days of daily data to be requested in a single request. (format: date-time)
  --groups: list<int> # Group of stats to include, otherwise only general stats are returned. Comma separated list is allowed. Values: General, Weapons, Medals
  --modes: list<int> # Game modes to return. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --period-type: int # Indicates a specific period type to return. Optional. May be: Daily, AllTime, or Activity (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  let qp = [(serialize-qp "dayend" $dayend "scalar") (serialize-qp "daystart" $daystart "scalar") (serialize-qp "groups" $groups "csv") (serialize-qp "modes" $modes "csv") (serialize-qp "periodType" $period_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id)} | format pattern "/Destiny2/{membership_type}/Account/{destiny_membership_id}/Character/{character_id}/Stats/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"dayend": $dayend, "daystart": $daystart, "groups": $groups, "modes": $modes, "periodType": $period_type} | compact), body: null}
}

# Gets activity history stats for indicated character.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/Activities/
# operationId: Destiny2.GetActivityHistory
export def "destiny2-account-character-stats-activities get-activity-history" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # Number of rows to return (format: int32)
  --mode: int # A filter for the activity mode to be returned. None returns all activities. See the documentation for DestinyActivityModeType for valid values, and pass in string representation. (format: int32)
  --page: int # Page number to return, starting with 0. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  let qp = [(serialize-qp "count" $count "scalar") (serialize-qp "mode" $mode "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id)} | format pattern "/Destiny2/{membership_type}/Account/{destiny_membership_id}/Character/{character_id}/Stats/Activities/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"count": $count, "mode": $mode, "page": $page} | compact), body: null}
}

# Gets all activities the character has participated in together with aggregate statistics for those activities.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/AggregateActivityStats/
# operationId: Destiny2.GetDestinyAggregateActivityStats
export def "destiny2-account-character-stats-aggregate-activity-stats get-destiny" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id)} | format pattern "/Destiny2/{membership_type}/Account/{destiny_membership_id}/Character/{character_id}/Stats/AggregateActivityStats/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets details about unique weapon usage, including all exotic weapons.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Character/{characterId}/Stats/UniqueWeapons/
# operationId: Destiny2.GetUniqueWeaponHistory
export def "destiny2-account-character-stats-unique-weapons get-history" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id)} | format pattern "/Destiny2/{membership_type}/Account/{destiny_membership_id}/Character/{character_id}/Stats/UniqueWeapons/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets aggregate historical stats organized around each character for a given account.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Stats/
# operationId: Destiny2.GetHistoricalStatsForAccount
export def "destiny2-account-stats get-historical" [
  membership_type: int
  destiny_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list<int> # Groups of stats to include, otherwise only general stats are returned. Comma separated list is allowed. Values: General, Weapons, Medals.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  let qp = [(serialize-qp "groups" $groups "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id)} | format pattern "/Destiny2/{membership_type}/Account/{destiny_membership_id}/Stats/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"groups": $groups} | compact), body: null}
}

# Gets leaderboards with the signed in user's friends and the supplied destinyMembershipId as the focus. PREVIEW: This endpoint has not yet been implemented. It is being returned for a preview of future functionality, and for public comment/suggestion/preparation.
#
# GET /Destiny2/{membershipType}/Account/{destinyMembershipId}/Stats/Leaderboards/
# operationId: Destiny2.GetLeaderboards
export def "destiny2-account-stats-leaderboards get" [
  membership_type: int
  destiny_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --maxtop: int # Maximum number of top players to return. Use a large number to get entire leaderboard. (format: int32)
  --modes: string # List of game modes for which to get leaderboards. See the documentation for DestinyActivityModeType for valid values, and pass in string representation, comma delimited.
  --statid: string # ID of stat to return rather than returning all Leaderboard stats.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  let qp = [(serialize-qp "maxtop" $maxtop "scalar") (serialize-qp "modes" $modes "scalar") (serialize-qp "statid" $statid "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id)} | format pattern "/Destiny2/{membership_type}/Account/{destiny_membership_id}/Stats/Leaderboards/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"maxtop": $maxtop, "modes": $modes, "statid": $statid} | compact), body: null}
}

# Returns Destiny Profile information for the supplied membership.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/
# operationId: Destiny2.GetProfile
export def "destiny2-profile get" [
  membership_type: int
  destiny_membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  let qp = [(serialize-qp "components" $components "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id)} | format pattern "/Destiny2/{membership_type}/Profile/{destiny_membership_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"components": $components} | compact), body: null}
}

# Returns character information for the supplied character.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/
# operationId: Destiny2.GetCharacter
export def "destiny2-profile-character get" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  let qp = [(serialize-qp "components" $components "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id)} | format pattern "/Destiny2/{membership_type}/Profile/{destiny_membership_id}/Character/{character_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"components": $components} | compact), body: null}
}

# Given a Presentation Node that has Collectibles as direct descendants, this will return item details about those descendants in the context of the requesting character.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Collectibles/{collectiblePresentationNodeHash}/
# operationId: Destiny2.GetCollectibleNodeDetails
export def "destiny2-profile-character-collectibles get-node-details" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  collectible_presentation_node_hash: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  if ($collectible_presentation_node_hash | is-empty) { error make --unspanned { msg: "path parameter 'collectiblePresentationNodeHash' must be non-empty" } }
  let qp = [(serialize-qp "components" $components "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id), collectible_presentation_node_hash: (encode-path-segment $collectible_presentation_node_hash)} | format pattern "/Destiny2/{membership_type}/Profile/{destiny_membership_id}/Character/{character_id}/Collectibles/{collectible_presentation_node_hash}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"components": $components} | compact), body: null}
}

# Get currently available vendors from the list of vendors that can possibly have rotating inventory. Note that this does not include things like preview vendors and vendors-as-kiosks, neither of whom have rotating/dynamic inventories. Use their definitions as-is for those.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Vendors/
# operationId: Destiny2.GetVendors
export def "destiny2-profile-character-vendors list" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
  --filter: int # The filter of what vendors and items to return, if any. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  let qp = [(serialize-qp "components" $components "csv") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id)} | format pattern "/Destiny2/{membership_type}/Profile/{destiny_membership_id}/Character/{character_id}/Vendors/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"components": $components, "filter": $filter} | compact), body: null}
}

# Get the details of a specific Vendor.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Character/{characterId}/Vendors/{vendorHash}/
# operationId: Destiny2.GetVendor
export def "destiny2-profile-character-vendors get" [
  membership_type: int
  destiny_membership_id: int
  character_id: int
  vendor_hash: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($character_id | is-empty) { error make --unspanned { msg: "path parameter 'characterId' must be non-empty" } }
  if ($vendor_hash | is-empty) { error make --unspanned { msg: "path parameter 'vendorHash' must be non-empty" } }
  let qp = [(serialize-qp "components" $components "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), character_id: (encode-path-segment $character_id), vendor_hash: (encode-path-segment $vendor_hash)} | format pattern "/Destiny2/{membership_type}/Profile/{destiny_membership_id}/Character/{character_id}/Vendors/{vendor_hash}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"components": $components} | compact), body: null}
}

# Retrieve the details of an instanced Destiny Item. An instanced Destiny item is one with an ItemInstanceId. Non-instanced items, such as materials, have no useful instance-specific details and thus are not queryable here.
#
# GET /Destiny2/{membershipType}/Profile/{destinyMembershipId}/Item/{itemInstanceId}/
# operationId: Destiny2.GetItem
export def "destiny2-profile-item get" [
  membership_type: int
  destiny_membership_id: int
  item_instance_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --components: list<int> # A comma separated list of components to return (as strings or numeric values). See the DestinyComponentType enum for valid components to request. You must request at least one component to receive results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($destiny_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'destinyMembershipId' must be non-empty" } }
  if ($item_instance_id | is-empty) { error make --unspanned { msg: "path parameter 'itemInstanceId' must be non-empty" } }
  let qp = [(serialize-qp "components" $components "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), destiny_membership_id: (encode-path-segment $destiny_membership_id), item_instance_id: (encode-path-segment $item_instance_id)} | format pattern "/Destiny2/{membership_type}/Profile/{destiny_membership_id}/Item/{item_instance_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"components": $components} | compact), body: null}
}

# Returns a summary information about all profiles linked to the requesting membership type/membership ID that have valid Destiny information. The passed-in Membership Type/Membership ID may be a Bungie.Net membership or a Destiny membership. It only returns the minimal amount of data to begin making more substantive requests, but will hopefully serve as a useful alternative to UserServices for people who just care about Destiny data. Note that it will only return linked accounts whose linkages you are allowed to view.
#
# GET /Destiny2/{membershipType}/Profile/{membershipId}/LinkedProfiles/
# operationId: Destiny2.GetLinkedProfiles
export def "destiny2-profile-linked-profiles get" [
  membership_type: int
  membership_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --get-all-memberships: oneof<nothing, bool> # (optional) if set to 'true', all memberships regardless of whether they're obscured by overrides will be returned. Normal privacy restrictions on account linking will still apply no matter what.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let qp = [(serialize-qp "getAllMemberships" $get_all_memberships "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id)} | format pattern "/Destiny2/{membership_type}/Profile/{membership_id}/LinkedProfiles/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"getAllMemberships": $get_all_memberships} | compact), body: null}
}

# Gets a count of all active non-public fireteams for the specified clan. Maximum value returned is 25.
#
# GET /Fireteam/Clan/{groupId}/ActiveCount/
# operationId: Fireteam.GetActivePrivateClanFireteamCount
export def "fireteam-clan-active-count get-private" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/Fireteam/Clan/{group_id}/ActiveCount/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a listing of all of this clan's fireteams that are have available slots. Caller is not checked for join criteria so caching is maximized.
#
# GET /Fireteam/Clan/{groupId}/Available/{platform}/{activityType}/{dateRange}/{slotFilter}/{publicOnly}/{page}/
# operationId: Fireteam.GetAvailableClanFireteams
export def "fireteam-clan-available get" [
  group_id: int
  platform: int
  activity_type: int
  date_range: int
  slot_filter: int
  public_only: int
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-immediate: oneof<nothing, bool> # If you wish the result to exclude immediate fireteams, set this to true. Immediate-only can be forced using the dateRange enum.
  --lang-filter: string # An optional language filter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  if ($activity_type | is-empty) { error make --unspanned { msg: "path parameter 'activityType' must be non-empty" } }
  if ($date_range | is-empty) { error make --unspanned { msg: "path parameter 'dateRange' must be non-empty" } }
  if ($slot_filter | is-empty) { error make --unspanned { msg: "path parameter 'slotFilter' must be non-empty" } }
  if ($public_only | is-empty) { error make --unspanned { msg: "path parameter 'publicOnly' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let qp = [(serialize-qp "excludeImmediate" $exclude_immediate "scalar") (serialize-qp "langFilter" $lang_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), platform: (encode-path-segment $platform), activity_type: (encode-path-segment $activity_type), date_range: (encode-path-segment $date_range), slot_filter: (encode-path-segment $slot_filter), public_only: (encode-path-segment $public_only), page: (encode-path-segment $page)} | format pattern "/Fireteam/Clan/{group_id}/Available/{platform}/{activity_type}/{date_range}/{slot_filter}/{public_only}/{page}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"excludeImmediate": $exclude_immediate, "langFilter": $lang_filter} | compact), body: null}
}

# Gets a listing of all fireteams that caller is an applicant, a member, or an alternate of.
#
# GET /Fireteam/Clan/{groupId}/My/{platform}/{includeClosed}/{page}/
# operationId: Fireteam.GetMyClanFireteams
export def "fireteam-clan-my get" [
  group_id: int
  platform: int
  include_closed: bool
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --group-filter: oneof<nothing, bool> # If true, filter by clan. Otherwise, ignore the clan and show all of the user's fireteams.
  --lang-filter: string # An optional language filter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  if ($include_closed | is-empty) { error make --unspanned { msg: "path parameter 'includeClosed' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let qp = [(serialize-qp "groupFilter" $group_filter "scalar") (serialize-qp "langFilter" $lang_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), platform: (encode-path-segment $platform), include_closed: (encode-path-segment $include_closed), page: (encode-path-segment $page)} | format pattern "/Fireteam/Clan/{group_id}/My/{platform}/{include_closed}/{page}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"groupFilter": $group_filter, "langFilter": $lang_filter} | compact), body: null}
}

# Gets a specific fireteam.
#
# GET /Fireteam/Clan/{groupId}/Summary/{fireteamId}/
# operationId: Fireteam.GetClanFireteam
export def "fireteam-clan-summary get" [
  group_id: int
  fireteam_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($fireteam_id | is-empty) { error make --unspanned { msg: "path parameter 'fireteamId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), fireteam_id: (encode-path-segment $fireteam_id)} | format pattern "/Fireteam/Clan/{group_id}/Summary/{fireteam_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a listing of all public fireteams starting now with open slots. Caller is not checked for join criteria so caching is maximized.
#
# GET /Fireteam/Search/Available/{platform}/{activityType}/{dateRange}/{slotFilter}/{page}/
# operationId: Fireteam.SearchPublicAvailableClanFireteams
export def "fireteam-search-available list-public-clan" [
  platform: int
  activity_type: int
  date_range: int
  slot_filter: int
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exclude-immediate: oneof<nothing, bool> # If you wish the result to exclude immediate fireteams, set this to true. Immediate-only can be forced using the dateRange enum.
  --lang-filter: string # An optional language filter.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($platform | is-empty) { error make --unspanned { msg: "path parameter 'platform' must be non-empty" } }
  if ($activity_type | is-empty) { error make --unspanned { msg: "path parameter 'activityType' must be non-empty" } }
  if ($date_range | is-empty) { error make --unspanned { msg: "path parameter 'dateRange' must be non-empty" } }
  if ($slot_filter | is-empty) { error make --unspanned { msg: "path parameter 'slotFilter' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let qp = [(serialize-qp "excludeImmediate" $exclude_immediate "scalar") (serialize-qp "langFilter" $lang_filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({platform: (encode-path-segment $platform), activity_type: (encode-path-segment $activity_type), date_range: (encode-path-segment $date_range), slot_filter: (encode-path-segment $slot_filter), page: (encode-path-segment $page)} | format pattern "/Fireteam/Search/Available/{platform}/{activity_type}/{date_range}/{slot_filter}/{page}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"excludeImmediate": $exclude_immediate, "langFilter": $lang_filter} | compact), body: null}
}

# Gets a listing of all topics marked as part of the core group.
#
# GET /Forum/GetCoreTopicsPaged/{page}/{sort}/{quickDate}/{categoryFilter}/
# operationId: Forum.GetCoreTopicsPaged
export def "forum-get-core-topics-paged get" [
  page: int
  sort: int
  quick_date: int
  category_filter: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locales: string # Comma seperated list of locales posts must match to return in the result list. Default 'en'
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  if ($sort | is-empty) { error make --unspanned { msg: "path parameter 'sort' must be non-empty" } }
  if ($quick_date | is-empty) { error make --unspanned { msg: "path parameter 'quickDate' must be non-empty" } }
  if ($category_filter | is-empty) { error make --unspanned { msg: "path parameter 'categoryFilter' must be non-empty" } }
  let qp = [(serialize-qp "locales" $locales "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({page: (encode-path-segment $page), sort: (encode-path-segment $sort), quick_date: (encode-path-segment $quick_date), category_filter: (encode-path-segment $category_filter)} | format pattern "/Forum/GetCoreTopicsPaged/{page}/{sort}/{quick_date}/{category_filter}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locales": $locales} | compact), body: null}
}

# Gets tag suggestions based on partial text entry, matching them with other tags previously used in the forums.
#
# GET /Forum/GetForumTagSuggestions/
# operationId: Forum.GetForumTagSuggestions
export def "forum-get-forum-tag-suggestions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --partialtag: string # The partial tag input to generate suggestions from.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "partialtag" $partialtag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Forum/GetForumTagSuggestions/" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"partialtag": $partialtag} | compact), body: null}
}

# Returns the post specified and its immediate parent.
#
# GET /Forum/GetPostAndParent/{childPostId}/
# operationId: Forum.GetPostAndParent
export def "forum-get-post-and-parent get" [
  child_post_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($child_post_id | is-empty) { error make --unspanned { msg: "path parameter 'childPostId' must be non-empty" } }
  let qp = [(serialize-qp "showbanned" $showbanned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({child_post_id: (encode-path-segment $child_post_id)} | format pattern "/Forum/GetPostAndParent/{child_post_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"showbanned": $showbanned} | compact), body: null}
}

# Returns the post specified and its immediate parent of posts that are awaiting approval.
#
# GET /Forum/GetPostAndParentAwaitingApproval/{childPostId}/
# operationId: Forum.GetPostAndParentAwaitingApproval
export def "forum-get-post-and-parent-awaiting-approval get" [
  child_post_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($child_post_id | is-empty) { error make --unspanned { msg: "path parameter 'childPostId' must be non-empty" } }
  let qp = [(serialize-qp "showbanned" $showbanned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({child_post_id: (encode-path-segment $child_post_id)} | format pattern "/Forum/GetPostAndParentAwaitingApproval/{child_post_id}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"showbanned": $showbanned} | compact), body: null}
}

# Returns a thread of posts at the given parent, optionally returning replies to those posts as well as the original parent.
#
# GET /Forum/GetPostsThreadedPaged/{parentPostId}/{page}/{pageSize}/{replySize}/{getParentPost}/{rootThreadMode}/{sortMode}/
# operationId: Forum.GetPostsThreadedPaged
export def "forum-get-posts-threaded-paged get" [
  parent_post_id: int
  page: int
  page_size: int
  reply_size: int
  get_parent_post: bool
  root_thread_mode: bool
  sort_mode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($parent_post_id | is-empty) { error make --unspanned { msg: "path parameter 'parentPostId' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  if ($page_size | is-empty) { error make --unspanned { msg: "path parameter 'pageSize' must be non-empty" } }
  if ($reply_size | is-empty) { error make --unspanned { msg: "path parameter 'replySize' must be non-empty" } }
  if ($get_parent_post | is-empty) { error make --unspanned { msg: "path parameter 'getParentPost' must be non-empty" } }
  if ($root_thread_mode | is-empty) { error make --unspanned { msg: "path parameter 'rootThreadMode' must be non-empty" } }
  if ($sort_mode | is-empty) { error make --unspanned { msg: "path parameter 'sortMode' must be non-empty" } }
  let qp = [(serialize-qp "showbanned" $showbanned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent_post_id: (encode-path-segment $parent_post_id), page: (encode-path-segment $page), page_size: (encode-path-segment $page_size), reply_size: (encode-path-segment $reply_size), get_parent_post: (encode-path-segment $get_parent_post), root_thread_mode: (encode-path-segment $root_thread_mode), sort_mode: (encode-path-segment $sort_mode)} | format pattern "/Forum/GetPostsThreadedPaged/{parent_post_id}/{page}/{page_size}/{reply_size}/{get_parent_post}/{root_thread_mode}/{sort_mode}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"showbanned": $showbanned} | compact), body: null}
}

# Returns a thread of posts starting at the topicId of the input childPostId, optionally returning replies to those posts as well as the original parent.
#
# GET /Forum/GetPostsThreadedPagedFromChild/{childPostId}/{page}/{pageSize}/{replySize}/{rootThreadMode}/{sortMode}/
# operationId: Forum.GetPostsThreadedPagedFromChild
export def "forum-get-posts-threaded-paged-from-child get" [
  child_post_id: int
  page: int
  page_size: int
  reply_size: int
  root_thread_mode: bool
  sort_mode: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --showbanned: string # If this value is not null or empty, banned posts are requested to be returned
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($child_post_id | is-empty) { error make --unspanned { msg: "path parameter 'childPostId' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  if ($page_size | is-empty) { error make --unspanned { msg: "path parameter 'pageSize' must be non-empty" } }
  if ($reply_size | is-empty) { error make --unspanned { msg: "path parameter 'replySize' must be non-empty" } }
  if ($root_thread_mode | is-empty) { error make --unspanned { msg: "path parameter 'rootThreadMode' must be non-empty" } }
  if ($sort_mode | is-empty) { error make --unspanned { msg: "path parameter 'sortMode' must be non-empty" } }
  let qp = [(serialize-qp "showbanned" $showbanned "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({child_post_id: (encode-path-segment $child_post_id), page: (encode-path-segment $page), page_size: (encode-path-segment $page_size), reply_size: (encode-path-segment $reply_size), root_thread_mode: (encode-path-segment $root_thread_mode), sort_mode: (encode-path-segment $sort_mode)} | format pattern "/Forum/GetPostsThreadedPagedFromChild/{child_post_id}/{page}/{page_size}/{reply_size}/{root_thread_mode}/{sort_mode}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"showbanned": $showbanned} | compact), body: null}
}

# Gets the post Id for the given content item's comments, if it exists.
#
# GET /Forum/GetTopicForContent/{contentId}/
# operationId: Forum.GetTopicForContent
export def "forum-get-topic-for-content get" [
  content_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($content_id | is-empty) { error make --unspanned { msg: "path parameter 'contentId' must be non-empty" } }
  let full_url = (build-url $base ({content_id: (encode-path-segment $content_id)} | format pattern "/Forum/GetTopicForContent/{content_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get topics from any forum.
#
# GET /Forum/GetTopicsPaged/{page}/{pageSize}/{group}/{sort}/{quickDate}/{categoryFilter}/
# operationId: Forum.GetTopicsPaged
export def "forum-get-topics-paged get" [
  page: int
  page_size: int
  group: int
  sort: int
  quick_date: int
  category_filter: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locales: string # Comma seperated list of locales posts must match to return in the result list. Default 'en'
  --tagstring: string # The tags to search, if any.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  if ($page_size | is-empty) { error make --unspanned { msg: "path parameter 'pageSize' must be non-empty" } }
  if ($group | is-empty) { error make --unspanned { msg: "path parameter 'group' must be non-empty" } }
  if ($sort | is-empty) { error make --unspanned { msg: "path parameter 'sort' must be non-empty" } }
  if ($quick_date | is-empty) { error make --unspanned { msg: "path parameter 'quickDate' must be non-empty" } }
  if ($category_filter | is-empty) { error make --unspanned { msg: "path parameter 'categoryFilter' must be non-empty" } }
  let qp = [(serialize-qp "locales" $locales "scalar") (serialize-qp "tagstring" $tagstring "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({page: (encode-path-segment $page), page_size: (encode-path-segment $page_size), group: (encode-path-segment $group), sort: (encode-path-segment $sort), quick_date: (encode-path-segment $quick_date), category_filter: (encode-path-segment $category_filter)} | format pattern "/Forum/GetTopicsPaged/{page}/{page_size}/{group}/{sort}/{quick_date}/{category_filter}/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locales": $locales, "tagstring": $tagstring} | compact), body: null}
}

# Gets the specified forum poll.
#
# GET /Forum/Poll/{topicId}/
# operationId: Forum.GetPoll
export def "forum-poll get" [
  topic_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($topic_id | is-empty) { error make --unspanned { msg: "path parameter 'topicId' must be non-empty" } }
  let full_url = (build-url $base ({topic_id: (encode-path-segment $topic_id)} | format pattern "/Forum/Poll/{topic_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Allows the caller to get a list of to 25 recruitment thread summary information objects.
#
# POST /Forum/Recruit/Summaries/
# operationId: Forum.GetRecruitmentThreadSummaries
export def "forum-recruit-summaries get-recruitment-thread" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Forum/Recruit/Summaries/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of available localization cultures
#
# GET /GetAvailableLocales/
# operationId: .GetAvailableLocales
export def "get-available-locales get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GetAvailableLocales/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets any active global alert for display in the forum banners, help pages, etc. Usually used for DOC alerts.
#
# GET /GlobalAlerts/
# operationId: .GetGlobalAlerts
export def "global-alerts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --includestreaming: oneof<nothing, bool> # Determines whether Streaming Alerts are included in results
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includestreaming" $includestreaming "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/GlobalAlerts/" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"includestreaming": $includestreaming} | compact), body: null}
}

# Returns a list of all available group avatars for the signed-in user.
#
# GET /GroupV2/GetAvailableAvatars/
# operationId: GroupV2.GetAvailableAvatars
export def "group-v2-get-available-avatars get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GroupV2/GetAvailableAvatars/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of all available group themes.
#
# GET /GroupV2/GetAvailableThemes/
# operationId: GroupV2.GetAvailableThemes
export def "group-v2-get-available-themes get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GroupV2/GetAvailableThemes/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the state of the user's clan invite preferences for a particular membership type - true if they wish to be invited to clans, false otherwise.
#
# GET /GroupV2/GetUserClanInviteSetting/{mType}/
# operationId: GroupV2.GetUserClanInviteSetting
export def "group-v2-get-user-clan-invite-setting get" [
  m_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($m_type | is-empty) { error make --unspanned { msg: "path parameter 'mType' must be non-empty" } }
  let full_url = (build-url $base ({m_type: (encode-path-segment $m_type)} | format pattern "/GroupV2/GetUserClanInviteSetting/{m_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get information about a specific group with the given name and type.
#
# GET /GroupV2/Name/{groupName}/{groupType}/
# operationId: GroupV2.GetGroupByName
export def "group-v2-name get" [
  group_name: string
  group_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_name | is-empty) { error make --unspanned { msg: "path parameter 'groupName' must be non-empty" } }
  if ($group_type | is-empty) { error make --unspanned { msg: "path parameter 'groupType' must be non-empty" } }
  let full_url = (build-url $base ({group_name: (encode-path-segment $group_name), group_type: (encode-path-segment $group_type)} | format pattern "/GroupV2/Name/{group_name}/{group_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get information about a specific group with the given name and type. The POST version.
#
# POST /GroupV2/NameV2/
# operationId: GroupV2.GetGroupByNameV2
export def "group-v2-name-v2 get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GroupV2/NameV2/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets groups recommended for you based on the groups to whom those you follow belong.
#
# POST /GroupV2/Recommended/{groupType}/{createDateRange}/
# operationId: GroupV2.GetRecommendedGroups
export def "group-v2-recommended get" [
  group_type: int
  create_date_range: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_type | is-empty) { error make --unspanned { msg: "path parameter 'groupType' must be non-empty" } }
  if ($create_date_range | is-empty) { error make --unspanned { msg: "path parameter 'createDateRange' must be non-empty" } }
  let full_url = (build-url $base ({group_type: (encode-path-segment $group_type), create_date_range: (encode-path-segment $create_date_range)} | format pattern "/GroupV2/Recommended/{group_type}/{create_date_range}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Allows a founder to manually recover a group they can see in game but not on bungie.net
#
# GET /GroupV2/Recover/{membershipType}/{membershipId}/{groupType}/
# operationId: GroupV2.RecoverGroupForFounder
export def "group-v2-recover get-for-founder" [
  membership_type: int
  membership_id: int
  group_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  if ($group_type | is-empty) { error make --unspanned { msg: "path parameter 'groupType' must be non-empty" } }
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id), group_type: (encode-path-segment $group_type)} | format pattern "/GroupV2/Recover/{membership_type}/{membership_id}/{group_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search for Groups.
#
# POST /GroupV2/Search/
# operationId: GroupV2.GroupSearch
export def "group-v2-search list" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/GroupV2/Search/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get information about the groups that a given member has applied to or been invited to.
#
# GET /GroupV2/User/Potential/{membershipType}/{membershipId}/{filter}/{groupType}/
# operationId: GroupV2.GetPotentialGroupsForMember
export def "group-v2-user-potential get-for-member" [
  membership_type: int
  membership_id: int
  filter: int
  group_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  if ($filter | is-empty) { error make --unspanned { msg: "path parameter 'filter' must be non-empty" } }
  if ($group_type | is-empty) { error make --unspanned { msg: "path parameter 'groupType' must be non-empty" } }
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id), filter: (encode-path-segment $filter), group_type: (encode-path-segment $group_type)} | format pattern "/GroupV2/User/Potential/{membership_type}/{membership_id}/{filter}/{group_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get information about the groups that a given member has joined.
#
# GET /GroupV2/User/{membershipType}/{membershipId}/{filter}/{groupType}/
# operationId: GroupV2.GetGroupsForMember
export def "group-v2-user get-for-member" [
  membership_type: int
  membership_id: int
  filter: int
  group_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  if ($filter | is-empty) { error make --unspanned { msg: "path parameter 'filter' must be non-empty" } }
  if ($group_type | is-empty) { error make --unspanned { msg: "path parameter 'groupType' must be non-empty" } }
  let full_url = (build-url $base ({membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id), filter: (encode-path-segment $filter), group_type: (encode-path-segment $group_type)} | format pattern "/GroupV2/User/{membership_type}/{membership_id}/{filter}/{group_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get information about a specific group of the given ID.
#
# GET /GroupV2/{groupId}/
# operationId: GroupV2.GetGroup
export def "group-v2 get" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# An administrative method to allow the founder of a group or clan to give up their position to another admin permanently.
#
# POST /GroupV2/{groupId}/Admin/AbdicateFoundership/{membershipType}/{founderIdNew}/
# operationId: GroupV2.AbdicateFoundership
export def "group-v2-admin-abdicate-foundership create" [
  group_id: int
  membership_type: int
  founder_id_new: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($founder_id_new | is-empty) { error make --unspanned { msg: "path parameter 'founderIdNew' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), membership_type: (encode-path-segment $membership_type), founder_id_new: (encode-path-segment $founder_id_new)} | format pattern "/GroupV2/{group_id}/Admin/AbdicateFoundership/{membership_type}/{founder_id_new}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the list of members in a given group who are of admin level or higher.
#
# GET /GroupV2/{groupId}/AdminsAndFounder/
# operationId: GroupV2.GetAdminsAndFounderOfGroup
export def "group-v2-admins-and-founder get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 items per page. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "currentpage" $currentpage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/AdminsAndFounder/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currentpage": $currentpage} | compact), body: null}
}

# Get the list of banned members in a given group. Only accessible to group Admins and above. Not applicable to all groups. Check group features.
#
# GET /GroupV2/{groupId}/Banned/
# operationId: GroupV2.GetBannedMembersOfGroup
export def "group-v2-banned get-members" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 entries. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "currentpage" $currentpage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Banned/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currentpage": $currentpage} | compact), body: null}
}

# Edit an existing group. You must have suitable permissions in the group to perform this operation. This latest revision will only edit the fields you pass in - pass null for properties you want to leave unaltered.
#
# POST /GroupV2/{groupId}/Edit/
# operationId: GroupV2.EditGroup
export def "group-v2-edit create" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Edit/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit an existing group's clan banner. You must have suitable permissions in the group to perform this operation. All fields are required.
#
# POST /GroupV2/{groupId}/EditClanBanner/
# operationId: GroupV2.EditClanBanner
export def "group-v2-edit-clan-banner create" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/EditClanBanner/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit group options only available to a founder. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/EditFounderOptions/
# operationId: GroupV2.EditFounderOptions
export def "group-v2-edit-founder-options create" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/EditFounderOptions/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the list of members in a given group.
#
# GET /GroupV2/{groupId}/Members/
# operationId: GroupV2.GetMembersOfGroup
export def "group-v2-members get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 items per page. (format: int32)
  --member-type: int # Filter out other member types. Use None for all members. (format: int32)
  --name-search: string # The name fragment upon which a search should be executed for members with matching display or unique names.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "currentpage" $currentpage "scalar") (serialize-qp "memberType" $member_type "scalar") (serialize-qp "nameSearch" $name_search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Members/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currentpage": $currentpage, "memberType": $member_type, "nameSearch": $name_search} | compact), body: null}
}

# Approve the given membershipId to join the group/clan as long as they have applied.
#
# POST /GroupV2/{groupId}/Members/Approve/{membershipType}/{membershipId}/
# operationId: GroupV2.ApprovePending
export def "group-v2-members-approve approve-pending" [
  group_id: int
  membership_type: int
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id)} | format pattern "/GroupV2/{group_id}/Members/Approve/{membership_type}/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Approve all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/ApproveAll/
# operationId: GroupV2.ApproveAllPending
export def "group-v2-members-approve-all approve-pending" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Members/ApproveAll/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Approve all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/ApproveList/
# operationId: GroupV2.ApprovePendingForList
export def "group-v2-members-approve-list approve-pending" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Members/ApproveList/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deny all of the pending users for the given group.
#
# POST /GroupV2/{groupId}/Members/DenyAll/
# operationId: GroupV2.DenyAllPending
export def "group-v2-members-deny-all list-pending" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Members/DenyAll/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deny all of the pending users for the given group that match the passed-in .
#
# POST /GroupV2/{groupId}/Members/DenyList/
# operationId: GroupV2.DenyPendingForList
export def "group-v2-members-deny-list list-pending" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Members/DenyList/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Invite a user to join this group.
#
# POST /GroupV2/{groupId}/Members/IndividualInvite/{membershipType}/{membershipId}/
# operationId: GroupV2.IndividualGroupInvite
export def "group-v2-members-individual-invite create" [
  group_id: int
  membership_type: int
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id)} | format pattern "/GroupV2/{group_id}/Members/IndividualInvite/{membership_type}/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancels a pending invitation to join a group.
#
# POST /GroupV2/{groupId}/Members/IndividualInviteCancel/{membershipType}/{membershipId}/
# operationId: GroupV2.IndividualGroupInviteCancel
export def "group-v2-members-individual-invite-cancel cancel" [
  group_id: int
  membership_type: int
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id)} | format pattern "/GroupV2/{group_id}/Members/IndividualInviteCancel/{membership_type}/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the list of users who have been invited into the group.
#
# GET /GroupV2/{groupId}/Members/InvitedIndividuals/
# operationId: GroupV2.GetInvitedIndividuals
export def "group-v2-members-invited-individuals get" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 items per page. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "currentpage" $currentpage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Members/InvitedIndividuals/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currentpage": $currentpage} | compact), body: null}
}

# Get the list of users who are awaiting a decision on their application to join a given group. Modified to include application info.
#
# GET /GroupV2/{groupId}/Members/Pending/
# operationId: GroupV2.GetPendingMemberships
export def "group-v2-members-pending get-memberships" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --currentpage: int # Page number (starting with 1). Each page has a fixed size of 50 items per page. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let qp = [(serialize-qp "currentpage" $currentpage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/Members/Pending/") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"currentpage": $currentpage} | compact), body: null}
}

# Bans the requested member from the requested group for the specified period of time.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Ban/
# operationId: GroupV2.BanMember
export def "group-v2-members-ban create" [
  group_id: int
  membership_type: int
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id)} | format pattern "/GroupV2/{group_id}/Members/{membership_type}/{membership_id}/Ban/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Kick a member from the given group, forcing them to reapply if they wish to re-join the group. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Kick/
# operationId: GroupV2.KickMember
export def "group-v2-members-kick create" [
  group_id: int
  membership_type: int
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id)} | format pattern "/GroupV2/{group_id}/Members/{membership_type}/{membership_id}/Kick/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit the membership type of a given member. You must have suitable permissions in the group to perform this operation.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/SetMembershipType/{memberType}/
# operationId: GroupV2.EditGroupMembership
export def "group-v2-members-set-membership-type create-edit" [
  group_id: int
  membership_type: int
  membership_id: int
  member_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  if ($member_type | is-empty) { error make --unspanned { msg: "path parameter 'memberType' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id), member_type: (encode-path-segment $member_type)} | format pattern "/GroupV2/{group_id}/Members/{membership_type}/{membership_id}/SetMembershipType/{member_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Unbans the requested member, allowing them to re-apply for membership.
#
# POST /GroupV2/{groupId}/Members/{membershipType}/{membershipId}/Unban/
# operationId: GroupV2.UnbanMember
export def "group-v2-members-unban create" [
  group_id: int
  membership_type: int
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), membership_type: (encode-path-segment $membership_type), membership_id: (encode-path-segment $membership_id)} | format pattern "/GroupV2/{group_id}/Members/{membership_type}/{membership_id}/Unban/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a list of available optional conversation channels and their settings.
#
# GET /GroupV2/{groupId}/OptionalConversations/
# operationId: GroupV2.GetGroupOptionalConversations
export def "group-v2-optional-conversations get" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/OptionalConversations/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Add a new optional conversation/chat channel. Requires admin permissions to the group.
#
# POST /GroupV2/{groupId}/OptionalConversations/Add/
# operationId: GroupV2.AddOptionalConversation
export def "group-v2-optional-conversations-add create" [
  group_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id)} | format pattern "/GroupV2/{group_id}/OptionalConversations/Add/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Edit the settings of an optional conversation/chat channel. Requires admin permissions to the group.
#
# POST /GroupV2/{groupId}/OptionalConversations/Edit/{conversationId}/
# operationId: GroupV2.EditOptionalConversation
export def "group-v2-optional-conversations-edit create" [
  group_id: int
  conversation_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($group_id | is-empty) { error make --unspanned { msg: "path parameter 'groupId' must be non-empty" } }
  if ($conversation_id | is-empty) { error make --unspanned { msg: "path parameter 'conversationId' must be non-empty" } }
  let full_url = (build-url $base ({group_id: (encode-path-segment $group_id), conversation_id: (encode-path-segment $conversation_id)} | format pattern "/GroupV2/{group_id}/OptionalConversations/Edit/{conversation_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the common settings used by the Bungie.Net environment.
#
# GET /Settings/
# operationId: .GetCommonSettings
export def "settings get-common" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Settings/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns your Bungie Friend list
#
# GET /Social/Friends/
# operationId: Social.GetFriendList
export def "social-friends get-list" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Social/Friends/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Requests a friend relationship with the target user. Any of the target user's linked membership ids are valid inputs.
#
# POST /Social/Friends/Add/{membershipId}/
# operationId: Social.IssueFriendRequest
export def "social-friends-add request-issue" [
  membership_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id)} | format pattern "/Social/Friends/Add/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a friend relationship with the target user. The user must be on your friend list, though no error will occur if they are not.
#
# POST /Social/Friends/Remove/{membershipId}/
# operationId: Social.RemoveFriend
export def "social-friends-remove delete" [
  membership_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id)} | format pattern "/Social/Friends/Remove/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns your friend request queue.
#
# GET /Social/Friends/Requests/
# operationId: Social.GetFriendRequestList
export def "social-friends-requests get-list" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Social/Friends/Requests/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Accepts a friend relationship with the target user. The user must be on your incoming friend request list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Accept/{membershipId}/
# operationId: Social.AcceptFriendRequest
export def "social-friends-requests-accept request" [
  membership_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id)} | format pattern "/Social/Friends/Requests/Accept/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Declines a friend relationship with the target user. The user must be on your incoming friend request list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Decline/{membershipId}/
# operationId: Social.DeclineFriendRequest
export def "social-friends-requests-decline request" [
  membership_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id)} | format pattern "/Social/Friends/Requests/Decline/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Remove a friend relationship with the target user. The user must be on your outgoing request friend list, though no error will occur if they are not.
#
# POST /Social/Friends/Requests/Remove/{membershipId}/
# operationId: Social.RemoveFriendRequest
export def "social-friends-requests-remove delete" [
  membership_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id)} | format pattern "/Social/Friends/Requests/Remove/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets the platform friend of the requested type, with additional information if they have Bungie accounts. Must have a recent login session with said platform.
#
# GET /Social/PlatformFriends/{friendPlatform}/{page}/
# operationId: Social.GetPlatformFriendList
export def "social-platform-friends get-list" [
  friend_platform: int
  page: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($friend_platform | is-empty) { error make --unspanned { msg: "path parameter 'friendPlatform' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let full_url = (build-url $base ({friend_platform: (encode-path-segment $friend_platform), page: (encode-path-segment $page)} | format pattern "/Social/PlatformFriends/{friend_platform}/{page}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Apply a partner offer to the targeted user. This endpoint does not claim a new offer, but any already claimed offers will be applied to the game if not already.
#
# POST /Tokens/Partner/ApplyMissingOffers/{partnerApplicationId}/{targetBnetMembershipId}/
# operationId: Tokens.ApplyMissingPartnerOffersWithoutClaim
export def "tokens-partner-apply-missing-offers create-without-claim" [
  partner_application_id: int
  target_bnet_membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_application_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerApplicationId' must be non-empty" } }
  if ($target_bnet_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'targetBnetMembershipId' must be non-empty" } }
  let full_url = (build-url $base ({partner_application_id: (encode-path-segment $partner_application_id), target_bnet_membership_id: (encode-path-segment $target_bnet_membership_id)} | format pattern "/Tokens/Partner/ApplyMissingOffers/{partner_application_id}/{target_bnet_membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Claim a partner offer as the authenticated user.
#
# POST /Tokens/Partner/ClaimOffer/
# operationId: Tokens.ClaimPartnerOffer
export def "tokens-partner-claim-offer create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Tokens/Partner/ClaimOffer/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Twitch Drops self-repair function - scans twitch for drops not marked as fulfilled and resyncs them.
#
# POST /Tokens/Partner/ForceDropsRepair/
# operationId: Tokens.ForceDropsRepair
export def "tokens-partner-force-drops-repair create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Tokens/Partner/ForceDropsRepair/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the partner sku and offer history of the targeted user. Elevated permissions are required to see users that are not yourself.
#
# GET /Tokens/Partner/History/{partnerApplicationId}/{targetBnetMembershipId}/
# operationId: Tokens.GetPartnerOfferSkuHistory
export def "tokens-partner-history get-offer-sku" [
  partner_application_id: int
  target_bnet_membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($partner_application_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerApplicationId' must be non-empty" } }
  if ($target_bnet_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'targetBnetMembershipId' must be non-empty" } }
  let full_url = (build-url $base ({partner_application_id: (encode-path-segment $partner_application_id), target_bnet_membership_id: (encode-path-segment $target_bnet_membership_id)} | format pattern "/Tokens/Partner/History/{partner_application_id}/{target_bnet_membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the partner rewards history of the targeted user, both partner offers and Twitch drops.
#
# GET /Tokens/Partner/History/{targetBnetMembershipId}/Application/{partnerApplicationId}/
# operationId: Tokens.GetPartnerRewardHistory
export def "tokens-partner-history-application get-reward" [
  target_bnet_membership_id: int
  partner_application_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($target_bnet_membership_id | is-empty) { error make --unspanned { msg: "path parameter 'targetBnetMembershipId' must be non-empty" } }
  if ($partner_application_id | is-empty) { error make --unspanned { msg: "path parameter 'partnerApplicationId' must be non-empty" } }
  let full_url = (build-url $base ({target_bnet_membership_id: (encode-path-segment $target_bnet_membership_id), partner_application_id: (encode-path-segment $partner_application_id)} | format pattern "/Tokens/Partner/History/{target_bnet_membership_id}/Application/{partner_application_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of the current bungie rewards
#
# GET /Tokens/Rewards/BungieRewards/
# operationId: Tokens.GetBungieRewardsList
export def "tokens-rewards-bungie-rewards get-list" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Tokens/Rewards/BungieRewards/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the bungie rewards for the targeted user when a platform membership Id and Type are used.
#
# GET /Tokens/Rewards/GetRewardsForPlatformUser/{membershipId}/{membershipType}/
# operationId: Tokens.GetBungieRewardsForPlatformUser
export def "tokens-rewards-get-rewards-for-platform-user get-bungie" [
  membership_id: int
  membership_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id), membership_type: (encode-path-segment $membership_type)} | format pattern "/Tokens/Rewards/GetRewardsForPlatformUser/{membership_id}/{membership_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the bungie rewards for the targeted user.
#
# GET /Tokens/Rewards/GetRewardsForUser/{membershipId}/
# operationId: Tokens.GetBungieRewardsForUser
export def "tokens-rewards-get-rewards-for-user get-bungie" [
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id)} | format pattern "/Tokens/Rewards/GetRewardsForUser/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns trending items for Bungie.net, collapsed into the first page of items per category. For pagination within a category, call GetTrendingCategory.
#
# GET /Trending/Categories/
# operationId: Trending.GetTrendingCategories
export def "trending-categories get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Trending/Categories/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns paginated lists of trending items for a category.
#
# GET /Trending/Categories/{categoryId}/{pageNumber}/
# operationId: Trending.GetTrendingCategory
export def "trending-categories get-category" [
  category_id: string
  page_number: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'categoryId' must be non-empty" } }
  if ($page_number | is-empty) { error make --unspanned { msg: "path parameter 'pageNumber' must be non-empty" } }
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id), page_number: (encode-path-segment $page_number)} | format pattern "/Trending/Categories/{category_id}/{page_number}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the detailed results for a specific trending entry. Note that trending entries are uniquely identified by a combination of *both* the TrendingEntryType *and* the identifier: the identifier alone is not guaranteed to be globally unique.
#
# GET /Trending/Details/{trendingEntryType}/{identifier}/
# operationId: Trending.GetTrendingEntryDetail
export def "trending-details get-entry" [
  trending_entry_type: int
  identifier: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($trending_entry_type | is-empty) { error make --unspanned { msg: "path parameter 'trendingEntryType' must be non-empty" } }
  if ($identifier | is-empty) { error make --unspanned { msg: "path parameter 'identifier' must be non-empty" } }
  let full_url = (build-url $base ({trending_entry_type: (encode-path-segment $trending_entry_type), identifier: (encode-path-segment $identifier)} | format pattern "/Trending/Details/{trending_entry_type}/{identifier}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of all available user themes.
#
# GET /User/GetAvailableThemes/
# operationId: User.GetAvailableThemes
export def "user-get-available-themes get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/User/GetAvailableThemes/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Loads a bungienet user by membership id.
#
# GET /User/GetBungieNetUserById/{id}/
# operationId: User.GetBungieNetUserById
export def "user-get-bungie-net-user-by-id get" [
  id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/User/GetBungieNetUserById/{id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of credential types attached to the requested account
#
# GET /User/GetCredentialTypesForTargetAccount/{membershipId}/
# operationId: User.GetCredentialTypesForTargetAccount
export def "user-get-credential-types-for-target-account get" [
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id)} | format pattern "/User/GetCredentialTypesForTargetAccount/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets any hard linked membership given a credential. Only works for credentials that are public (just SteamID64 right now). Cross Save aware.
#
# GET /User/GetMembershipFromHardLinkedCredential/{crType}/{credential}/
# operationId: User.GetMembershipFromHardLinkedCredential
export def "user-get-membership-from-hard-linked-credential get" [
  cr_type: int
  credential: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($cr_type | is-empty) { error make --unspanned { msg: "path parameter 'crType' must be non-empty" } }
  if ($credential | is-empty) { error make --unspanned { msg: "path parameter 'credential' must be non-empty" } }
  let full_url = (build-url $base ({cr_type: (encode-path-segment $cr_type), credential: (encode-path-segment $credential)} | format pattern "/User/GetMembershipFromHardLinkedCredential/{cr_type}/{credential}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of accounts associated with the supplied membership ID and membership type. This will include all linked accounts (even when hidden) if supplied credentials permit it.
#
# GET /User/GetMembershipsById/{membershipId}/{membershipType}/
# operationId: User.GetMembershipDataById
export def "user-get-memberships-by-id get-data" [
  membership_id: int
  membership_type: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  if ($membership_type | is-empty) { error make --unspanned { msg: "path parameter 'membershipType' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id), membership_type: (encode-path-segment $membership_type)} | format pattern "/User/GetMembershipsById/{membership_id}/{membership_type}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of accounts associated with signed in user. This is useful for OAuth implementations that do not give you access to the token response.
#
# GET /User/GetMembershipsForCurrentUser/
# operationId: User.GetMembershipDataForCurrentUser
export def "user-get-memberships-for-current-user get-data" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/User/GetMembershipsForCurrentUser/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets a list of all display names linked to this membership id but sanitized (profanity filtered). Obeys all visibility rules of calling user and is heavily cached.
#
# GET /User/GetSanitizedPlatformDisplayNames/{membershipId}/
# operationId: User.GetSanitizedPlatformDisplayNames
export def "user-get-sanitized-platform-display-names get" [
  membership_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($membership_id | is-empty) { error make --unspanned { msg: "path parameter 'membershipId' must be non-empty" } }
  let full_url = (build-url $base ({membership_id: (encode-path-segment $membership_id)} | format pattern "/User/GetSanitizedPlatformDisplayNames/{membership_id}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Given the prefix of a global display name, returns all users who share that name.
#
# POST /User/Search/GlobalName/{page}/
# operationId: User.SearchByGlobalNamePost
export def "user-search-global-name create-by" [
  page: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let full_url = (build-url $base ({page: (encode-path-segment $page)} | format pattern "/User/Search/GlobalName/{page}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# [OBSOLETE] Do not use this to search users, use SearchByGlobalNamePost instead.
#
# GET /User/Search/Prefix/{displayNamePrefix}/{page}/
# operationId: User.SearchByGlobalNamePrefix
export def "user-search-prefix list-by-global-name" [
  display_name_prefix: string
  page: int
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  if ($display_name_prefix | is-empty) { error make --unspanned { msg: "path parameter 'displayNamePrefix' must be non-empty" } }
  if ($page | is-empty) { error make --unspanned { msg: "path parameter 'page' must be non-empty" } }
  let full_url = (build-url $base ({display_name_prefix: (encode-path-segment $display_name_prefix), page: (encode-path-segment $page)} | format pattern "/User/Search/Prefix/{display_name_prefix}/{page}/"))
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get the user-specific system overrides that should be respected alongside common systems.
#
# GET /UserSystemOverrides/
# operationId: .GetUserSystemOverrides
export def "user-system-overrides get" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/UserSystemOverrides/")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}
