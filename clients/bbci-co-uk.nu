# Auto-generated client for BBC iPlayer Business Layer v1.0
# Source: https://api.apis.guru/v2/specs/bbci.co.uk/1.0/openapi.json
# Auth: --token flag or $env.BBC_IPLAYER_BUSINESS_LAYER_TOKEN

const BASE_URL = "https://ibl.api.bbci.co.uk/ibl/v1"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BBC_IPLAYER_BUSINESS_LAYER_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "query-api_key" => { {scheme: $scheme, headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)", location: "query"} }
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://ibl.api.bbci.co.uk/ibl/v1" "http://ibl.api.bbci.co.uk/ibl/v1"] }
def auth-scheme-completer [] { ["query-api_key" "basic" "none" "basic-credentials"] }

# Completers for enum parameters
def rights-completer [] { ["mobile" "tv" "web"] }
def sort-completer [] { ["title"] }
def sort-direction-completer [] { ["asc" "desc"] }
def availability-completer [] { ["all" "available"] }
def lang-completer [] { ["cy" "en" "ga" "gd" "pi"] }
def sort-completer-1 [] { ["popular" "recent"] }
def mixin-completer [] { ["live" "promotions"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "atoz-programmes get-ato-z-list" } } | get name | first)
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

# Programmes by initial title character
#
# GET /atoz/{letter}/programmes
# operationId: Get_Programmes AtoZ search_
export def "atoz-programmes get-ato-z-list" [
  letter: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
  --initial-child-count: int # The depth to return child entities. (default: 4)
  --qp-sort: string@sort-completer # The sort order of the results.
  --sort-direction: string@sort-direction-completer # Whether to sort ascending or descending
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($letter | is-empty) { error make --unspanned { msg: "path parameter 'letter' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({letter: (encode-path-segment $letter)} | format pattern "/atoz/{letter}/programmes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "page": $page, "per_page": $per_page, "initial_child_count": $initial_child_count, "sort": $qp_sort, "sort_direction": $sort_direction, "availability": $availability} | compact), body: null}
}

# Get categories
#
# GET /categories
# operationId: Get_Categories_
export def "categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang} | compact), body: null}
}

# Get sub-categories
#
# GET /categories/{category}
# operationId: Get_Sub-categories_
export def "categories get-sub" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/categories/{category}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang} | compact), body: null}
}

# List all the episodes for a category.
#
# GET /categories/{category}/episodes
# operationId: Get_Episodes by category_
export def "categories-episodes get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
  --qp-sort: string@sort-completer-1 # The sort order of the results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/categories/{category}/episodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "rights": $rights, "availability": $availability, "page": $page, "per_page": $per_page, "sort": $qp_sort} | compact), body: null}
}

# List the highlights for a category.
#
# GET /categories/{category}/highlights
# operationId: Get_Highlights by category_
export def "categories-highlights get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list<string>@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/categories/{category}/highlights") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "rights": $rights, "availability": $availability, "mixin": $mixin} | compact), body: null}
}

# List all the programmes for a category.
#
# GET /categories/{category}/programmes
# operationId: Get_Programmes by category_
export def "categories-programmes get" [
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({category: (encode-path-segment $category)} | format pattern "/categories/{category}/programmes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "rights": $rights, "availability": $availability, "page": $page, "per_page": $per_page} | compact), body: null}
}

# List all the channels.
#
# GET /channels
# operationId: Get_Channels_
export def "channels get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --region: string # The region to get the channels for.
  --lang: string@lang-completer # The language for any applicable localised strings.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "region" $region "scalar") (serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"region": $region, "lang": $lang} | compact), body: null}
}

# Get broadcasts by channel
#
# GET /channels/{channel}/broadcasts
# operationId: Get_Broadcasts by channel_
export def "channels-broadcasts get" [
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list<string>@mixin-completer # Request additional data in the output
  --per-page: int # The number of results to return. (format: int64)
  --qp-from: string # Time to return results from, e.g. -3h
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($channel | is-empty) { error make --unspanned { msg: "path parameter 'channel' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "from" $qp_from "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel: (encode-path-segment $channel)} | format pattern "/channels/{channel}/broadcasts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "rights": $rights, "availability": $availability, "mixin": $mixin, "per_page": $per_page, "from": $qp_from} | compact), body: null}
}

# List the highlights for a channel.
#
# GET /channels/{channel}/highlights
# operationId: Get_Highlights by channel_
export def "channels-highlights get" [
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --live: oneof<nothing, bool> # Whether to include live programmes
  --mixin: list<string>@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($channel | is-empty) { error make --unspanned { msg: "path parameter 'channel' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "live" $live "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({channel: (encode-path-segment $channel)} | format pattern "/channels/{channel}/highlights") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "rights": $rights, "availability": $availability, "live": $live, "mixin": $mixin} | compact), body: null}
}

# Get programmes by channel
#
# GET /channels/{channel}/programmes
# operationId: Get_Programmes by channel_
export def "channels-programmes get" [
  channel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($channel | is-empty) { error make --unspanned { msg: "path parameter 'channel' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel: (encode-path-segment $channel)} | format pattern "/channels/{channel}/programmes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "rights": $rights, "availability": $availability, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get schedule by channel
#
# GET /channels/{channel}/schedule/{date}
# operationId: Get_Schedule by channel_
export def "channels-schedule get" [
  channel: string
  date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($channel | is-empty) { error make --unspanned { msg: "path parameter 'channel' must be non-empty" } }
  if ($date | is-empty) { error make --unspanned { msg: "path parameter 'date' must be non-empty" } }
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel: (encode-path-segment $channel), date: (encode-path-segment $date)} | format pattern "/channels/{channel}/schedule/{date}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "rights": $rights, "availability": $availability} | compact), body: null}
}

# Get Clips
#
# GET /clips/{pid}
# operationId: Get_Clips_
export def "clips get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/clips/{pid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "availability": $availability} | compact), body: null}
}

# Episode for a given pid.
#
# GET /episodes/{pid}
# operationId: Get_Programme by PID_
export def "episodes get-programme" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list<string>@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/episodes/{pid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "availability": $availability, "mixin": $mixin} | compact), body: null}
}

# Get Onward Journey
#
# GET /episodes/{pid}/next
# operationId: Get_Onward_Journey
export def "episodes-next get-onward-journey" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/episodes/{pid}/next") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "availability": $availability} | compact), body: null}
}

# Get Follow-ups (post-rolls)
#
# GET /episodes/{pid}/postrolls
# operationId: getPostRolls
export def "episodes-post-rolls get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/episodes/{pid}/postrolls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "availability": $availability} | compact), body: null}
}

# Get Trailers (pre-rolls)
#
# GET /episodes/{pid}/prerolls
# operationId: Get_Trailers (pre-rolls)_
export def "episodes-prerolls get-trailers-pre-rolls" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/episodes/{pid}/prerolls") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "availability": $availability} | compact), body: null}
}

# Get programme recommendations
#
# GET /episodes/{pid}/recommendations
# operationId: Get_Programme recommendations_
export def "episodes-recommendations get-programme" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/episodes/{pid}/recommendations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "availability": $availability, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Get programmes popular
#
# GET /groups/popular/episodes
# operationId: Get_Programmes popular_
export def "groups-popular-episodes get-programmes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
  --initial-child-count: int # The depth to return child entities. (default: 4)
  --qp-sort: string # The sort order of the results.
  --sort-direction: string@sort-direction-completer # Whether to sort ascending or descending
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list<string>@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/groups/popular/episodes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "page": $page, "per_page": $per_page, "initial_child_count": $initial_child_count, "sort": $qp_sort, "sort_direction": $sort_direction, "availability": $availability, "mixin": $mixin} | compact), body: null}
}

# Get episodes by group, brand or series
#
# GET /groups/{pid}/episodes
# operationId: Get_Episodes by group_
export def "groups-episodes get" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --page: int # The page index. (format: int64)
  --per-page: int # The number of results to return. (format: int64)
  --initial-child-count: int # The depth to return child entities. (default: 4)
  --qp-sort: string # The sort order of the results.
  --sort-direction: string@sort-direction-completer # Whether to sort ascending or descending
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list<string>@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "sort_direction" $sort_direction "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/groups/{pid}/episodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "page": $page, "per_page": $per_page, "initial_child_count": $initial_child_count, "sort": $qp_sort, "sort_direction": $sort_direction, "availability": $availability, "mixin": $mixin} | compact), body: null}
}

# Get programme highlights
#
# GET /home/highlights
# operationId: Get_Programme highlights_
export def "home-highlights get-programme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --mixin: list<string>@mixin-completer # Request additional data in the output
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "mixin" $mixin "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/home/highlights" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang, "rights": $rights, "availability": $availability, "mixin": $mixin} | compact), body: null}
}

# Programme for a given pid.
#
# GET /programmes/{pid}
# operationId: Get_Programmes by parent PID_
export def "programmes get-by-parent" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --initial-child-count: int # The depth to return child entities. (default: 4)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/programmes/{pid}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "availability": $availability, "initial_child_count": $initial_child_count} | compact), body: null}
}

# Child episodes for a given programme pid.
#
# GET /programmes/{pid}/episodes
# operationId: Get_Episodes by parent PID_
export def "programmes-episodes get-by-parent" [
  pid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
  --initial-child-count: int # The depth to return child entities. (default: 4)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  if ($pid | is-empty) { error make --unspanned { msg: "path parameter 'pid' must be non-empty" } }
  let qp = [(serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar") (serialize-qp "initial_child_count" $initial_child_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({pid: (encode-path-segment $pid)} | format pattern "/programmes/{pid}/episodes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"rights": $rights, "availability": $availability, "initial_child_count": $initial_child_count} | compact), body: null}
}

# List all regions
#
# GET /regions
# operationId: Get_Regions_
export def "regions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --lang: string@lang-completer # The language for any applicable localised strings.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "lang" $lang "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/regions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"lang": $lang} | compact), body: null}
}

# Get schema
#
# GET /schema/ibl.json
# operationId: Get_Schema_
export def "schema-ibl-json get" [
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
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/schema/ibl.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Search
#
# GET /search
# operationId: Search_
export def "search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The term to search for.
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "lang": $lang, "rights": $rights, "availability": $availability} | compact), body: null}
}

# Search-suggest
#
# GET /search-suggest
# operationId: Search-suggest_
export def "search-suggest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --q: string # The term to search for.
  --lang: string@lang-completer # The language for any applicable localised strings.
  --rights: string@rights-completer # The rights group to limit results to. (default: web)
  --availability: string@availability-completer # Whether to return all, or available programmes (default: available)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "lang" $lang "scalar") (serialize-qp "rights" $rights "scalar") (serialize-qp "availability" $availability "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search-suggest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"q": $q, "lang": $lang, "rights": $rights, "availability": $availability} | compact), body: null}
}

# Get status
#
# GET /status
# operationId: Get_Status_
export def "status get" [
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
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get user store purchases
#
# GET /user/purchases
# operationId: Get_User store purchases_
export def "user-purchases get-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-cookie: float # The BBC-id cookie value (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity_cookie" $identity_cookie "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/purchases" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"identity_cookie": $identity_cookie} | compact), body: null}
}

# Get user store recommendations
#
# GET /user/recommendations
# operationId: Get_User store recommendations_
export def "user-recommendations get-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-cookie: float # The BBC-id cookie value (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity_cookie" $identity_cookie "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/recommendations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"identity_cookie": $identity_cookie} | compact), body: null}
}

# Get user watching
#
# GET /user/watching
# operationId: Get_User watching_
export def "user-watching get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity-cookie: float # The BBC-id cookie value (format: double)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identity_cookie" $identity_cookie "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/watching" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"identity_cookie": $identity_cookie} | compact), body: null}
}
