# Auto-generated client for Discovery API vv2
# Source: https://api.apis.guru/v2/specs/ticketmaster.com/discovery/v2/openapi.json
# Auth: --token flag or $env.DISCOVERY_API_TOKEN

const BASE_URL = "http://localhost//www.ticketmaster.com/discovery/v2"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DISCOVERY_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost//www.ticketmaster.com/discovery/v2"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def source-completer [] { [" frontgate" " tmr" " universe" "ticketmaster"] }
def include-test-completer [] { [" no" " only" "yes"] }
def include-licensed-content-completer [] { [" no" "yes"] }
def include-spellcheck-completer [] { [" no" "yes"] }
def include-tba-completer [] { [" no" " only" "yes"] }
def include-tbd-completer [] { [" no" " only" "yes"] }
def unit-completer [] { ["km" "miles"] }
def include-fuzzy-completer [] { [" no" "yes"] }
def accept-completer [] { ["application/hal+json; charset=utf-8" "application/json; charset=utf-8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "discovery-attractions find" } } | get name | first)
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

# Attraction Search
#
# GET /discovery/v2/attractions
# operationId: find
export def "discovery-attractions find" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sorting order of the search result. Allowable Values : 'name,asc', 'name,desc', 'relevance,asc', 'relevance,desc' (default: relevance,desc, e.g. )
  --classification-name: list # Filter attractions by classification name: name of any segment, genre, sub-genre, type, sub-type (default: , e.g. )
  --classification-id: list # Filter attractions by classification id: id of any segment, genre, sub-genre, type, sub-type (default: , e.g. )
  --keyword: string # Keyword to search on (default: , e.g. )
  --id: string # Filter entities by its id (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --include-test: string@include-test-completer # True if you want to have entities flag as test in the response. Only, if you only wanted test entities (default: no, e.g. )
  --page: string # Page number (default: 0, e.g. )
  --size: string # Page size of the response (default: 20, e.g. )
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # Yes if you want to display licensed content (default: no, e.g. )
  --include-spellcheck: string@include-spellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "classificationName" $classification_name "multi") (serialize-qp "classificationId" $classification_id "multi") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "includeTest" $include_test "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar") (serialize-qp "includeSpellcheck" $include_spellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/attractions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "classificationName": $classification_name, "classificationId": $classification_id, "keyword": $keyword, "id": $id, "source": $qp_source, "includeTest": $include_test, "page": $page, "size": $size, "locale": $locale, "includeLicensedContent": $include_licensed_content, "includeSpellcheck": $include_spellcheck} | compact), body: null}
}

# Get Attraction Details
#
# GET /discovery/v2/attractions/{id}
# operationId: get
export def "discovery-attractions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/discovery/v2/attractions/{id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "includeLicensedContent": $include_licensed_content} | compact), body: null}
}

# Classification Search
#
# GET /discovery/v2/classifications
export def "discovery-classifications list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sorting order of the search result (default: name,asc, e.g. )
  --keyword: string # Keyword to search on (default: , e.g. )
  --id: string # Filter entities by its id (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --include-test: string@include-test-completer # True if you want to have entities flag as test in the response. Only, if you only wanted test entities (default: no, e.g. )
  --page: string # Page number (default: 0, e.g. )
  --size: string # Page size of the response (default: 20, e.g. )
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # Yes if you want to display licensed content (default: no, e.g. )
  --include-spellcheck: string@include-spellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "includeTest" $include_test "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar") (serialize-qp "includeSpellcheck" $include_spellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/classifications" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "keyword": $keyword, "id": $id, "source": $qp_source, "includeTest": $include_test, "page": $page, "size": $size, "locale": $locale, "includeLicensedContent": $include_licensed_content, "includeSpellcheck": $include_spellcheck} | compact), body: null}
}

# Get Genre Details
#
# GET /discovery/v2/classifications/genres/{id}
# operationId: getGenre
export def "discovery-classifications-genres get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/discovery/v2/classifications/genres/{id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "includeLicensedContent": $include_licensed_content} | compact), body: null}
}

# Get Segment Details
#
# GET /discovery/v2/classifications/segments/{id}
# operationId: getSegment
export def "discovery-classifications-segments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/discovery/v2/classifications/segments/{id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "includeLicensedContent": $include_licensed_content} | compact), body: null}
}

# Get Sub-Genre Details
#
# GET /discovery/v2/classifications/subgenres/{id}
# operationId: getSubgenre
export def "discovery-classifications-subgenres get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/discovery/v2/classifications/subgenres/{id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "includeLicensedContent": $include_licensed_content} | compact), body: null}
}

# Get Classification Details
#
# GET /discovery/v2/classifications/{id}
export def "discovery-classifications get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/discovery/v2/classifications/{id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "includeLicensedContent": $include_licensed_content} | compact), body: null}
}

# Event Search
#
# GET /discovery/v2/events
export def "discovery-events list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sorting order of the search result. Allowable values : 'name,asc', 'name,desc', 'date,asc', 'date,desc', 'relevance,asc', 'relevance,desc', 'distance,asc', 'name,date,asc', 'name,date,desc', 'date,name,asc', 'date,name,desc','onsaleStartDate,asc', 'id,asc' (default: relevance,desc, e.g. )
  --start-date-time: string # Filter events with a start date after this date (default: , e.g. )
  --end-date-time: string # Filter events with a start date before this date (default: , e.g. )
  --onsale-start-date-time: string # Filter events with onsale start date after this date (default: , e.g. )
  --onsale-on-start-date: string # Filter events with onsale start date on this date (default: , e.g. )
  --onsale-on-after-start-date: string # Filter events with onsale range within this date (default: , e.g. )
  --onsale-end-date-time: string # Filter events with onsale end date before this date (default: , e.g. )
  --city: string # Filter events by city (default: , e.g. )
  --country-code: string # Filter events by country code (default: , e.g. )
  --state-code: string # Filter events by state code (default: , e.g. )
  --postal-code: string # Filter events by postal code / zipcode (default: , e.g. )
  --venue-id: string # Filter events by venue id (default: , e.g. )
  --attraction-id: string # Filter events by attraction id (default: , e.g. )
  --segment-id: string # Filter events by segment id (default: , e.g. )
  --segment-name: string # Filter events by segment name (default: , e.g. )
  --classification-name: list # Filter events by classification name: name of any segment, genre, sub-genre, type, sub-type (default: , e.g. )
  --classification-id: list # Filter events by classification id: id of any segment, genre, sub-genre, type, sub-type (default: , e.g. )
  --market-id: string # Filter events by market id (default: , e.g. )
  --promoter-id: string # Filter events by promoter id (default: , e.g. )
  --dma-id: string # Filter events by dma id (default: , e.g. )
  --include-tba: string@include-tba-completer # True, to include events with date to be announce (TBA) (default: no if date parameter sent, yes otherwise, e.g. )
  --include-tbd: string@include-tbd-completer # True, to include event with a date to be defined (TBD) (default: no if date parameter sent, yes otherwise, e.g. )
  --client-visibility: string # Filter events by clientName (default: , e.g. )
  --latlong: string # Filter events by latitude and longitude, this filter is deprecated and maybe removed in a future release, please use geoPoint instead (default: , e.g. 33.80003000,-117.88304300)
  --radius: string # Radius of the area in which we want to search for events. (default: 50, e.g. )
  --unit: string@unit-completer # Unit of the radius (default: miles, e.g. )
  --geo-point: string # filter events by geoHash (default: , e.g. dr5rh)
  --keyword: string # Keyword to search on (default: , e.g. )
  --id: string # Filter entities by its id (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --include-test: string@include-test-completer # True if you want to have entities flag as test in the response. Only, if you only wanted test entities (default: no, e.g. )
  --page: string # Page number (default: 0, e.g. )
  --size: string # Page size of the response (default: 20, e.g. )
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # Yes if you want to display licensed content (default: no, e.g. )
  --include-spellcheck: string@include-spellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "startDateTime" $start_date_time "scalar") (serialize-qp "endDateTime" $end_date_time "scalar") (serialize-qp "onsaleStartDateTime" $onsale_start_date_time "scalar") (serialize-qp "onsaleOnStartDate" $onsale_on_start_date "scalar") (serialize-qp "onsaleOnAfterStartDate" $onsale_on_after_start_date "scalar") (serialize-qp "onsaleEndDateTime" $onsale_end_date_time "scalar") (serialize-qp "city" $city "scalar") (serialize-qp "countryCode" $country_code "scalar") (serialize-qp "stateCode" $state_code "scalar") (serialize-qp "postalCode" $postal_code "scalar") (serialize-qp "venueId" $venue_id "scalar") (serialize-qp "attractionId" $attraction_id "scalar") (serialize-qp "segmentId" $segment_id "scalar") (serialize-qp "segmentName" $segment_name "scalar") (serialize-qp "classificationName" $classification_name "multi") (serialize-qp "classificationId" $classification_id "multi") (serialize-qp "marketId" $market_id "scalar") (serialize-qp "promoterId" $promoter_id "scalar") (serialize-qp "dmaId" $dma_id "scalar") (serialize-qp "includeTBA" $include_tba "scalar") (serialize-qp "includeTBD" $include_tbd "scalar") (serialize-qp "clientVisibility" $client_visibility "scalar") (serialize-qp "latlong" $latlong "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "geoPoint" $geo_point "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "includeTest" $include_test "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar") (serialize-qp "includeSpellcheck" $include_spellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/events" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "startDateTime": $start_date_time, "endDateTime": $end_date_time, "onsaleStartDateTime": $onsale_start_date_time, "onsaleOnStartDate": $onsale_on_start_date, "onsaleOnAfterStartDate": $onsale_on_after_start_date, "onsaleEndDateTime": $onsale_end_date_time, "city": $city, "countryCode": $country_code, "stateCode": $state_code, "postalCode": $postal_code, "venueId": $venue_id, "attractionId": $attraction_id, "segmentId": $segment_id, "segmentName": $segment_name, "classificationName": $classification_name, "classificationId": $classification_id, "marketId": $market_id, "promoterId": $promoter_id, "dmaId": $dma_id, "includeTBA": $include_tba, "includeTBD": $include_tbd, "clientVisibility": $client_visibility, "latlong": $latlong, "radius": $radius, "unit": $unit, "geoPoint": $geo_point, "keyword": $keyword, "id": $id, "source": $qp_source, "includeTest": $include_test, "page": $page, "size": $size, "locale": $locale, "includeLicensedContent": $include_licensed_content, "includeSpellcheck": $include_spellcheck} | compact), body: null}
}

# Get Event Details
#
# GET /discovery/v2/events/{id}
export def "discovery-events get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/discovery/v2/events/{id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "includeLicensedContent": $include_licensed_content} | compact), body: null}
}

# Get Event Images
#
# GET /discovery/v2/events/{id}/images
# operationId: getImages
export def "discovery-events-images get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/discovery/v2/events/{id}/images") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "includeLicensedContent": $include_licensed_content} | compact), body: null}
}

# Find Suggest
#
# GET /discovery/v2/suggest
export def "discovery-suggest get" [
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
  --keyword: string # Keyword to search on (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --latlong: string # Filter events by latitude and longitude, this filter is deprecated and maybe removed in a future release, please use geoPoint instead (default: , e.g. 33.80003000,-117.88304300)
  --radius: string # Radius of the area in which we want to search for events. (default: 100, e.g. )
  --unit: string@unit-completer # Unit of the radius (default: miles, e.g. )
  --size: string # Size of every entity returned in the response (default: 5, e.g. )
  --include-fuzzy: string@include-fuzzy-completer # yes, to include fuzzy matches in the search. This has performance impact. (default: no, e.g. )
  --client-visibility: string # Filter events to clientName (default: , e.g. )
  --country-code: string # Filter suggestions by country code (default: , e.g. )
  --include-tba: string@include-tba-completer # True, to include events with date to be announce (TBA) (default: no if date parameter sent, yes otherwise, e.g. )
  --include-tbd: string@include-tbd-completer # True, to include event with a date to be defined (TBD) (default: no if date parameter sent, yes otherwise, e.g. )
  --segment-id: string # Filter suggestions by segment id (default: , e.g. )
  --geo-point: string # filter events by geoHash (default: , e.g. dr5rh)
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # Yes if you want to display licensed content (default: no, e.g. )
  --include-spellcheck: string@include-spellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "keyword" $keyword "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "latlong" $latlong "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "includeFuzzy" $include_fuzzy "scalar") (serialize-qp "clientVisibility" $client_visibility "scalar") (serialize-qp "countryCode" $country_code "scalar") (serialize-qp "includeTBA" $include_tba "scalar") (serialize-qp "includeTBD" $include_tbd "scalar") (serialize-qp "segmentId" $segment_id "scalar") (serialize-qp "geoPoint" $geo_point "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar") (serialize-qp "includeSpellcheck" $include_spellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/suggest" $qp)
  let accept_val = ($accept | default "application/hal+json; charset=utf-8")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"keyword": $keyword, "source": $qp_source, "latlong": $latlong, "radius": $radius, "unit": $unit, "size": $size, "includeFuzzy": $include_fuzzy, "clientVisibility": $client_visibility, "countryCode": $country_code, "includeTBA": $include_tba, "includeTBD": $include_tbd, "segmentId": $segment_id, "geoPoint": $geo_point, "locale": $locale, "includeLicensedContent": $include_licensed_content, "includeSpellcheck": $include_spellcheck} | compact), body: null}
}

# Venue Search
#
# GET /discovery/v2/venues
export def "discovery-venues list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sorting order of the search result. Allowable Values: 'name,asc', 'name,desc', 'relevance,asc', 'relevance,desc', 'distance,asc', 'distance,desc' (default: relevance,desc, e.g. )
  --state-code: string # Filter venues by state / province code (default: , e.g. )
  --country-code: string # Filter venues by country code (default: , e.g. )
  --latlong: string # Filter events by latitude and longitude, this filter is deprecated and maybe removed in a future release, please use geoPoint instead (default: , e.g. 33.80003000,-117.88304300)
  --radius: string # Radius of the area in which we want to search for events. (default: 50, e.g. )
  --unit: string@unit-completer # Unit of the radius (default: miles, e.g. )
  --geo-point: string # filter events by geoHash (default: , e.g. dr5rh)
  --keyword: string # Keyword to search on (default: , e.g. )
  --id: string # Filter entities by its id (default: , e.g. )
  --qp-source: string@source-completer # Filter entities by its source name (default: , e.g. )
  --include-test: string@include-test-completer # True if you want to have entities flag as test in the response. Only, if you only wanted test entities (default: no, e.g. )
  --page: string # Page number (default: 0, e.g. )
  --size: string # Page size of the response (default: 20, e.g. )
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # Yes if you want to display licensed content (default: no, e.g. )
  --include-spellcheck: string@include-spellcheck-completer # yes, to include spell check suggestions in the response. (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "stateCode" $state_code "scalar") (serialize-qp "countryCode" $country_code "scalar") (serialize-qp "latlong" $latlong "scalar") (serialize-qp "radius" $radius "scalar") (serialize-qp "unit" $unit "scalar") (serialize-qp "geoPoint" $geo_point "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "includeTest" $include_test "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar") (serialize-qp "includeSpellcheck" $include_spellcheck "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/discovery/v2/venues" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"sort": $qp_sort, "stateCode": $state_code, "countryCode": $country_code, "latlong": $latlong, "radius": $radius, "unit": $unit, "geoPoint": $geo_point, "keyword": $keyword, "id": $id, "source": $qp_source, "includeTest": $include_test, "page": $page, "size": $size, "locale": $locale, "includeLicensedContent": $include_licensed_content, "includeSpellcheck": $include_spellcheck} | compact), body: null}
}

# Get Venue Details
#
# GET /discovery/v2/venues/{id}
export def "discovery-venues get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The locale in ISO code format. Multiple comma-separated values can be provided. When omitting the country part of the code (e.g. only 'en' or 'fr') then the first matching locale is used. When using a '*' it matches all locales. '*' can only be used at the end (e.g. 'en-us,en,*') (default: en, e.g. en-us,en,fr)
  --include-licensed-content: string@include-licensed-content-completer # True if you want to display licensed content (default: no, e.g. )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "includeLicensedContent" $include_licensed_content "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/discovery/v2/venues/{id}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "includeLicensedContent": $include_licensed_content} | compact), body: null}
}
