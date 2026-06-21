# Auto-generated client for MotaWord API v1.0
# Source: https://api.apis.guru/v2/specs/motaword.com/1.0/openapi.json
# Auth: --token flag or $env.MOTAWORD_API_TOKEN

const BASE_URL = "https://api.motaword.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MOTAWORD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://api.motaword.com" "https://sandbox.motaword.com" "http://localhost"] }
def auth-scheme-completer [] { ["basic" "bearer" "none" "basic-credentials"] }

# Completers for enum parameters
def type-completer [] { ["active"] }
def type-filter-completer [] { ["ALL" "DESIGNS" "GLOSSARIES" "IMAGES" "LOCALIZATION" "PDFS" "PRESENTATIONS" "SPREADSHEETS" "STYLE_GUIDES" "SUBTITLES" "TEXT_DOCUMENTS" "WEB"] }
def order-by-completer [] { ["created_at" "id" "name" "updated_at"] }
def order-type-completer [] { ["asc" "desc"] }
def device-completer [] { ["Amazon" "Android" "Chrome" "Edge" "Firefox" "MacOS" "Safari" "Windows" "WindowsPhone" "iOS"] }
def type-completer-1 [] { ["OneSignal"] }
def order-by-completer-1 [] { ["delivery" "id" "price" "status"] }
def payment-method-completer [] { ["app" "client" "corporate" "corporate_card" "credit"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def type-completer-2 [] { ["EMAIL" "INCOMING_EMAIL" "NOTE" "TASK"] }
def accept-completer-1 [] { ["application/json" "application/xml"] }
def period-completer [] { ["monthly" "weekly"] }
def user-type-completer [] { ["all" "vendor"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "static get-endpoints" } } | get name | first)
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

# Available endpoints
#
# GET /
# operationId: getEndpoints
export def "static get-endpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download result of an async operation
#
# GET /async/download
# operationId: downloadAsync
export def "async-download download" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/async/download" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async_request_key": $async_request_key} | compact), body: null}
}

# Get blog posts - ordered by created desc by default
#
# GET /blogs
# operationId: getBlogPosts
export def "blogs get-posts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Article language, default `en`. When no blog article is available and `fallback=true` is specified, it falls back to `en`.
  --fallback: oneof<nothing, bool> # When `true`, and no article is found in the locale, it falls back to `locale=en`.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 1
]: nothing -> record<articles: table<announcement_type: string, author: string, content: string, created_at: string, excerpt: string, id: int, language: string, links: record, slug: string, title: string, topic: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "fallback" $fallback "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "fallback": $fallback, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Clear cache by key
#
# DELETE /cache/{key}
# operationId: deleteCache
export def "cache delete" [
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/cache/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a commission list of current client.
#
# GET /commissions
# operationId: getCommissions
export def "commissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commissions: table<amount: record, date: string, project: record, status: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a commission list of current client.
#
# POST /commissions
# operationId: getCommissionsByFilter
export def "commissions get-by-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<commissions: table<amount: record, date: string, project: record, status: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commissions")
  let req_body = {"budget_code": $budget_code, "date_from": $date_from, "date_to": $date_to, "source_languages": $source_languages, "target_languages": $target_languages, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View continuous projects
#
# GET /continuous_projects
# operationId: getContinuousProjects
export def "continuous-projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Type of continuous project. (nullable, default: active)
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record, target_languages: list, type: string, word_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/continuous_projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"type": $type} | compact), body: null}
}

# Create a continuous project
#
# POST /continuous_projects
# operationId: createContinuousProject
# --subscription shape: {downgrade?: list<string>, payment_method?: int, period_end?: string, plan_id?: string, plan_name?: string, price?: string, products?: list, schedule_name?: string, schedule_start?: string, subscription_id?: string, upgrade?: list<string>, withTrial?: any}
export def "continuous-projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --analytics-enabled: oneof<nothing, bool> # Should we collect analytics data from Active for this continuous project?
  --auto-start-postedit: oneof<nothing, bool> # Immediately start post-editing project for translation requests that are applied MT.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --id: int # format: int64
  --is-enabled: oneof<nothing, bool>
  --last-activity-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --links: any
  --mt-enabled: oneof<nothing, bool> # Immediately apply MT on translation requests if they are missing from TM.
  --mt-engine: string # One of "MOTAWORD", "GOOGLE", "AMAZON", "MS". Default is "MOTAWORD".
  --name: string
  --postedit-enabled: oneof<nothing, bool> # Get an instant quote for translation requests that are applied MT.
  --source-language: string
  --status: string # One of "a => ACTIVE", "i => INACTIVE", "d => DELETED", "c => SCHEDULED CANCELLATION", "p => SCHEDULED CHANGE"
  --subscription: record # shape: {downgrade?: list<string>, payment_method?: int, period_end?: string, plan_id?: string, plan_name?: string, price?: string, products?: list, schedule_name?: string, schedule_start?: string, subscription_id?: string, upgrade?: list<string>, withTrial?: any}
  --target-languages: list<string>
  --type: string # Continuous project type. We currently have only 2 types, NULL and "active".
  --word-count: int # format: int64
]: any -> record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/continuous_projects")
  let req_body = {"analytics_enabled": $analytics_enabled, "auto_start_postedit": $auto_start_postedit, "created_at": $created_at, "id": $id, "is_enabled": $is_enabled, "last_activity_at": $last_activity_at, "links": $links, "mt_enabled": $mt_enabled, "mt_engine": $mt_engine, "name": $name, "postedit_enabled": $postedit_enabled, "source_language": $source_language, "status": $status, "subscription": $subscription, "target_languages": $target_languages, "type": $type, "word_count": $word_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a continuous project
#
# DELETE /continuous_projects/{id}
# operationId: deleteContinuousProject
export def "continuous-projects delete" [
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a continuous project
#
# GET /continuous_projects/{id}
# operationId: getContinuousProject
export def "continuous-projects get" [
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
]: nothing -> record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a continuous project
#
# POST /continuous_projects/{id}
# operationId: updateContinuousProject
# --languages item shape: {code?: string, is_enabled?: bool}
export def "continuous-projects update" [
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
  --analytics-enabled: oneof<nothing, bool>
  --auto-start-postedit: oneof<nothing, bool>
  --is-enabled: oneof<nothing, bool>
  --languages: list # item shape: {code?: string, is_enabled?: bool}
  --mt-enabled: oneof<nothing, bool>
  --name: string
  --postedit-enabled: oneof<nothing, bool>
]: any -> record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}"))
  let req_body = {"analytics_enabled": $analytics_enabled, "auto_start_postedit": $auto_start_postedit, "is_enabled": $is_enabled, "languages": $languages, "mt_enabled": $mt_enabled, "name": $name, "postedit_enabled": $postedit_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get JWT token to be used in analytics dashboards
#
# GET /continuous_projects/{id}/analytics-token
# operationId: getAnalyticsToken
export def "continuous-projects-analytics-token get" [
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
]: nothing -> record<jwt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/analytics-token"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Save/collect analytics data from Active widget
#
# POST /continuous_projects/{id}/collect-analytics
# operationId: collectAnalytics
export def "continuous-projects-collect-analytics create" [
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
  --anonymous-id: string
  --properties: record
  --session-id: string
  --type: string
  --user-id: string
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/collect-analytics"))
  let req_body = {"anonymousId": $anonymous_id, "properties": $properties, "sessionId": $session_id, "type": $type, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Complete continuous project
#
# POST /continuous_projects/{id}/complete
# operationId: complete
export def "continuous-projects-complete complete" [
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/complete"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get quote for documents
#
# POST /continuous_projects/{id}/documents/quote
# operationId: getQuoteForDocuments
export def "continuous-projects-documents-quote get-by-id" [
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
  --files: list<int>
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/documents/quote"))
  let req_body = {"files": $files} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Complete a continuous project document
#
# POST /continuous_projects/{id}/documents/{documentId}/complete
# operationId: completeContinuousDocument
export def "continuous-projects-documents-complete complete" [
  id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), document_id: (encode-path-segment $document_id)} | format pattern "/continuous_projects/{id}/documents/{document_id}/complete"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a quote for a continuous project document
#
# POST /continuous_projects/{id}/documents/{documentId}/quote
# operationId: getQuoteForDocument
export def "continuous-projects-documents-quote get-by-id-document-id" [
  id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), document_id: (encode-path-segment $document_id)} | format pattern "/continuous_projects/{id}/documents/{document_id}/quote"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get quote for languages
#
# POST /continuous_projects/{id}/languages/quote
# operationId: getQuoteForLanguages
export def "continuous-projects-languages-quote get-by-id" [
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
  --languages: list<string>
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/languages/quote"))
  let req_body = {"languages": $languages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Complete continuous project language
#
# POST /continuous_projects/{id}/languages/{targetLanguage}/complete
# operationId: completeLanguage
export def "continuous-projects-languages-complete complete" [
  id: int
  target_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($target_language | is-empty) { error make --unspanned { msg: "path parameter 'targetLanguage' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), target_language: (encode-path-segment $target_language)} | format pattern "/continuous_projects/{id}/languages/{target_language}/complete"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get quote for language
#
# POST /continuous_projects/{id}/languages/{targetLanguage}/quote
# operationId: getQuoteForLanguage
export def "continuous-projects-languages-quote get-by-id-target-language" [
  id: int
  target_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($target_language | is-empty) { error make --unspanned { msg: "path parameter 'targetLanguage' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), target_language: (encode-path-segment $target_language)} | format pattern "/continuous_projects/{id}/languages/{target_language}/quote"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete subscription for continuous project
#
# DELETE /continuous_projects/{id}/subscription
# operationId: deleteSubscription
export def "continuous-projects-subscription delete" [
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
]: nothing -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/subscription"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get subscription for continuous project
#
# GET /continuous_projects/{id}/subscription
# operationId: getSubscription
export def "continuous-projects-subscription get" [
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
]: nothing -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/subscription"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create subscription for continuous project
#
# POST /continuous_projects/{id}/subscription
# operationId: createSubscription
export def "continuous-projects-subscription create" [
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
  --downgrade: list<string> # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list<string> # Stripe upgradable plan
  --with-trial: any # Stripe plan trial (format: boolean)
]: any -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/subscription"))
  let req_body = {"downgrade": $downgrade, "payment_method": $payment_method, "period_end": $period_end, "plan_id": $plan_id, "plan_name": $plan_name, "price": $price, "products": $products, "schedule_name": $schedule_name, "schedule_start": $schedule_start, "subscription_id": $subscription_id, "upgrade": $upgrade, "withTrial": $with_trial} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update subscription for continuous project
#
# PUT /continuous_projects/{id}/subscription
# operationId: updateSubscription
export def "continuous-projects-subscription update" [
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
  --downgrade: list<string> # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list<string> # Stripe upgradable plan
  --with-trial: any # Stripe plan trial (format: boolean)
]: any -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/subscription"))
  let req_body = {"downgrade": $downgrade, "payment_method": $payment_method, "period_end": $period_end, "plan_id": $plan_id, "plan_name": $plan_name, "price": $price, "products": $products, "schedule_name": $schedule_name, "schedule_start": $schedule_start, "subscription_id": $subscription_id, "upgrade": $upgrade, "withTrial": $with_trial} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update subscription payment method for continuous project
#
# PUT /continuous_projects/{id}/subscription/payment
# operationId: updateSubscriptionPaymentMethod
export def "continuous-projects-subscription-payment update-method" [
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
  --downgrade: list<string> # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list<string> # Stripe upgradable plan
  --with-trial: any # Stripe plan trial (format: boolean)
]: any -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/continuous_projects/{id}/subscription/payment"))
  let req_body = {"downgrade": $downgrade, "payment_method": $payment_method, "period_end": $period_end, "plan_id": $plan_id, "plan_name": $plan_name, "price": $price, "products": $products, "schedule_name": $schedule_name, "schedule_start": $schedule_start, "subscription_id": $subscription_id, "upgrade": $upgrade, "withTrial": $with_trial} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Instantly translate your content
#
# POST /continuous_projects/{id}/translate/{targetLanguage}
# operationId: translate
# --documents item shape: {data?: string, name?: string}
# --filters shape: {skipMt?: list<string>, skipPostEdit?: list<string>}
export def "continuous-projects-translate create" [
  id: int
  target_language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contents: list<string> # Simple list of strings to be translated. You can also choose to upload files instead of strings.
  --documents: list # You can add as many files as you want in documents parameter. — item shape: {data?: string, name?: string}
  --filters: record # shape: {skipMt?: list<string>, skipPostEdit?: list<string>}
  --meta: record # Free-form meta data to attach to your instant translation request. This can be used in statistics and analytical dashboards.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($target_language | is-empty) { error make --unspanned { msg: "path parameter 'targetLanguage' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), target_language: (encode-path-segment $target_language)} | format pattern "/continuous_projects/{id}/translate/{target_language}"))
  let req_body = {"contents": $contents, "documents": $documents, "filters": $filters, "meta": $meta} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View continuous documents
#
# GET /continuous_projects/{projectId}/documents
# operationId: getContinuousProjectDocuments
export def "continuous-projects-documents list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-by-language: string
]: nothing -> record<documents: table<billed_word_count: int, id: string, links: record, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "filterByLanguage" $filter_by_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filterByLanguage": $filter_by_language} | compact), body: null}
}

# Add a new document to your continuous project
#
# POST /continuous_projects/{projectId}/documents
# operationId: addDocument
# --document shape: {data?: string, name?: string}
export def "continuous-projects-documents create" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: record # shape: {data?: string, name?: string}
]: any -> record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/documents"))
  let req_body = {"document": $document} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get continuous project document progress for multiple IDs
#
# POST /continuous_projects/{projectId}/documents/progress
# operationId: postContinuousProjectDocumentProgress
export def "continuous-projects-documents-progress create" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-name: string
  --filter-by-language: string
]: any -> record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/documents/progress"))
  let req_body = {"documentName": $document_name, "filterByLanguage": $filter_by_language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of strings and its translations in the project.
#
# POST /continuous_projects/{projectId}/documents/strings
# operationId: postContinuousProjectFileStrings
export def "continuous-projects-documents-strings create-file" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document-name: string
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/documents/strings"))
  let req_body = {"documentName": $document_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}
# operationId: getContinuousProjectDocument
export def "continuous-projects-documents get" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/continuous_projects/{project_id}/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update the document
#
# POST /continuous_projects/{projectId}/documents/{documentId}
# operationId: updateDocument
# --document shape: {data?: string, name?: string}
export def "continuous-projects-documents update" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: record # shape: {data?: string, name?: string}
]: any -> record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/continuous_projects/{project_id}/documents/{document_id}"))
  let req_body = {"document": $document} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Monitor progress of a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}/progress
# operationId: getContinuousProjectDocumentProgress
export def "continuous-projects-documents-progress get" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-by-language: string
]: nothing -> record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let qp = [(serialize-qp "filterByLanguage" $filter_by_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/continuous_projects/{project_id}/documents/{document_id}/progress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filterByLanguage": $filter_by_language} | compact), body: null}
}

# View strings their translations in a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}/strings
# operationId: getContinuousProjectFileStrings
export def "continuous-projects-documents-strings get-file" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/continuous_projects/{project_id}/documents/{document_id}/strings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Invoices of a continuous project
#
# GET /continuous_projects/{projectId}/invoices
# operationId: getContinuousProjectInvoices
export def "continuous-projects-invoices get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<invoices: table<amount: float, base_amount: float, base_currency: string, billing: record, currency: string, id: int, invoice_no: int, invoiced_at: string, links: record, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/invoices"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Monitor progress and status of a continous project
#
# GET /continuous_projects/{projectId}/progress
# operationId: getContinuousProjectProgress
export def "continuous-projects-progress get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter-by-language: string
]: nothing -> record<costs: record<mt: record<amount: float, currency: string>, post_edit: record<amount: float, currency: string>, saved: record<amount: float, currency: string>, total: record<amount: float, currency: string>>, progress: record<languages: record, links: record<self: record, project: record>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>, word_counts: record<mt: int, post_edit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "filterByLanguage" $filter_by_language "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/progress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"filterByLanguage": $filter_by_language} | compact), body: null}
}

# View strings and translations in continuous project
#
# GET /continuous_projects/{projectId}/strings
# operationId: getContinuousProjectStrings
export def "continuous-projects-strings get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/strings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Clear translation cache
#
# DELETE /continuous_projects/{projectId}/strings/cached
# operationId: clearTranslationCache
export def "continuous-projects-strings-cached delete-clear-translation-cache" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale
  --file-id: int # Continuous Project File ID (format: int64)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/strings/cached") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "file_id": $file_id} | compact), body: null}
}

# View cached strings translations in continuous project
#
# GET /continuous_projects/{projectId}/strings/cached
# operationId: getTranslationCache
export def "continuous-projects-strings-cached get-translation-cache" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # Flatten cache results and ignore document keys (default: 1)
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/strings/cached") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"flatten": $flatten} | compact), body: null}
}

# Recache translations
#
# POST /continuous_projects/{projectId}/strings/recache-tms
# operationId: recacheTranslations
export def "continuous-projects-strings-recache-tms create-translations" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale
  --file-id: int # Continuous Project File ID (format: int64)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/strings/recache-tms") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"locale": $locale, "file_id": $file_id} | compact), body: null}
}

# View Active widgets
#
# GET /continuous_projects/{projectId}/widgets
# operationId: getActiveWidgets
export def "continuous-projects-widgets list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, widgets: table<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/widgets"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a new Active widget
#
# POST /continuous_projects/{projectId}/widgets
# operationId: createActiveWidget
export def "continuous-projects-widgets create-active" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website.
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --variables: string # Continuous project variable definitions
]: any -> record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/continuous_projects/{project_id}/widgets"))
  let req_body = {"allow_hash_in_url": $allow_hash_in_url, "allow_query_in_url": $allow_query_in_url, "auto_detect_source_language": $auto_detect_source_language, "created_at": $created_at, "elements": $elements, "follow_user": $follow_user, "force_cache_refresh_interval": $force_cache_refresh_interval, "id": $id, "language_mappings": $language_mappings, "live": $live, "modify_links": $modify_links, "name": $name, "optimize_per_page": $optimize_per_page, "pages": $pages, "path_regex": $path_regex, "position": $position, "query_name": $query_name, "reboot_on_url_change": $reboot_on_url_change, "restricted_domains": $restricted_domains, "sections": $sections, "test_mode": $test_mode, "theme": $theme, "token": $body_token, "url_change_mode": $url_change_mode, "url_mode": $url_mode, "use_cache": $use_cache, "use_dummy_translations": $use_dummy_translations, "variables": $variables} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a single widget for this Active project
#
# DELETE /continuous_projects/{projectId}/widgets/{widgetId}
# operationId: deleteActiveWidget
export def "continuous-projects-widgets delete-active" [
  project_id: int
  widget_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($widget_id | is-empty) { error make --unspanned { msg: "path parameter 'widgetId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), widget_id: (encode-path-segment $widget_id)} | format pattern "/continuous_projects/{project_id}/widgets/{widget_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View an Active widget
#
# GET /continuous_projects/{projectId}/widgets/{widgetId}
# operationId: getActiveWidget
export def "continuous-projects-widgets get-active" [
  project_id: int
  widget_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($widget_id | is-empty) { error make --unspanned { msg: "path parameter 'widgetId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), widget_id: (encode-path-segment $widget_id)} | format pattern "/continuous_projects/{project_id}/widgets/{widget_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update Active widget settings.
#
# POST /continuous_projects/{projectId}/widgets/{widgetId}
# operationId: updateActiveWidget
export def "continuous-projects-widgets update-active" [
  project_id: int
  widget_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website.
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --variables: string # Continuous project variable definitions
]: any -> record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($widget_id | is-empty) { error make --unspanned { msg: "path parameter 'widgetId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), widget_id: (encode-path-segment $widget_id)} | format pattern "/continuous_projects/{project_id}/widgets/{widget_id}"))
  let req_body = {"allow_hash_in_url": $allow_hash_in_url, "allow_query_in_url": $allow_query_in_url, "auto_detect_source_language": $auto_detect_source_language, "created_at": $created_at, "elements": $elements, "follow_user": $follow_user, "force_cache_refresh_interval": $force_cache_refresh_interval, "id": $id, "language_mappings": $language_mappings, "live": $live, "modify_links": $modify_links, "name": $name, "optimize_per_page": $optimize_per_page, "pages": $pages, "path_regex": $path_regex, "position": $position, "query_name": $query_name, "reboot_on_url_change": $reboot_on_url_change, "restricted_domains": $restricted_domains, "sections": $sections, "test_mode": $test_mode, "theme": $theme, "token": $body_token, "url_change_mode": $url_change_mode, "url_mode": $url_mode, "use_cache": $use_cache, "use_dummy_translations": $use_dummy_translations, "variables": $variables} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reset Active widget token
#
# POST /continuous_projects/{projectId}/widgets/{widgetId}/reset-token
# operationId: resetActiveWidgetToken
export def "continuous-projects-widgets-reset-token reset-active" [
  project_id: int
  widget_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($widget_id | is-empty) { error make --unspanned { msg: "path parameter 'widgetId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), widget_id: (encode-path-segment $widget_id)} | format pattern "/continuous_projects/{project_id}/widgets/{widget_id}/reset-token"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your corporate account
#
# GET /corporate
# operationId: getCorporate
export def "corporate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View available permissions
#
# GET /corporate/permissions
# operationId: getAvailableCorporatePermissions
export def "corporate-permissions get-available" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View user groups
#
# GET /corporate/user-groups
# operationId: getCorporateUserGroups
export def "corporate-user-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/user-groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a corporate user group
#
# POST /corporate/user-groups
# operationId: saveCorporateUserGroup
export def "corporate-user-groups create-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --corporate-id: int # format: int64
  --id: int # format: int64
  --name: string
  --permissions: list<string>
]: any -> record<corporate_id: int, id: int, name: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/user-groups")
  let req_body = {"corporate_id": $corporate_id, "id": $id, "name": $name, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View users
#
# GET /corporate/users
# operationId: getCorporateUsers
export def "corporate-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a user
#
# POST /corporate/users
# operationId: saveCorporateUser
# --notifications shape: {phone_number?: string, sms_enabled?: bool}
export def "corporate-users create-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list<int> # A list of user group IDs
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/users")
  let req_body = {"city": $city, "country": $country, "phone": $phone, "state": $state, "street": $street, "zip": $zip, "birthday": $birthday, "email": $email, "first_name": $first_name, "id": $id, "last_name": $last_name, "notifications": $notifications, "notify": $notify, "paypal_email": $paypal_email, "require_1099": $require_1099, "user_groups": $user_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of corporate accounts
#
# GET /corporates/all
# operationId: getCorporatesList
export def "corporates-all get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporates/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get details of this corporate account
#
# GET /corporates/{corporateId}
# operationId: getCorporateById
export def "corporates get" [
  corporate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($corporate_id | is-empty) { error make --unspanned { msg: "path parameter 'corporateId' must be non-empty" } }
  let full_url = (build-url $base ({corporate_id: (encode-path-segment $corporate_id)} | format pattern "/corporates/{corporate_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of available permissions for this corporate account. They are used when assigning permissions to corporate users.
#
# GET /corporates/{corporateId}/permissions
# operationId: getAvailableCorporatePermissionsById
export def "corporates-permissions get-available" [
  corporate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($corporate_id | is-empty) { error make --unspanned { msg: "path parameter 'corporateId' must be non-empty" } }
  let full_url = (build-url $base ({corporate_id: (encode-path-segment $corporate_id)} | format pattern "/corporates/{corporate_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of user groups for this corporate account
#
# GET /corporates/{corporateId}/user-groups
# operationId: getCorporateUserGroupsById
export def "corporates-user-groups get" [
  corporate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($corporate_id | is-empty) { error make --unspanned { msg: "path parameter 'corporateId' must be non-empty" } }
  let full_url = (build-url $base ({corporate_id: (encode-path-segment $corporate_id)} | format pattern "/corporates/{corporate_id}/user-groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update a corporate user group for this corporate account
#
# POST /corporates/{corporateId}/user-groups
# operationId: saveCorporateUserGroupById
export def "corporates-user-groups create-save" [
  corporate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-corporate-id: int # format: int64
  --id: int # format: int64
  --name: string
  --permissions: list<string>
]: any -> record<corporate_id: int, id: int, name: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($corporate_id | is-empty) { error make --unspanned { msg: "path parameter 'corporateId' must be non-empty" } }
  let full_url = (build-url $base ({corporate_id: (encode-path-segment $corporate_id)} | format pattern "/corporates/{corporate_id}/user-groups"))
  let req_body = {"corporate_id": $body_corporate_id, "id": $id, "name": $name, "permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of users for this corporate account
#
# GET /corporates/{corporateId}/users
# operationId: getCorporateUsersById
export def "corporates-users get" [
  corporate_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($corporate_id | is-empty) { error make --unspanned { msg: "path parameter 'corporateId' must be non-empty" } }
  let full_url = (build-url $base ({corporate_id: (encode-path-segment $corporate_id)} | format pattern "/corporates/{corporate_id}/users"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete your account
#
# DELETE /delete-account
# operationId: deleteAccount
export def "delete-account delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/delete-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your documents
#
# GET /documents
# operationId: getDocuments
export def "documents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recent: oneof<nothing, bool> # When true, this will return the most 4 recent active documents. (default: 0)
  --search: string
  --type-filter: string@type-filter-completer # default: ALL
  --language-code: string # searches in source language of documents, in source and target languages of document's quote
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --order-by: string@order-by-completer # default: updated_at
  --order-type: string@order-type-completer
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recent" $recent "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "type_filter" $type_filter "scalar") (serialize-qp "language_code" $language_code "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_type" $order_type "scalar") (serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"recent": $recent, "search": $search, "type_filter": $type_filter, "language_code": $language_code, "page": $page, "per_page": $per_page, "order_by": $order_by, "order_type": $order_type, "with[]": $with} | compact), body: null}
}

# Get a list of subjects of projects
#
# GET /documents/subjects
# operationId: getAllDocumentSubjects
export def "documents-subjects get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents/subjects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a single document
#
# GET /documents/{documentId}
# operationId: getDocument
export def "documents get" [
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a document translation progress
#
# GET /documents/{documentId}/progress
# operationId: getDocumentProgress
export def "documents-progress get" [
  document_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/progress"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Regenerate preview and return preview URL for given file
#
# POST /documents/{documentId}/regenerate_preview
# operationId: regeneratePreview
export def "documents-regenerate-preview create" [
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<link: record<href: string>, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/regenerate_preview"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Find documents similar to this document.
#
# GET /documents/{documentId}/similars
# operationId: getSimilarDocuments
export def "documents-similars get" [
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Determines the number of similar documents to return. (format: int64, default: 1)
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/similars") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"per_page": $per_page, "with[]": $with} | compact), body: null}
}

# Use the translation of given source manual document as manual draft source for the given target document.
#
# POST /documents/{documentId}/use_as_draft
# operationId: useAsDraft
export def "documents-use-as-draft create" [
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-file-id: float
  --from-manual-translation-file-id: float
  --to-manual-translation-file-id: float
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/use_as_draft"))
  let req_body = {"fromFileId": $from_file_id, "fromManualTranslationFileId": $from_manual_translation_file_id, "toManualTranslationFileId": $to_manual_translation_file_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Use the translation of the given manual document as a regular file.
#
# POST /documents/{documentId}/use_as_regular
# operationId: useAsRegular
export def "documents-use-as-regular create" [
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-original-file-preview: oneof<nothing, bool>
  --allow-review-in-manual-editor: oneof<nothing, bool>
  --disable-invitations: oneof<nothing, bool>
  --from-manual-translation-file-id: float
  --hide-numbers: oneof<nothing, bool>
  --recreate: oneof<nothing, bool>
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}/use_as_regular"))
  let req_body = {"allowOriginalFilePreview": $allow_original_file_preview, "allowReviewInManualEditor": $allow_review_in_manual_editor, "disableInvitations": $disable_invitations, "fromManualTranslationFileId": $from_manual_translation_file_id, "hideNumbers": $hide_numbers, "recreate": $recreate} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /downgrade-proofreader
#
# operationId: downgradeProofreader
export def "downgrade-proofreader create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/downgrade-proofreader")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your vendor earnings
#
# GET /earnings
# operationId: getEarnings
export def "earnings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completed: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, ongoing: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/earnings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List of supported file formats
#
# GET /formats
# operationId: getFormats
export def "formats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/formats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Freeze account
#
# POST /freeze-account
# operationId: freezeAccount
export def "freeze-account create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/freeze-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download account glossary.
#
# GET /glossary
# operationId: downloadGlobalGlossary
export def "glossary download-global" [
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
  let full_url = (build-url $base "/glossary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update the account glossary
#
# POST /glossary
# operationId: updateGlobalGlossary
export def "glossary update-global" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  glossary: string # Glossary file. Currently supported formats: .xlsx, .tbx (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/glossary")
  let req_body = {"glossary": $glossary} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate a new access token for MotaWord's integrations service
#
# GET /integrations/token
# operationId: getIntegrationsToken
export def "integrations-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get vendor list for compiled invitation needs
#
# POST /invitation/vendors
# operationId: getInvitationVendors
export def "invitation-vendors get" [
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
]: any -> record<vendors: table<matchedNeeds: list, userId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invitation/vendors")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else if (($input | is-not-empty) and ($req_body | is-empty)) { $input } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# List of supported languages
#
# GET /languages
# operationId: getLanguages
export def "languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "none"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Log user's current location. This data is used in our Intelligent Project Manager for various data analysis, including project prioritization for vendors and account validation.
#
# POST /location
# operationId: logLocation
export def "location create-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  lat: float # Latitude of location (format: float)
  lon: float # Longitude of location (format: float)
  --timestamp: int
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/location")
  let req_body = {"lat": $lat, "lon": $lon, "timestamp": $timestamp} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /make-proofreader
#
# operationId: makeProofreader
export def "make-proofreader create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/make-proofreader")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your account info
#
# GET /me
# operationId: getMe
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update your account info
#
# POST /me
# operationId: updateMe
# --notifications shape: {phone_number?: string, sms_enabled?: bool}
export def "me update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list<int> # A list of user group IDs
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let req_body = {"city": $city, "country": $country, "phone": $phone, "state": $state, "street": $street, "zip": $zip, "birthday": $birthday, "email": $email, "first_name": $first_name, "id": $id, "last_name": $last_name, "notifications": $notifications, "notify": $notify, "paypal_email": $paypal_email, "require_1099": $require_1099, "user_groups": $user_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a delivery prediction for a project
#
# POST /ml/delivery-prediction
# operationId: getDeliveryPrediction
export def "ml-delivery-prediction get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --project-id: int # format: int64
]: any -> record<result: table<language: string, late: bool, probability: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ml/delivery-prediction")
  let req_body = {"projectId": $project_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Subscribe to push notifications
#
# POST /notifications/subscribe
# operationId: subscribeNotification
export def "notifications-subscribe subscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/subscribe")
  let req_body = {"device": $device, "endpoint": $endpoint, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /notifications/unsubscribe
#
# operationId: unsubscribeNotification
export def "notifications-unsubscribe unsubscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/unsubscribe")
  let req_body = {"device": $device, "endpoint": $endpoint, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sends a message to chat
#
# POST /pam/chat
# operationId: postMessage
export def "pam-chat create-message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # the message to be sent
  --recipients: list<string> # name of the recipients in the channel
  --slots: list<string> # contexts for next message
  --thread-id: string # id of the thread
  --thread-key: string # the key for thread_id default is project
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pam/chat")
  let req_body = {"message": $message, "recipients": $recipients, "slots": $slots, "thread_id": $thread_id, "thread_key": $thread_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get the Pam profile of a client for this client ID
#
# GET /pam/profiles/client/{clientId}
# operationId: getClientProfileForPam
export def "pam-profiles-client get" [
  client_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_creation_date: string, client_project_count: float, corporate: string, corporate_id: float, corporate_user_count: float, frequent_file_extension: string, frequent_language_pairs: list<string>, full_name: string, growth: bool, is_complex: bool, last_12_months_spending: float, last_project: float, last_project_time: string, last_proofreaders: table<full_name: string, id: float, language: string, vendor_link: string>, notes: list<string>, nps: record<average: record<completed_surveys_count: float, score: float>, last: record<completion_date: string, score: float>>, user_rank_in_project_count: float, user_rank_in_spending: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($client_id | is-empty) { error make --unspanned { msg: "path parameter 'clientId' must be non-empty" } }
  let full_url = (build-url $base ({client_id: (encode-path-segment $client_id)} | format pattern "/pam/profiles/client/{client_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get completion report data of a project
#
# GET /pam/projects/{projectId}/completion-report
# operationId: getProjectCompletionReportForPam
export def "pam-projects-completion-report get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_user_id: float, completion_report_data: table<invited_vendors: list, target_language: string>, id: float, quote_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/pam/projects/{project_id}/completion-report"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update your account password
#
# POST /password
# operationId: updatePassword
export def "password update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # New Password
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/password")
  let req_body = {"password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View your payment and billing info
#
# GET /payment
# operationId: getPaymentInfo
export def "payment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update payment info
#
# POST /payment
# operationId: updatePaymentInfo
export def "payment update-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --bin: string
  --save-as-corporate-primary: oneof<nothing, bool>
  --share-with-corporate-users: oneof<nothing, bool>
  --stripe-token: string
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment")
  let req_body = {"city": $city, "country": $country, "phone": $phone, "state": $state, "street": $street, "zip": $zip, "bin": $bin, "save_as_corporate_primary": $save_as_corporate_primary, "share_with_corporate_users": $share_with_corporate_users, "stripeToken": $stripe_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Reset payment code
#
# POST /payment/reset-corporate-payment-code
# operationId: resetCorporatePaymentCode
export def "payment-reset-corporate-payment-code reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bin: string, id: int, is_default: bool, payment_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment/reset-corporate-payment-code")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Manage automatic charges on your credit card
#
# POST /payment/toggle-corporate-auto-charge
# operationId: toggleCorporateAutoCharge
export def "payment-toggle-corporate-auto-charge create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment/toggle-corporate-auto-charge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View saved credit card
#
# GET /payment/{cardId}
# operationId: getCreditCard
export def "payment get-credit-card" [
  card_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bin: string, id: int, is_default: bool, payment_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'cardId' must be non-empty" } }
  let full_url = (build-url $base ({card_id: (encode-path-segment $card_id)} | format pattern "/payment/{card_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete credit card
#
# DELETE /payment/{cardId}/delete
# operationId: deleteCreditCard
export def "payment-delete delete-credit-card" [
  card_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'cardId' must be non-empty" } }
  let full_url = (build-url $base ({card_id: (encode-path-segment $card_id)} | format pattern "/payment/{card_id}/delete"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Reset credit card payment code
#
# POST /payment/{cardId}/reset-payment-code
# operationId: resetCardPaymentCode
export def "payment-reset-payment-code reset-card" [
  card_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bin: string, id: int, is_default: bool, payment_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($card_id | is-empty) { error make --unspanned { msg: "path parameter 'cardId' must be non-empty" } }
  let full_url = (build-url $base ({card_id: (encode-path-segment $card_id)} | format pattern "/payment/{card_id}/reset-payment-code"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your permissions
#
# GET /permissions
# operationId: getPermissions
export def "permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload profile picture
#
# POST /profile-picture
# operationId: uploadProfilePicture
export def "profile-picture upload" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  profile_picture: string # Profile picture file contents. Accepted extensions are png, jpg. (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile-picture")
  let req_body = {"profile_picture": $profile_picture} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View your translation projects
#
# GET /projects
# operationId: getProjects
@deprecated --flag with-pending
@deprecated --flag with-started
@deprecated --flag with-completed
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --status: list # Filter projects by status. Accepts multiple statuses. Possible values 'pending', 'started', 'completed'
  --with-pending: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --with-started: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --with-completed: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --order-by: string@order-by-completer-1 # default: id
  --order-type: string@order-type-completer
  --with: list<string> # Include detailed information. Possible values 'client', 'vendor'
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status[]" $status "multi") (serialize-qp "with_pending" $with_pending "scalar") (serialize-qp "with_started" $with_started "scalar") (serialize-qp "with_completed" $with_completed "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_type" $order_type "scalar") (serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page, "status[]": $status, "with_pending": $with_pending, "with_started": $with_started, "with_completed": $with_completed, "order_by": $order_by, "order_type": $order_type, "with[]": $with} | compact), body: null}
}

# Create a new project
#
# POST /projects
# operationId: createProject
export def "projects create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Optional. If you provide a callback URL, we will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
  --coupon-code: string # Coupon code to redeem
  --custom: list<string> # Optional. This is a consistent custom data parameter that will be given to you in the response across every request of this project model. Values should be provided like this, custom[my_key] = my_value.
  --documents: string # Optional. You can add as many files as you want in documents[] parameter. Or you add your documents later in separate calls. (format: binary)
  --glossaries: string # Optional. Only one glossary is supported at the moment. (format: binary)
  --source-language: string
  --styleguides: string # Optional. You can add as many files as you want in styleguides[] parameter. Or you add your style guides later in separate calls. (format: binary)
  --target-languages: list<string>
]: any -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let req_body = {"callback_url": $callback_url, "coupon_code": $coupon_code, "custom": $custom, "documents[]": $documents, "glossaries[]": $glossaries, "source_language": $source_language, "styleguides[]": $styleguides, "target_languages[]": $target_languages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Quote Id
#
# GET /projects/from-internal-id/{projectId}
# operationId: getQuoteIdFromInternalId
export def "projects-from-internal-id get-quote" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<internal_id: int, public_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/from-internal-id/{project_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# List projects as a vendor
#
# GET /projects/vendor
# operationId: getVendorProjects
export def "projects-vendor get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --joined: oneof<nothing, bool> # Return only projects that this user has already joined
  --completed: oneof<nothing, bool> # Return only projects that have been completed. When `true`, this makes `joined` true as well.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "joined" $joined "scalar") (serialize-qp "completed" $completed "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/vendor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"joined": $joined, "completed": $completed, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Delete your translation project
#
# DELETE /projects/{id}
# operationId: deleteProject
export def "projects delete" [
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a translation project
#
# GET /projects/{id}
# operationId: getProject
export def "projects get" [
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
  --with: list<string> # Include detailed information. Possible values 'client', 'vendor', 'score'
]: nothing -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"with[]": $with} | compact), body: null}
}

# Update project info and settings
#
# PUT /projects/{id}
# operationId: updateProject
export def "projects update" [
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
  --callback-url: string # Optional. If you provide a callback URL, we will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
  --coupon-code: string # Coupon code to redeem
  --custom: list<string> # Optional. This is a consistent custom data parameter that will be given to you in the response across every request of this project model. Values should be provided like this, custom[my_key] = my_value. If you previously provided one, it will be replaced.
  --source-language: string
  --target-languages: list<string>
]: any -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}"))
  let req_body = {"callback_url": $callback_url, "coupon_code": $coupon_code, "custom": $custom, "source_language": $source_language, "target_languages[]": $target_languages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Assign a CM to the project
#
# POST /projects/{id}/assign-cm
# operationId: assignCM
export def "projects-assign-cm assign" [
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
  --user-id: int # format: int64
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/assign-cm"))
  let req_body = {"user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Trigger a call to your callback URL related to this project.
#
# GET /projects/{id}/callback/{actionType}
# operationId: triggerCallback
export def "projects-callback trigger" [
  id: int
  action_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list<record>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record, documents: record, glossaries: record, payment: record, quote_pdf: record, styleguides: record>, pairs: list<record>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>, result: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($action_type | is-empty) { error make --unspanned { msg: "path parameter 'actionType' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), action_type: (encode-path-segment $action_type)} | format pattern "/projects/{id}/callback/{action_type}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Cancel your translation project
#
# POST /projects/{id}/cancel
# operationId: cancelProject
export def "projects-cancel cancel" [
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
  --reason: string # Cancellation reason
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/cancel"))
  let req_body = {"reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Deliver project
#
# POST /projects/{id}/deliver
# operationId: deliverProject
export def "projects-deliver create" [
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/deliver"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download your translated project
#
# GET /projects/{id}/download
# operationId: download
export def "projects-download list" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/download"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download your translated project language
#
# GET /projects/{id}/download/{language}
# operationId: downloadLanguage
export def "projects-download download" [
  id: int
  language: string
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), language: (encode-path-segment $language)} | format pattern "/projects/{id}/download/{language}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Send a quote email
#
# POST /projects/{id}/email-quote
# operationId: sendQuoteEmail
export def "projects-email-quote send" [
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/email-quote"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View project invoice
#
# GET /projects/{id}/invoice
# operationId: getInvoice
export def "projects-invoice get" [
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
]: nothing -> record<amount: float, base_amount: float, base_currency: string, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, currency: string, id: int, invoice_no: int, invoiced_at: string, links: record<self: record<href: string>, corporate: record<href: string>, html: record<href: string>, json: record<href: string>, pdf: record<href: string>, project: record<href: string>, view: record<href: string>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/invoice"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download project invoice (HTML)
#
# GET /projects/{id}/invoice.html
# operationId: downloadHtmlInvoice
export def "projects-invoice-html download" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/invoice.html"))
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download project invoice (PDF)
#
# GET /projects/{id}/invoice.pdf
# operationId: downloadPdfInvoice
export def "projects-invoice-pdf download" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/invoice.pdf"))
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Launch your translation project
#
# POST /projects/{id}/launch
# operationId: launchProject
export def "projects-launch create" [
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
  --bin: string # Last 4 digits of the credit card you are using one-time. This parameter is only required when stripe_token is provided.
  --budget-code: string # Optional with corporate accounts. Not available for others.
  --card-id: int # Optional. `client`, `app`, `corporate_card` methods require a credit card ID. `credit` method requires Stripe token and bin. (format: int64)
  --payment-code: string # Optional. `corporate` payment method requires this.s
  --payment-method: string@payment-method-completer # Optional. Determines which method to use for payment. `client`, `app`, `corporate_card` methods require a credit card ID. `credit` method requires Stripe token and bin. `corporate` method follows corporate account policy automatically, either follows invoicing flow or automatically charges corporate's primary card.
  --stripe-token: string # This is required if you are using a one-time credit card. This is the token generted from frontend via Stripe SDK. If you are using a one-time card with `stripe_token`, you must also provide `bin`, last 4 digits of the card.
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/launch"))
  let req_body = {"bin": $bin, "budget_code": $budget_code, "card_id": $card_id, "payment_code": $payment_code, "payment_method": $payment_method, "stripe_token": $stripe_token} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Package your translated project
#
# POST /projects/{id}/package
# operationId: package
export def "projects-package create-by-id" [
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
  --async: int # If you want to package and download the translation synchronously, mark this parameter as '0'. It will package the translation and then return the packaged file in the response, identical to /download call after an asynchronous /package call. (format: int64, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/package") $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async": $async} | compact), body: null}
}

# Track translation packaging status
#
# GET /projects/{id}/package/check
# operationId: trackPackage
export def "projects-package-check get-track" [
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
  --key: string # This is the package tracking key provided in the response of a /package call.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/package/check") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"key": $key} | compact), body: null}
}

# Package your translated project language
#
# POST /projects/{id}/package/{language}
# operationId: packageLanguage
export def "projects-package create-by-id-language" [
  id: int
  language: string
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
  --async: int # If you want to package and download the translation synchronously, mark this parameter as '0'. It will package the translation and then return the packaged file in the response, identical to /download call after an asynchronous /package call. (format: int64, default: 0)
]: nothing -> record<status: string, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), language: (encode-path-segment $language)} | format pattern "/projects/{id}/package/{language}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async": $async} | compact), body: null}
}

# View progress of a project
#
# GET /projects/{id}/progress
# operationId: getProgress
export def "projects-progress get" [
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
  --qp-raw: oneof<nothing, bool> # This will return a more raw progress information for translation and proofreading. For instance, when completed, we will return 100% for both tasks by default, whereas their actual progress may be lower than 100%. (default: false)
]: nothing -> record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/progress") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"raw": $qp_raw} | compact), body: null}
}

# Recreate your translation project from scratch. This is a risky action, you will lose current translations.
#
# POST /projects/{id}/recreate
# operationId: recreateProject
export def "projects-recreate create" [
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/recreate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Submit feedback report for a project
#
# POST /projects/{id}/reports
# operationId: submitProjectReports
export def "projects-reports submit" [
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
  --activity-type: string # Activity Type
  --message: string # Report Message
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/reports"))
  let req_body = {"activity_type": $activity_type, "message": $message} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get sales activities for a project
#
# GET /projects/{id}/sales/activities
# operationId: getSalesActivities
export def "projects-sales-activities get" [
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
  --exclude-owner: string
  --type: string@type-completer-2
]: nothing -> record<activities: table<body: string, created_at: int, created_by: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "excludeOwner" $exclude_owner "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/sales/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"excludeOwner": $exclude_owner, "type": $type} | compact), body: null}
}

# Insert sales activity for a project
#
# POST /projects/{id}/sales/activities
# operationId: insertSalesActivity
export def "projects-sales-activities create-activity" [
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
  --subject: string
  --timestamp: int # format: int64
  --type: string # Activity Type
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/sales/activities"))
  let req_body = {"subject": $subject, "timestamp": $timestamp, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete project webhooks
#
# DELETE /projects/{id}/webhooks
# operationId: deleteProjectWebhook
export def "projects-webhooks delete" [
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
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/webhooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View project webhooks
#
# GET /projects/{id}/webhooks
# operationId: getProjectWebhooks
export def "projects-webhooks get" [
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
]: nothing -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/webhooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update project webhook
#
# POST /projects/{id}/webhooks
# operationId: postProjectWebhook
export def "projects-webhooks create" [
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
  --callback-url: string # Webhook URL. We will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
]: any -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/webhooks"))
  let req_body = {"callback_url": $callback_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update project webhook
#
# PUT /projects/{id}/webhooks
# operationId: updateProjectWebhook
export def "projects-webhooks update" [
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
  --callback-url: string # Webhook URL. We will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
]: any -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/projects/{id}/webhooks"))
  let req_body = {"callback_url": $callback_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Monitor project activities
#
# GET /projects/{projectId}/activities
# operationId: getActivities
export def "projects-activities get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<activities: table<activity_at: int, id: int, links: record, source_text: string, target_text: string, translator: int, type: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/activities") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# View an activity
#
# GET /projects/{projectId}/activities/{activityId}
# operationId: getActivity
export def "projects-activities get-activity" [
  project_id: int
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
]: nothing -> record<activity_at: int, id: int, links: record<self: record<href: string>, comments: record<href: string>, project: record<href: string>>, source_text: string, target_text: string, translator: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), activity_id: (encode-path-segment $activity_id)} | format pattern "/projects/{project_id}/activities/{activity_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Submit comment to an activity
#
# POST /projects/{projectId}/activities/{activityId}
# operationId: submitComment
export def "projects-activities submit-comment" [
  project_id: int
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
  comment: string # Comment text.
  --commented-at: int # Unix epoch time (format: int64)
  --id: int # format: int64
  --links: any
]: any -> record<comment: string, commented_at: int, id: int, links: record<self: record<href: string>, activity: record<href: string>, project: record<href: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), activity_id: (encode-path-segment $activity_id)} | format pattern "/projects/{project_id}/activities/{activity_id}"))
  let req_body = {"comment": $comment, "commented_at": $commented_at, "id": $id, "links": $links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View activity comments
#
# GET /projects/{projectId}/activities/{activityId}/comments
# operationId: getActivityComments
export def "projects-activities-comments get-activity" [
  project_id: int
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
]: nothing -> record<activities: table<comment: string, commented_at: int, id: int, links: record>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($activity_id | is-empty) { error make --unspanned { msg: "path parameter 'activityId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), activity_id: (encode-path-segment $activity_id)} | format pattern "/projects/{project_id}/activities/{activity_id}/comments"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View all project comments
#
# GET /projects/{projectId}/comments
# operationId: getComments
export def "projects-comments get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<activities: table<comment: string, commented_at: int, id: int, links: record>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/comments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page} | compact), body: null}
}

# View project source documents
#
# GET /projects/{projectId}/documents
# operationId: getProjectDocuments
export def "projects-documents list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"with[]": $with} | compact), body: null}
}

# Upload a new document
#
# POST /projects/{projectId}/documents
# operationId: createProjectDocument
# --source-links[] item shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
export def "projects-documents create" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list<string> # You can add as many files as you want in documents[] parameter.
  --schemes: string # JSON string. If your documents have a scheme, as in cases of CSV files, use the same array index keys for `schemes` parameter to specify their schemes. See `Document Schemes` title in the API documentation.
  --source-links: list # When provided, we will download the files from these URLs, in addition to files provded in `documents` parameter and then save as source documents — item shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
]: any -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/documents"))
  let req_body = {"documents[]": $documents, "schemes[]": $schemes, "source-links[]": $source_links} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete the document
#
# DELETE /projects/{projectId}/documents/{documentId}
# operationId: deleteProjectDocument
export def "projects-documents delete" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/projects/{project_id}/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a project source document
#
# GET /projects/{projectId}/documents/{documentId}
# operationId: getProjectDocument
export def "projects-documents get" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<file_type: string, has_custom_package: bool, id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, manual_files: table<driveFileId: int, isProofread: bool, isTranslated: bool, language: string, proofreadingFileId: int, translationFileId: int>, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list<string>, uploaded_at: int, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/projects/{project_id}/documents/{document_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"with[]": $with} | compact), body: null}
}

# Update the document.
#
# POST /projects/{projectId}/documents/{documentId}
# operationId: updateProjectDocument
# --source-link shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
export def "projects-documents update" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: string # Single file data. The name is plural to provide a consistent naming convention. (format: binary)
  --schemes: string # JSON string. If your documents have a scheme, as in cases of CSV files, use the same array index keys for `schemes` parameter to specify their schemes. See `Document Schemes` title in the API documentation.
  --source-link: record # shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
]: any -> record<file_type: string, has_custom_package: bool, id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, manual_files: table<driveFileId: int, isProofread: bool, isTranslated: bool, language: string, proofreadingFileId: int, translationFileId: int>, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list<string>, uploaded_at: int, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/projects/{project_id}/documents/{document_id}"))
  let req_body = {"documents": $documents, "schemes": $schemes, "source-link": $source_link} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download a project source document
#
# GET /projects/{projectId}/documents/{documentId}/download
# operationId: downloadProjectDocument
export def "projects-documents-download download" [
  project_id: int
  document_id: int
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
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/projects/{project_id}/documents/{document_id}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View strings and translations of a document
#
# GET /projects/{projectId}/documents/{documentId}/translations
# operationId: getDocumentTranslations
export def "projects-documents-translations list" [
  project_id: int
  document_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id)} | format pattern "/projects/{project_id}/documents/{document_id}/translations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download translated document
#
# GET /projects/{projectId}/documents/{documentId}/translations/download/{language}
# operationId: downloadTranslatedDocumentForLanguage
export def "projects-documents-translations-download download-translated" [
  project_id: int
  document_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --certified: oneof<nothing, bool> # Download certified translation (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let qp = [(serialize-qp "certified" $certified "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id), language: (encode-path-segment $language)} | format pattern "/projects/{project_id}/documents/{document_id}/translations/download/{language}") $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"certified": $certified} | compact), body: null}
}

# View strings and translations of a document for target language
#
# GET /projects/{projectId}/documents/{documentId}/translations/{language}
# operationId: getDocumentTranslationsForLanguage
export def "projects-documents-translations get" [
  project_id: int
  document_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), document_id: (encode-path-segment $document_id), language: (encode-path-segment $language)} | format pattern "/projects/{project_id}/documents/{document_id}/translations/{language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View glossaries
#
# GET /projects/{projectId}/glossaries
# operationId: getGlossaries
export def "projects-glossaries get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<glossaries: table<id: int, links: record, name: string, uploaded_at: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/glossaries"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Upload a glossary file
#
# POST /projects/{projectId}/glossaries
# operationId: createGlossary
export def "projects-glossaries create-glossary" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  glossaries: string # You can only add one glossary, even though the name suggests multiple glossaries. This may be updated in the future to support multiple glossaries. (format: binary)
]: any -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/glossaries"))
  let req_body = {"glossaries": $glossaries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a glossary
#
# DELETE /projects/{projectId}/glossaries/{glossaryId}
# operationId: deleteGlossary
export def "projects-glossaries delete-glossary" [
  project_id: int
  glossary_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($glossary_id | is-empty) { error make --unspanned { msg: "path parameter 'glossaryId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), glossary_id: (encode-path-segment $glossary_id)} | format pattern "/projects/{project_id}/glossaries/{glossary_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a glossary
#
# GET /projects/{projectId}/glossaries/{glossaryId}
# operationId: getGlossary
export def "projects-glossaries get-glossary" [
  project_id: int
  glossary_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($glossary_id | is-empty) { error make --unspanned { msg: "path parameter 'glossaryId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), glossary_id: (encode-path-segment $glossary_id)} | format pattern "/projects/{project_id}/glossaries/{glossary_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a glossary
#
# PUT /projects/{projectId}/glossaries/{glossaryId}
# operationId: updateGlossary
export def "projects-glossaries update-glossary" [
  project_id: int
  glossary_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  glossaries: string # You can only add one glossary, even though the name suggests multiple glossaries. This may be updated in the future to support multiple glossaries. (format: binary)
]: any -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($glossary_id | is-empty) { error make --unspanned { msg: "path parameter 'glossaryId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), glossary_id: (encode-path-segment $glossary_id)} | format pattern "/projects/{project_id}/glossaries/{glossary_id}"))
  let req_body = {"glossaries": $glossaries} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download a glossary
#
# GET /projects/{projectId}/glossaries/{glossaryId}/download
# operationId: downloadGlossary
export def "projects-glossaries-download download-glossary" [
  project_id: int
  glossary_id: int
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
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($glossary_id | is-empty) { error make --unspanned { msg: "path parameter 'glossaryId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), glossary_id: (encode-path-segment $glossary_id)} | format pattern "/projects/{project_id}/glossaries/{glossary_id}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View project strings and translations
#
# GET /projects/{projectId}/strings
# operationId: getProjectStrings
export def "projects-strings list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/strings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Download project translation memory
#
# POST /projects/{projectId}/strings/package
# operationId: packageProjectTranslationMemory
export def "projects-strings-package create-translation-memory" [
  project_id: int
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
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --format: string # Translation Memory file format (default: tmx)
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "async" $async "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/strings/package") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async": $async, "format": $format} | compact), body: null}
}

# Check translation memory packaging status
#
# GET /projects/{projectId}/strings/package/status
# operationId: packageProjectTranslationMemoryStatus
export def "projects-strings-package-status get-translation-memory" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/strings/package/status") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async_request_key": $async_request_key} | compact), body: null}
}

# Download language-specific project translation memory
#
# POST /projects/{projectId}/strings/{languageCode}/package
# operationId: packageProjectTranslationMemoryForLanguage
export def "projects-strings-package create-translation-memory-for-language" [
  project_id: int
  language_code: string
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
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --format: string # Translation Memory file format (default: tmx)
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($language_code | is-empty) { error make --unspanned { msg: "path parameter 'languageCode' must be non-empty" } }
  let qp = [(serialize-qp "async" $async "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), language_code: (encode-path-segment $language_code)} | format pattern "/projects/{project_id}/strings/{language_code}/package") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async": $async, "format": $format} | compact), body: null}
}

# Check language-specific translation memory packaging status
#
# GET /projects/{projectId}/strings/{languageCode}/package/status
# operationId: packageProjectTranslationMemoryForLanguageStatus
export def "projects-strings-package-status get-translation-memory-for-language" [
  project_id: int
  language_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($language_code | is-empty) { error make --unspanned { msg: "path parameter 'languageCode' must be non-empty" } }
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), language_code: (encode-path-segment $language_code)} | format pattern "/projects/{project_id}/strings/{language_code}/package/status") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async_request_key": $async_request_key} | compact), body: null}
}

# View strings and translations for target language
#
# GET /projects/{projectId}/strings/{language}
# operationId: getProjectStringsForLanguage
export def "projects-strings get" [
  project_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), language: (encode-path-segment $language)} | format pattern "/projects/{project_id}/strings/{language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View style guides
#
# GET /projects/{projectId}/styleguides
# operationId: getStyleGuides
export def "projects-styleguides get-style-guides" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, styleguides: table<id: int, links: record, name: string, uploaded_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/styleguides") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"with[]": $with} | compact), body: null}
}

# Upload a new style guide
#
# POST /projects/{projectId}/styleguides
# operationId: createStyleGuide
export def "projects-styleguides create-style-guide" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguides: string # You can only add one style guide, even though the name suggests multiple style guides. This may be updated in the future to support multiple style guides. (format: binary)
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, styleguides: table<id: int, links: record, name: string, uploaded_at: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/styleguides"))
  let req_body = {"styleguides": $styleguides} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a style guide
#
# DELETE /projects/{projectId}/styleguides/{styleGuideId}
# operationId: deleteStyleGuide
export def "projects-styleguides delete-style-guide" [
  project_id: int
  style_guide_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($style_guide_id | is-empty) { error make --unspanned { msg: "path parameter 'styleGuideId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), style_guide_id: (encode-path-segment $style_guide_id)} | format pattern "/projects/{project_id}/styleguides/{style_guide_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View a style guide
#
# GET /projects/{projectId}/styleguides/{styleGuideId}
# operationId: getStyleGuide
export def "projects-styleguides get-style-guide" [
  project_id: int
  style_guide_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($style_guide_id | is-empty) { error make --unspanned { msg: "path parameter 'styleGuideId' must be non-empty" } }
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), style_guide_id: (encode-path-segment $style_guide_id)} | format pattern "/projects/{project_id}/styleguides/{style_guide_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"with[]": $with} | compact), body: null}
}

# Update a style guide
#
# PUT /projects/{projectId}/styleguides/{styleGuideId}
# operationId: updateStyleGuide
export def "projects-styleguides update-style-guide" [
  project_id: int
  style_guide_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguides: string # You can only add one style guide, even though the name suggests multiple style guides. This may be updated in the future to support multiple style guides. (format: binary)
]: any -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($style_guide_id | is-empty) { error make --unspanned { msg: "path parameter 'styleGuideId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), style_guide_id: (encode-path-segment $style_guide_id)} | format pattern "/projects/{project_id}/styleguides/{style_guide_id}"))
  let req_body = {"styleguides": $styleguides} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download a style guide
#
# GET /projects/{projectId}/styleguides/{styleGuideId}/download
# operationId: downloadStyleGuide
export def "projects-styleguides-download download-style-guide" [
  project_id: int
  style_guide_id: int
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
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($style_guide_id | is-empty) { error make --unspanned { msg: "path parameter 'styleGuideId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), style_guide_id: (encode-path-segment $style_guide_id)} | format pattern "/projects/{project_id}/styleguides/{style_guide_id}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deprecated. Use /projects/{projectId}/strings instead.
#
# GET /projects/{projectId}/translations
# DEPRECATED
# operationId: getProjectTranslations
@deprecated
export def "projects-translations list" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/translations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Deprecated. use /projects/{projectId}/strings/{language} instead.
#
# GET /projects/{projectId}/translations/{language}
# DEPRECATED
# operationId: getProjectTranslationsForLanguage
@deprecated
export def "projects-translations get" [
  project_id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  if ($language | is-empty) { error make --unspanned { msg: "path parameter 'language' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id), language: (encode-path-segment $language)} | format pattern "/projects/{project_id}/translations/{language}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of vendors.
#
# GET /projects/{projectId}/vendors
# operationId: getProjectVendors
export def "projects-vendors get" [
  project_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($project_id | is-empty) { error make --unspanned { msg: "path parameter 'projectId' must be non-empty" } }
  let full_url = (build-url $base ({project_id: (encode-path-segment $project_id)} | format pattern "/projects/{project_id}/vendors"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns available options for selected timeframe.
#
# POST /reports/filter
# operationId: getFilterContents
export def "reports-filter get-contents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
]: any -> record<budget_codes: list<string>, categories: list<string>, clients: table<id: int, name: string>, documents: table<id: int, name: string>, projects: table<id: int, name: string>, severities: list<string>, source_languages: list<string>, subjects: list<string>, target_languages: list<string>, vendors: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/filter")
  let req_body = {"date_from": $date_from, "date_to": $date_to} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Language pairs report
#
# POST /reports/language-pairs
# operationId: getLanguagePairsReport
export def "reports-language-pairs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, report: table<language_pair: record, spending: float, word_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/language-pairs")
  let req_body = {"budget_code": $budget_code, "date_from": $date_from, "date_to": $date_to, "source_languages": $source_languages, "target_languages": $target_languages, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Projects report
#
# POST /reports/projects
# operationId: getProjectsReport
export def "reports-projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/projects")
  let req_body = {"budget_code": $budget_code, "date_from": $date_from, "date_to": $date_to, "source_languages": $source_languages, "target_languages": $target_languages, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Generate a QA report for given filter
#
# POST /reports/qa
# operationId: generateQAReport
export def "reports-qa generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-codes: list<string>
  --categories: list<string>
  --clients: list<float>
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --documents: list<float>
  --projects: list<float>
  --severities: list<string>
  --source-languages: list<string>
  --subjects: list<string>
  --target-languages: list<string>
  --vendors: list<float>
]: any -> record<report: table<category: string, comment: string, docId: string, editorLink: string, end: int, inSource: bool, isCurrent: bool, module: string, projectId: record, severity: string, source: string, sourceLanguage: record, start: int, state: string, targetLanguage: record, translation: string, uniqueKey: string, vendor: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/qa")
  let req_body = {"budget_codes": $budget_codes, "categories": $categories, "clients": $clients, "date_from": $date_from, "date_to": $date_to, "documents": $documents, "projects": $projects, "severities": $severities, "source_languages": $source_languages, "subjects": $subjects, "target_languages": $target_languages, "vendors": $vendors} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Company users report
#
# POST /reports/users
# operationId: getUsersReport
export def "reports-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, report: table<currency: string, spending: float, user: record, word_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/users")
  let req_body = {"budget_code": $budget_code, "date_from": $date_from, "date_to": $date_to, "source_languages": $source_languages, "target_languages": $target_languages, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sends email confirmation email for current user
#
# POST /resend-email-confirmation
# operationId: sendEmailConfirmation
export def "resend-email-confirmation send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resend-email-confirmation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your vendor responsiveness
#
# GET /responsivity
# operationId: getResponsivity
export def "responsivity get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # Time period to calculate your responsiveness (default: monthly)
]: nothing -> record<links: record<self: record<href: string>>, responsivity: table<invited: int, month: string, notEntered: int, onlyEntered: int, score: float, week: string, worked: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/responsivity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"period": $period} | compact), body: null}
}

# Search everything in your account
#
# GET /search
# operationId: searchEverywhere
export def "search list-everywhere" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --query: string # Search query term
  --include: list<string> # Search in these entities. Current oprions are projects, documents, strings. Can be multiple. When not provided, we'll search through all entities.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, result: record<documents: list<record>, projects: list<record>, strings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $query "scalar") (serialize-qp "include[]" $include "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"query": $query, "include[]": $include, "page": $page, "per_page": $per_page} | compact), body: null}
}

# Reindex for search all of the client source and translation documents.
#
# POST /search/documents/reindex
# operationId: reindexDocuments
export def "search-documents-reindex create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/documents/reindex")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check reindex status of the client source and translation documents.
#
# GET /search/documents/reindex/status
# operationId: checkDocumentsReindex
export def "search-documents-reindex-status check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/documents/reindex/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async_request_key": $async_request_key} | compact), body: null}
}

# View your account statistics
#
# GET /stats
# operationId: getStats
export def "stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client: record<document_count: int, nps: float, started_project_count: int, total_discounted: record<amount: float, currency: string>, total_project_count: int, total_spending: float, translator_count: int>, vendor: record<earnings: record<total: float>, projects: record<invited: int, total: int, worked: int>, words: record<approved: int, translated: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the total commissions stats.
#
# GET /stats/commissions
# operationId: getCommissionStats
export def "stats-commissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balance: record<amount: float, currency: string>, paid: record<amount: float, currency: string>, quote_total: record<amount: float, currency: string>, total: record<amount: float, currency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/commissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the total commissions stats by report filter.
#
# POST /stats/commissions
# operationId: getCommissionStatsByFilter
export def "stats-commissions get-by-filter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list<string> # List of source language codes.
  --target-languages: list<string> # List of target language codes.
  --users: list<int> # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<balance: record<amount: float, currency: string>, paid: record<amount: float, currency: string>, quote_total: record<amount: float, currency: string>, total: record<amount: float, currency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/commissions")
  let req_body = {"budget_code": $budget_code, "date_from": $date_from, "date_to": $date_to, "source_languages": $source_languages, "target_languages": $target_languages, "users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View your popular language pairs
#
# GET /stats/popular-pairs
# operationId: getPopularPairs
export def "stats-popular-pairs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pairs: table<source_language: string, target_language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/popular-pairs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your project statistics
#
# GET /stats/projects
# operationId: getProjectStats
export def "stats-projects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stats: table<languages: list, month: string, number_of_projects: int, total_spending: float, week: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your translation statistics
#
# GET /stats/strings
# operationId: getStringStats
export def "stats-strings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<language_counts: table<project_string_count: int, source_language: string, tm_string_count: int>, total_project_strings_count: int, total_tm_strings_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/strings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View account strings (translation memory)
#
# GET /strings
# operationId: getStrings
export def "strings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language: string # Source Language Code
  --page: int # Requested page (format: int64, default: 0)
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, strings: table<content: string, language: string, last_changed: string, translations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_language" $source_language "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/strings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"source_language": $source_language, "page": $page} | compact), body: null}
}

# Translate Strings with MT
#
# POST /strings
# DEPRECATED
# operationId: postStrings
@deprecated
export def "strings create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --contents: list<string>
  --source-language: string
  --target-languages: list<string>
]: any -> record<cost: record<amount: float, currency: string>, strings: table<content: string, language: string, last_changed: string, translations: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/strings")
  let req_body = {"contents": $contents, "source_language": $source_language, "target_languages": $target_languages} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update string translation
#
# PUT /strings
# operationId: updateTranslationMemoryUnit
export def "strings update-translation-memory-unit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language: string
  --source-text: string
  --target-language: string
  --target-text: string
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/strings")
  let req_body = {"sourceLanguage": $source_language, "sourceText": $source_text, "targetLanguage": $target_language, "targetText": $target_text} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Download account translation memory
#
# POST /strings/{languageCode}/package
# operationId: packageUserTranslationMemory
export def "strings-package create-user-translation-memory" [
  language_code: string
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
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --email: int # If you don't need us to email the TMX, set this to '0'. Default is 1. (format: int64, default: 1)
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_code | is-empty) { error make --unspanned { msg: "path parameter 'languageCode' must be non-empty" } }
  let qp = [(serialize-qp "async" $async "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({language_code: (encode-path-segment $language_code)} | format pattern "/strings/{language_code}/package") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async": $async, "email": $email} | compact), body: null}
}

# Check account translation memory packaging status
#
# GET /strings/{languageCode}/package/status
# operationId: packageUserTranslationMemoryForLanguageStatus
export def "strings-package-status get-user-translation-memory-for-language" [
  language_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($language_code | is-empty) { error make --unspanned { msg: "path parameter 'languageCode' must be non-empty" } }
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({language_code: (encode-path-segment $language_code)} | format pattern "/strings/{language_code}/package/status") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"async_request_key": $async_request_key} | compact), body: null}
}

# Download account style guide
#
# GET /styleguide
# operationId: downloadGlobalStyleGuide
export def "styleguide download-global-style-guide" [
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
  let full_url = (build-url $base "/styleguide")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or update the account style guide
#
# POST /styleguide
# operationId: updateGlobalStyleGuide
export def "styleguide update-global-style-guide" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguide: string # Style guide file. Currently supported formats: .pdf, .docx, .txt (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/styleguide")
  let req_body = {"styleguide": $styleguide} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get survey questions in given scope and type
#
# GET /surveys/{scope}/{type}
# operationId: getQuestions
export def "surveys get-questions" [
  scope: string
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
  --attach-answers-for-project: int # Project ID (format: int64)
]: nothing -> table<answers: list<record>, question: record<enabled: bool, format: string, id: int, question: string, text: string>, question_answers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let qp = [(serialize-qp "attach_answers_for_project" $attach_answers_for_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope), type: (encode-path-segment $type)} | format pattern "/surveys/{scope}/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"attach_answers_for_project": $attach_answers_for_project} | compact), body: null}
}

# Post survey answers for scope and type
#
# POST /surveys/{scope}/{type}
# operationId: submitAnswers
# --answers item shape: {answer?: string, project_id?: int, question_answer_id?: int, question_id?: int, user_id?: int}
export def "surveys submit-answers" [
  scope: string
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
  --answers: list # item shape: {answer?: string, project_id?: int, question_answer_id?: int, question_id?: int, user_id?: int}
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($scope | is-empty) { error make --unspanned { msg: "path parameter 'scope' must be non-empty" } }
  if ($type | is-empty) { error make --unspanned { msg: "path parameter 'type' must be non-empty" } }
  let full_url = (build-url $base ({scope: (encode-path-segment $scope), type: (encode-path-segment $type)} | format pattern "/surveys/{scope}/{type}"))
  let req_body = {"answers": $answers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# OpenAPI YAML representation of our API
#
# GET /swagger
# operationId: getSwaggerYaml
export def "swagger get-yaml" [
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
  let full_url = (build-url $base "/swagger")
  let accept_val = "text/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieve an access token
#
# POST /token
# operationId: getAccessToken
export def "token get-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string # OAuth2 grant type. Supports 'client_credentials', 'password', 'refresh_token' or 'user_id'.
  --password: string # MW Account password (to be used in password grant type)
  --refresh-token: string # Refresh token value for refresh token flow.
  scope: string # Authorization scope. Use 'privileged' for private endpoints.
  --user-id: int # Value for user_id grant type flow. (format: int64)
  --username: string # MW Account email (to be used in password grant type)
]: any -> record<access_token: string, expires_in: int, refresh_token: string, scope: string, token_type: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token")
  let req_body = {"grant_type": $grant_type, "password": $password, "refresh_token": $refresh_token, "scope": $scope, "user_id": $user_id, "username": $username} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Defreeze your account
#
# POST /unfreeze-account
# operationId: unfreezeAccount
export def "unfreeze-account create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unfreeze-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# View your user groups
#
# GET /user-groups
# operationId: getUserGroups
export def "user-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user-groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of platform users
#
# GET /users
# operationId: getUsers
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --user-type: string@user-type-completer # default: all
  --search: string
  --email: string
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "user_type" $user_type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"page": $page, "per_page": $per_page, "user_type": $user_type, "search": $search, "email": $email} | compact), body: null}
}

# Create a new user
#
# POST /users
# operationId: createUser
# --client shape: {corporate?: record, nps?: float, subjects?: record}
# --language_pairs item shape: {source_language?: string, target_language?: string}
# --mailing shape: {city?: string, country?: string, phone?: string, state?: string, street?: string, zip?: string}
# --social_media shape: {facebook_url?: string, linkedIn_url?: string, twitter_url?: string}
# --user_groups item shape: {corporate_id?: int, id?: int, name?: string, permissions?: list<string>}
# --vendor shape: {can_work_manual_files?: bool, email_open_rate?: float, is_frozen?: bool, is_proofreader?: bool, language_pairs?: list, native_language?: string, pam_tqs?: float, paypal_email?: string, profile_survey?: record, require_1099?: bool, tags?: list<string>, tms_user_name?: string, vendor_type?: string}
@deprecated --flag can-work-manual-files
@deprecated --flag city
@deprecated --flag country
@deprecated --flag is-proofreader
@deprecated --flag language-pairs
@deprecated --flag native-language
@deprecated --flag nps
@deprecated --flag state
@deprecated --flag street
@deprecated --flag tms-user-name
@deprecated --flag zip-code
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Send a welcome email to the user (default: 1)
  --billing: any
  --birthday: string # format: date
  --can-work-manual-files: oneof<nothing, bool> # \@deprecated. use `vendor` key (DEPRECATED)
  --city: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --client: record # shape: {corporate?: record, nps?: float, subjects?: record}
  --corporate-id: int # format: int64
  --country: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --created-at: int # Unix epoch time (format: int64)
  --do-not-contact: oneof<nothing, bool>
  --email: string
  --first-name: string
  --has-pwd: oneof<nothing, bool>
  --id: int # format: int64
  --is-client: oneof<nothing, bool>
  --is-developer: oneof<nothing, bool>
  --is-proofreader: oneof<nothing, bool> # \@deprecated. use `vendor` key (DEPRECATED)
  --is-prospect: oneof<nothing, bool>
  --is-sales-person: oneof<nothing, bool>
  --is-vendor: oneof<nothing, bool>
  --language-pairs: list # \@deprecated. use `vendor` key (DEPRECATED) — item shape: {source_language?: string, target_language?: string}
  --last-name: string
  --last-seen-online-at: int # Unix epoch time (format: int64)
  --links: any
  --locale: string # User Locale
  --mailing: record # shape: {city?: string, country?: string, phone?: string, state?: string, street?: string, zip?: string}
  --name: string
  --native-language: string # \@deprecated. Native language of user (DEPRECATED)
  --nps: float # \@deprecated. use /stats endpoint for the current nps value. (DEPRECATED, format: float)
  --phone-number: string
  --profile-picture-path: string
  --social-media: record # shape: {facebook_url?: string, linkedIn_url?: string, twitter_url?: string}
  --state: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --status: string
  --street: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --timezone: string
  --tms-user-name: string # \@deprecated. use `vendor` key (DEPRECATED)
  --user-groups: list # item shape: {corporate_id?: int, id?: int, name?: string, permissions?: list<string>}
  --vendor: record # shape: {can_work_manual_files?: bool, email_open_rate?: float, is_frozen?: bool, is_proofreader?: bool, language_pairs?: list, native_language?: string, pam_tqs?: float, paypal_email?: string, profile_survey?: record, require_1099?: bool, tags?: list<string>, tms_user_name?: string, vendor_type?: string}
  --zip-code: string # \@deprecated. use mailing or billing key. new key name is "zip". (DEPRECATED)
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let req_body = {"billing": $billing, "birthday": $birthday, "can_work_manual_files": $can_work_manual_files, "city": $city, "client": $client, "corporate_id": $corporate_id, "country": $country, "created_at": $created_at, "do_not_contact": $do_not_contact, "email": $email, "first_name": $first_name, "has_pwd": $has_pwd, "id": $id, "is_client": $is_client, "is_developer": $is_developer, "is_proofreader": $is_proofreader, "is_prospect": $is_prospect, "is_sales_person": $is_sales_person, "is_vendor": $is_vendor, "language_pairs": $language_pairs, "last_name": $last_name, "last_seen_online_at": $last_seen_online_at, "links": $links, "locale": $locale, "mailing": $mailing, "name": $name, "native_language": $native_language, "nps": $nps, "phone_number": $phone_number, "profile_picture_path": $profile_picture_path, "social_media": $social_media, "state": $state, "status": $status, "street": $street, "timezone": $timezone, "tms_user_name": $tms_user_name, "user_groups": $user_groups, "vendor": $vendor, "zip_code": $zip_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"notify": $notify} | compact), body: $req_body}
}

# Get a list of vendors available for the criteria given
#
# POST /users/available-vendors
# operationId: getAvailableVendors
export def "users-available-vendors get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list<string> # Include detailed information. Possible values 'user'. Requesting user info enrichment takes much longer.
  --corporate-id: float # Corporate account ID to filter for vendor authorization
  --manual-work-permission: oneof<nothing, bool> # Filter vendors for manual work permission (default: 0)
  --source-language: string # Source language code
  --target-languages: list<string> # List of target language codes.
  --types: list<string> # List of vendor types
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/users/available-vendors" $qp)
  let req_body = {"corporateId": $corporate_id, "manualWorkPermission": $manual_work_permission, "sourceLanguage": $source_language, "targetLanguages": $target_languages, "types": $types} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"with[]": $with} | compact), body: $req_body}
}

# Filter vendors based on provided parameters
#
# POST /users/filter
# operationId: getFilteredVendors
export def "users-filter get-filtered-vendors" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number
  --per-page: int # The number of items per page
  --order-by: string # The field to order the results by
  --order: string # The order to sort the results by (ascending or descending)
  --clients: list<int>
  --communication-channel: list<string>
  --corporate-ids-for-auth: list<int>
  --corporates: list<int>
  --country: list<string>
  --created-at: string
  --current-services: list<string>
  --daily-proofreading-capacity: int
  --daily-translation-capacity: int
  --destination-languages: list<int>
  --dtp-software: list<string>
  --email-address: string
  --experience: list<string>
  --first-name: string
  --id: list<int>
  --is-certified-translator: oneof<nothing, bool>
  --is-sworn-translator: oneof<nothing, bool>
  --language-pairs: list
  --last-name: string
  --last-online: string
  --last-worked: string
  --memoq: int
  --memsource: int
  --min-tqs: float
  --omegat: int
  --project-count: int
  --proofreader-experience: int
  --provides-creative-writing-service: oneof<nothing, bool>
  --provides-postedit-service: oneof<nothing, bool>
  --quote-file-subjects: list<string>
  --reference: string
  --sdl-trados: int
  --search: string
  --skype-id: string
  --smartcat: int
  --smartling: int
  --source-languages: list<int>
  --specialization: list<string>
  --status: list<string>
  --subtitle-edit: int
  --subtitle-workshop: int
  --translator-association: string
  --transsuite-2000: int
  --user-working-timezone: list<string>
  --vendor-profile-lsp: string
  --vendor-tags: list<string>
  --vendor-type: list<string>
  --vendor-working-timezone: list<string>
  --word-count: int
  --wordbee: int
  --wordfast: int
  --work-type: string
  --work-with: string
  --working-as: list<string>
  --xbench: int
  --xtm: int
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/filter" $qp)
  let req_body = {"clients": $clients, "communication_channel": $communication_channel, "corporate_ids_for_auth": $corporate_ids_for_auth, "corporates": $corporates, "country": $country, "created_at": $created_at, "current_services": $current_services, "daily_proofreading_capacity": $daily_proofreading_capacity, "daily_translation_capacity": $daily_translation_capacity, "destination_languages": $destination_languages, "dtp_software": $dtp_software, "email_address": $email_address, "experience": $experience, "first_name": $first_name, "id": $id, "is_certified_translator": $is_certified_translator, "is_sworn_translator": $is_sworn_translator, "language_pairs": $language_pairs, "last_name": $last_name, "last_online": $last_online, "last_worked": $last_worked, "memoq": $memoq, "memsource": $memsource, "min_tqs": $min_tqs, "omegat": $omegat, "project_count": $project_count, "proofreader_experience": $proofreader_experience, "provides_creative_writing_service": $provides_creative_writing_service, "provides_postedit_service": $provides_postedit_service, "quote_file_subjects": $quote_file_subjects, "reference": $reference, "sdl_trados": $sdl_trados, "search": $search, "skype_id": $skype_id, "smartcat": $smartcat, "smartling": $smartling, "source_languages": $source_languages, "specialization": $specialization, "status": $status, "subtitle_edit": $subtitle_edit, "subtitle_workshop": $subtitle_workshop, "translator_association": $translator_association, "transsuite_2000": $transsuite_2000, "user_working_timezone": $user_working_timezone, "vendor_profile_lsp": $vendor_profile_lsp, "vendor_tags": $vendor_tags, "vendor_type": $vendor_type, "vendor_working_timezone": $vendor_working_timezone, "word_count": $word_count, "wordbee": $wordbee, "wordfast": $wordfast, "work_type": $work_type, "work_with": $work_with, "working_as": $working_as, "xbench": $xbench, "xtm": $xtm} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"page": $page, "per_page": $per_page, "order_by": $order_by, "order": $order} | compact), body: $req_body}
}

# Sends password reset email to the user's registered email address
#
# POST /users/send-password-reminder
# operationId: sendPasswordReminder
export def "users-send-password-reminder send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/send-password-reminder")
  let req_body = {"email": $email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns all vendor tags for vendors filter
#
# GET /users/tags
# operationId: getAllVendorTags
export def "users-tags get-list-vendor" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<color: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get user information, including client or vendor specific info.
#
# GET /{userId}
# operationId: getUser
export def "user get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /{userId}
#
# operationId: updateUser
# --notifications shape: {phone_number?: string, sms_enabled?: bool}
export def "user update" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list<int> # A list of user group IDs
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}"))
  let req_body = {"city": $city, "country": $country, "phone": $phone, "state": $state, "street": $street, "zip": $zip, "birthday": $birthday, "email": $email, "first_name": $first_name, "id": $id, "last_name": $last_name, "notifications": $notifications, "notify": $notify, "paypal_email": $paypal_email, "require_1099": $require_1099, "user_groups": $user_groups} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /{userId}/approve
#
# operationId: approveVendorApplication
export def "approve approve-vendor-application" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/approve"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete requester account
#
# DELETE /{userId}/delete-account
# operationId: deleteUserAccount
export def "delete-account delete-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/delete-account"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of your documents
#
# GET /{userId}/documents
# operationId: getUserDocuments
export def "documents get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recent: oneof<nothing, bool> # When true, this will return the most 4 recent active documents. (default: 0)
  --search: string
  --type-filter: string@type-filter-completer # default: ALL
  --language-code: string # searches in source language of documents, in source and target languages of document's quote
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --order-by: string@order-by-completer # default: updated_at
  --order-type: string@order-type-completer
]: nothing -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "recent" $recent "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "type_filter" $type_filter "scalar") (serialize-qp "language_code" $language_code "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_type" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"recent": $recent, "search": $search, "type_filter": $type_filter, "language_code": $language_code, "page": $page, "per_page": $per_page, "order_by": $order_by, "order_type": $order_type} | compact), body: null}
}

# POST /{userId}/downgrade-proofreader
#
# operationId: downgradeUserProofreader
export def "downgrade-proofreader create-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/downgrade-proofreader"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns your vendor earnings. Includes real-time earnings from ongoing projects, and fixed earnings from completed projects. Also includes total earnings and string edits.
#
# GET /{userId}/earnings
# operationId: getUserEarnings
export def "earnings get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completed: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, ongoing: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/earnings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Freeze requester account for project notifications
#
# POST /{userId}/freeze-account
# operationId: freezeUserAccount
export def "freeze-account create-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/freeze-account"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /{userId}/make-proofreader
#
# operationId: makeUserProofreader
export def "make-proofreader create-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/make-proofreader"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /{userId}/notifications/subscribe
#
# operationId: subscribeUserNotification
export def "notifications-subscribe subscribe-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/notifications/subscribe"))
  let req_body = {"device": $device, "endpoint": $endpoint, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# POST /{userId}/notifications/unsubscribe
#
# operationId: unsubscribeUserNotification
export def "notifications-unsubscribe unsubscribe-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/notifications/unsubscribe"))
  let req_body = {"device": $device, "endpoint": $endpoint, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# View user's payment and billing info
#
# GET /{userId}/payment
# operationId: getUserPaymentInfo
export def "payment get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/payment"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update user payment info
#
# POST /{userId}/payment
# operationId: updateUserPaymentInfo
# --card shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
# --cards item shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
# --corporate shape: {allow_api_invoicing?: bool, allow_payment_code?: bool, auto_charge?: bool, billing?: any, card?: record, contact_email_address?: string, payment_code?: string}
# --shared_card shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
export def "payment update-user-get" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing: any
  --card: record # shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
  --cards: list # item shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
  --corporate: record # shape: {allow_api_invoicing?: bool, allow_payment_code?: bool, auto_charge?: bool, billing?: any, card?: record, contact_email_address?: string, payment_code?: string}
  --shared-card: record # shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/payment"))
  let req_body = {"billing": $billing, "card": $card, "cards": $cards, "corporate": $corporate, "shared_card": $shared_card} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Returns a list of permissions that this user is authorized for.
#
# GET /{userId}/permissions
# operationId: getUserPermissions
export def "permissions get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/permissions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /{userId}/profile-picture
#
# operationId: uploadUserProfilePicture
export def "profile-picture upload-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  profile_picture: string # Profile picture file contents. Accepted extensions are png, jpg. (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/profile-picture"))
  let req_body = {"profile_picture": $profile_picture} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a list of user/vendor projects
#
# GET /{userId}/projects/vendor
# operationId: getVendorProjectsByUserId
export def "projects-vendor get-by-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --joined: oneof<nothing, bool> # Return only projects that this user has already joined
  --completed: oneof<nothing, bool> # Return only projects that have been completed. When `true`, this makes `joined` true as well.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "joined" $joined "scalar") (serialize-qp "completed" $completed "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/projects/vendor") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"joined": $joined, "completed": $completed, "page": $page, "per_page": $per_page} | compact), body: null}
}

# POST /{userId}/reject
#
# operationId: rejectVendorApplication
export def "reject reject-vendor-application" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/reject"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Sends email confirmation email for a user
#
# POST /{userId}/resend-email-confirmation
# operationId: sendUserEmailConfirmation
export def "resend-email-confirmation send-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/resend-email-confirmation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a user's vendor responsivity stats
#
# GET /{userId}/responsivity
# operationId: getUserResponsivity
export def "responsivity get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # Period for calcualtion. (default: monthly)
]: nothing -> record<links: record<self: record<href: string>>, responsivity: table<invited: int, month: string, notEntered: int, onlyEntered: int, score: float, week: string, worked: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/responsivity") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"period": $period} | compact), body: null}
}

# Returns a user's client and vendor statistics. This used to be called "summary" (\@deprecated).
#
# GET /{userId}/stats
# operationId: getUserStats
export def "stats get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client: record<document_count: int, nps: float, started_project_count: int, total_discounted: record<amount: float, currency: string>, total_project_count: int, total_spending: float, translator_count: int>, vendor: record<earnings: record<total: float>, projects: record<invited: int, total: int, worked: int>, words: record<approved: int, translated: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/stats"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns the language pairs that the user has ordered most.
#
# GET /{userId}/stats/popular-pairs
# operationId: getUserPopularPairs
export def "stats-popular-pairs get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pairs: table<source_language: string, target_language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/stats/popular-pairs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a user's project statistics.
#
# GET /{userId}/stats/projects
# operationId: getUserProjectStats
export def "stats-projects get-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stats: table<languages: list, month: string, number_of_projects: int, total_spending: float, week: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/stats/projects"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /{userId}/suspend
#
# operationId: suspendUser
export def "suspend create-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Suspension reason for vendor
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/suspend"))
  let req_body = {"reason": $reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Unfreeze requester account for project notifications
#
# POST /{userId}/unfreeze-account
# operationId: unfreezeUserAccount
export def "unfreeze-account create-user" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/unfreeze-account"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Returns a list of user groups that this user belongs to.
#
# GET /{userId}/user-groups
# operationId: getThisUserGroups
export def "user-groups get-this" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/user-groups"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# POST /{userId}/user-groups
#
# operationId: updateUserGroup
export def "user-groups update" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website.
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --variables: string # Continuous project variable definitions
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($user_id | is-empty) { error make --unspanned { msg: "path parameter 'userId' must be non-empty" } }
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/{user_id}/user-groups"))
  let req_body = {"allow_hash_in_url": $allow_hash_in_url, "allow_query_in_url": $allow_query_in_url, "auto_detect_source_language": $auto_detect_source_language, "created_at": $created_at, "elements": $elements, "follow_user": $follow_user, "force_cache_refresh_interval": $force_cache_refresh_interval, "id": $id, "language_mappings": $language_mappings, "live": $live, "modify_links": $modify_links, "name": $name, "optimize_per_page": $optimize_per_page, "pages": $pages, "path_regex": $path_regex, "position": $position, "query_name": $query_name, "reboot_on_url_change": $reboot_on_url_change, "restricted_domains": $restricted_domains, "sections": $sections, "test_mode": $test_mode, "theme": $theme, "token": $body_token, "url_change_mode": $url_change_mode, "url_mode": $url_mode, "use_cache": $use_cache, "use_dummy_translations": $use_dummy_translations, "variables": $variables} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
